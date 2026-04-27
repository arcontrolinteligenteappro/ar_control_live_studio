#include <vector>
#include <list>
#include <mutex>
#include <chrono>
#include <android/log.h>

extern "C" {
#include "libavcodec/avcodec.h"
#include "libavformat/avformat.h"
#include "libavutil/imgutils.h"
#include "libswscale/swscale.h"
#include "libavutil/opt.h"
}

#include "../controls/replay_engine.h"

#define LOG_TAG "ReplayEngineNative"
#define LOGI(...) __android_log_debugPrint(ANDROID_LOG_INFO, LOG_TAG, __VA_ARGS__)
#define LOGE(...) __android_log_debugPrint(ANDROID_LOG_ERROR, LOG_TAG, __VA_ARGS__)

struct EncodedPacket {
    AVPacket *pkt;
    int64_t dts; // De-muxing timestamp
};

struct ReplayBuffer {
    std::list<EncodedPacket> packet_buffer;
    std::mutex mtx;
    int capacity_seconds;
    int fps;
    int bitrate;
    int64_t next_pts = 0;
    int64_t total_duration_pts = 0;

    // FFmpeg context
    AVCodecContext *encoder_ctx = nullptr;
    AVFrame *frame = nullptr;
    SwsContext *sws_ctx = nullptr;
    int width = 0;
    int height = 0;
};


int init_encoder(ReplayBuffer *buffer, int width, int height) {
    LOGI("Initializing encoder for %dx%d", width, height);
    buffer->width = width;
    buffer->height = height;

    const AVCodec *codec = avcodec_find_encoder_by_name("libx264");
    if (!codec) {
        LOGE("Codec libx264 not found");
        return -1;
    }

    buffer->encoder_ctx = avcodec_alloc_context3(codec);
    if (!buffer->encoder_ctx) {
        LOGE("Could not allocate video codec context");
        return -1;
    }

    buffer->encoder_ctx->bit_rate = buffer->bitrate;
    buffer->encoder_ctx->width = width;
    buffer->encoder_ctx->height = height;
    buffer->encoder_ctx->time_base = {1, buffer->fps};
    buffer->encoder_ctx->framerate = {buffer->fps, 1};
    buffer->encoder_ctx->gop_size = buffer->fps; // Keyframe every second
    buffer->encoder_ctx->max_b_frames = 1;
    buffer->encoder_ctx->pix_fmt = AV_PIX_FMT_YUV420P;

    av_opt_set(buffer->encoder_ctx->priv_data, "preset", "ultrafast", 0);
    av_opt_set(buffer->encoder_ctx->priv_data, "tune", "zerolatency", 0);

    if (avcodec_open2(buffer->encoder_ctx, codec, nullptr) < 0) {
        LOGE("Could not open codec");
        return -1;
    }

    buffer->frame = av_frame_alloc();
    if (!buffer->frame) {
        LOGE("Could not allocate video frame");
        return -1;
    }
    buffer->frame->format = buffer->encoder_ctx->pix_fmt;
    buffer->frame->width = width;
    buffer->frame->height = height;

    if (av_frame_get_buffer(buffer->frame, 0) < 0) {
        LOGE("Could not allocate the video frame data");
        return -1;
    }

    LOGI("Encoder initialized successfully");
    return 0;
}

void encode_and_store_packet(ReplayBuffer *buffer, AVFrame *frame) {
    if (avcodec_send_frame(buffer->encoder_ctx, frame) < 0) {
        LOGE("Error sending a frame for encoding");
        return;
    }

    while (true) {
        AVPacket *pkt = av_packet_alloc();
        int ret = avcodec_receive_packet(buffer->encoder_ctx, pkt);
        if (ret == AVERROR(EAGAIN) || ret == AVERROR_EOF) {
            av_packet_free(&pkt);
            break;
        } else if (ret < 0) {
            LOGE("Error during encoding");
            av_packet_free(&pkt);
            break;
        }

        std::lock_guard<std::mutex> lock(buffer->mtx);
        buffer->packet_buffer.push_back({pkt, pkt->dts});
        buffer->total_duration_pts += pkt->duration;

        // Ring buffer logic: remove old packets if buffer is full
        int64_t capacity_pts = buffer->capacity_seconds * buffer->fps;
        while (buffer->total_duration_pts > capacity_pts && !buffer->packet_buffer.empty()) {
            EncodedPacket &oldest = buffer->packet_buffer.front();
            buffer->total_duration_pts -= oldest.pkt->duration;
            av_packet_free(&oldest.pkt);
            buffer->packet_buffer.pop_front();
        }
    }
}


ReplayBuffer *replay_buffer_create(int capacity_seconds, int frames_per_second, int bitrate) {
    ReplayBuffer *buffer = new ReplayBuffer();
    buffer->capacity_seconds = capacity_seconds;
    buffer->fps = frames_per_second;
    buffer->bitrate = bitrate;
    LOGI("ReplayBuffer created in C++. Capacity: %d s, FPS: %d, Bitrate: %d", capacity_seconds, frames_per_second, bitrate);
    return buffer;
}

void replay_buffer_add_frame(ReplayBuffer *buffer,
                             const uint8_t *y_plane, int y_stride,
                             const uint8_t *u_plane, int u_stride,
                             const uint8_t *v_plane, int v_stride,
                             int width, int height) {
    if (!buffer) return;

    // Initialize encoder on the first frame
    if (!buffer->encoder_ctx || buffer->width != width || buffer->height != height) {
        if (buffer->encoder_ctx) {
            // Teardown old encoder if resolution changed
            avcodec_free_context(&buffer->encoder_ctx);
            av_frame_free(&buffer->frame);
            sws_freeContext(buffer->sws_ctx);
        }
        if (init_encoder(buffer, width, height) != 0) {
            LOGE("Failed to initialize encoder on first frame.");
            return;
        }
    }

    // Ensure frame is writable
    if (av_frame_make_writable(buffer->frame) < 0) {
        LOGE("Frame not writable");
        return;
    }

    // Copy Y, U, V planes from CameraImage to AVFrame
    // This is a simple copy assuming the format is I420 (YUV420p)
    const uint8_t *in_data[3] = {y_plane, u_plane, v_plane};
    int in_linesize[3] = {y_stride, u_stride, v_stride};

    // No need for sws_scale if the input format is already YUV420p
    av_image_copy(buffer->frame->data, buffer->frame->linesize,
                  in_data, in_linesize,
                  AV_PIX_FMT_YUV420P, width, height);

    buffer->frame->pts = buffer->next_pts++;
    encode_and_store_packet(buffer, buffer->frame);
}

int32_t replay_buffer_save_to_file(ReplayBuffer *buffer, const char *output_path) {
    if (!buffer || !buffer->encoder_ctx) {
        LOGE("Save failed: buffer or encoder not initialized.");
        return -1;
    }

    std::lock_guard<std::mutex> lock(buffer->mtx);
    LOGI("Starting to save replay to %s", output_path);

    AVFormatContext *fmt_ctx = nullptr;
    avformat_alloc_output_context2(&fmt_ctx, nullptr, "mp4", output_path);
    if (!fmt_ctx) {
        LOGE("Could not create output context");
        return -1;
    }

    AVStream *stream = avformat_new_stream(fmt_ctx, nullptr);
    if (!stream) {
        LOGE("Failed allocating output stream");
        avformat_free_context(fmt_ctx);
        return -1;
    }

    avcodec_parameters_from_context(stream->codecpar, buffer->encoder_ctx);
    stream->time_base = buffer->encoder_ctx->time_base;

    if (!(fmt_ctx->oformat->flags & AVFMT_NOFILE)) {
        if (avio_open(&fmt_ctx->pb, output_path, AVIO_FLAG_WRITE) < 0) {
            LOGE("Could not open output file '%s'", output_path);
            avformat_free_context(fmt_ctx);
            return -1;
        }
    }

    if (avformat_write_header(fmt_ctx, nullptr) < 0) {
        LOGE("Error occurred when opening output file");
        avio_closep(&fmt_ctx->pb);
        avformat_free_context(fmt_ctx);
        return -1;
    }

    int64_t last_dts = 0;
    int64_t pts_offset = 0;

    for (const auto &encoded_packet : buffer->packet_buffer) {
        AVPacket *pkt_copy = av_packet_clone(encoded_packet.pkt);

        if (pts_offset == 0) {
            pts_offset = -pkt_copy->pts;
        }

        // Rescale timestamps
        pkt_copy->pts += pts_offset;
        pkt_copy->dts += pts_offset;

        pkt_copy->stream_index = stream->index;
        av_packet_rescale_ts(pkt_copy, buffer->encoder_ctx->time_base, stream->time_base);

        if (av_interleaved_write_frame(fmt_ctx, pkt_copy) < 0) {
            LOGE("Error while writing video frame");
        }
        av_packet_free(&pkt_copy);
    }

    av_write_trailer(fmt_ctx);

    if (!(fmt_ctx->oformat->flags & AVFMT_NOFILE)) {
        avio_closep(&fmt_ctx->pb);
    }

    avformat_free_context(fmt_ctx);
    LOGI("Replay saved successfully to %s", output_path);
    return 0;
}

void replay_buffer_destroy(ReplayBuffer *buffer) {
    if (!buffer) return;

    std::lock_guard<std::mutex> lock(buffer->mtx);
    for (auto &encoded_packet : buffer->packet_buffer) {
        av_packet_free(&encoded_packet.pkt);
    }
    buffer->packet_buffer.clear();

    if (buffer->encoder_ctx) {
        // Flush encoder
        encode_and_store_packet(buffer, nullptr);
        avcodec_free_context(&buffer->encoder_ctx);
    }
    if (buffer->frame) {
        av_frame_free(&buffer->frame);
    }
    if (buffer->sws_ctx) {
        sws_freeContext(buffer->sws_ctx);
    }

    delete buffer;
    LOGI("ReplayBuffer destroyed");
}
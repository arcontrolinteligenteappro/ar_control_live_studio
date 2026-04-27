#ifndef AR_CONTROL_LIVE_STUDIO_AUDIO_PLUGIN_H
#define AR_CONTROL_LIVE_STUDIO_AUDIO_PLUGIN_H

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar.h> // Generic registrar, use platform-specific for actual plugin
#include <flutter/standard_method_codec.h>

#include <memory>
#include <mutex>
#include <map>
#include <string>
#include <atomic>
#include <thread>

namespace ar_control_live_studio {

// Conceptual Audio Source
struct AudioSource {
    std::string id;
    std::string media_stream_track_id; // For WebRTC sources, to hook into its audio
    std::atomic<float> target_volume{0.0f}; // The volume requested by Dart
    std::atomic<float> current_volume{0.0f}; // The actual volume currently applied (for cross-fade)
    // Add native audio resource handles here (e.g., Oboe AudioStream, CoreAudio unit, WASAPI client)
    // For cross-fade, the audio processing loop would smoothly transition current_volume to target_volume.
};

class ArControlLiveStudioAudioPlugin : public flutter::Plugin {
public:
    static void RegisterWithRegistrar(flutter::PluginRegistrar* registrar);

    ArControlLiveStudioAudioPlugin();
    virtual ~ArControlLiveStudioAudioPlugin();

private:
    void HandleMethodCall(
        const flutter::MethodCall<flutter::EncodableValue>& method_call,
        std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);

    // Native audio mixer logic
    void InitNativeMixer();
    void RegisterNativeSource(const std::string& source_id, const std::string& media_stream_track_id);
    void SetNativeSourceVolume(const std::string& source_id, float volume);
    void CrossfadeNative(const std::string& from_id, const std::string& to_id, float to_target_volume, int duration_ms);
    void DisposeNativeSource(const std::string& source_id);

    std::map<std::string, std::unique_ptr<AudioSource>> audio_sources_;
    std::mutex audio_sources_mutex_; // Protects audio_sources_ map
    std::atomic<bool> mixer_initialized_{false};

    // Conceptual native audio engine thread
    std::thread audio_processing_thread_;
    std::atomic<bool> stop_audio_processing_{false};
    void AudioProcessingLoop();
};

} // namespace ar_control_live_studio

#endif // AR_CONTROL_LIVE_STUDIO_AUDIO_PLUGIN_H
#include "ar_control_live_studio_audio_plugin.h"
#include <iostream>
#include <chrono>
#include <thread>
#include <cmath> // For std::pow, std::log10

// Platform-specific audio includes (conceptual)
// #ifdef __ANDROID__
// #include <oboe/Oboe.h> // Example for Android
// #elif __APPLE__
// #include <AudioToolbox/AudioToolbox.h> // Example for iOS/macOS
// #elif _WIN32
// #include <Audioclient.h> // Example for Windows
// #endif

namespace ar_control_live_studio {

// --- Plugin Implementation ---

void ArControlLiveStudioAudioPlugin::RegisterWithRegistrar(flutter::PluginRegistrar* registrar) {
    auto channel =
        std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
            registrar->messenger(), "ar_control_live_studio/audio",
            &flutter::StandardMethodCodec::GetInstance());

    auto plugin = std::make_unique<ArControlLiveStudioAudioPlugin>();

    channel->SetMethodCallHandler(
        [plugin_pointer = plugin.get()](const auto& call, auto result) {
            plugin_pointer->HandleMethodCall(call, std::move(result));
        });

    registrar->AddPlugin(std::move(plugin));
}

ArControlLiveStudioAudioPlugin::ArControlLiveStudioAudioPlugin() {
    // Start the conceptual audio processing thread
    stop_audio_processing_ = false;
    audio_processing_thread_ = std::thread(&ArControlLiveStudioAudioPlugin::AudioProcessingLoop, this);
}

ArControlLiveStudioAudioPlugin::~ArControlLiveStudioAudioPlugin() {
    stop_audio_processing_ = true;
    if (audio_processing_thread_.joinable()) {
        audio_processing_thread_.join();
    }
    // Dispose all native audio resources
    std::lock_guard<std::mutex> lock(audio_sources_mutex_);
    audio_sources_.clear();
    std::cout << "Native Audio Plugin: Mixer disposed." << std::endl;
}

void ArControlLiveStudioAudioPlugin::HandleMethodCall(
    const flutter::MethodCall<flutter::EncodableValue>& method_call,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
    
    if (method_call.method_name().compare("initMixer") == 0) {
        InitNativeMixer();
        result->Success();
    } else if (method_call.method_name().compare("registerSource") == 0) {
        const auto* arguments = std::get_if<flutter::EncodableMap>(method_call.arguments());
        if (arguments) {
            std::string source_id = std::get<std::string>(arguments->at(flutter::EncodableValue("sourceId")));
            std::string media_stream_track_id = "";
            if (arguments->count(flutter::EncodableValue("trackId"))) {
                media_stream_track_id = std::get<std::string>(arguments->at(flutter::EncodableValue("trackId")));
            }
            RegisterNativeSource(source_id, media_stream_track_id);
            result->Success();
        } else {
            result->Error("Invalid arguments", "Expected map with sourceId and optional trackId.");
        }
    } else if (method_call.method_name().compare("setSourceVolume") == 0) {
        const auto* arguments = std::get_if<flutter::EncodableMap>(method_call.arguments());
        if (arguments) {
            std::string source_id = std::get<std::string>(arguments->at(flutter::EncodableValue("sourceId")));
            double volume = std::get<double>(arguments->at(flutter::EncodableValue("volume")));
            SetNativeSourceVolume(source_id, static_cast<float>(volume));
            result->Success();
        } else {
            result->Error("Invalid arguments", "Expected map with sourceId and volume.");
        }
    } else if (method_call.method_name().compare("crossfade") == 0) {
        const auto* arguments = std::get_if<flutter::EncodableMap>(method_call.arguments());
        if (arguments) {
            std::string to_id = std::get<std::string>(arguments->at(flutter::EncodableValue("toSourceId")));
            double to_target_volume = std::get<double>(arguments->at(flutter::EncodableValue("toSourceTargetVolume")));
            int duration_ms = std::get<int32_t>(arguments->at(flutter::EncodableValue("durationMs")));
            std::string from_id = "";
            if (arguments->count(flutter::EncodableValue("fromSourceId"))) {
                auto from_val = arguments->at(flutter::EncodableValue("fromSourceId"));
                if (!from_val.IsNull()) {
                    from_id = std::get<std::string>(from_val);
                }
            }
            CrossfadeNative(from_id, to_id, static_cast<float>(to_target_volume), duration_ms);
            result->Success();
        } else {
            result->Error("Invalid arguments", "Expected map for crossfade.");
        }
    } else if (method_call.method_name().compare("disposeSource") == 0) {
        const auto* arguments = std::get_if<flutter::EncodableMap>(method_call.arguments());
        if (arguments) {
            std::string source_id = std::get<std::string>(arguments->at(flutter::EncodableValue("sourceId")));
            DisposeNativeSource(source_id);
            result->Success();
        } else {
            result->Error("Invalid arguments", "Expected map with sourceId.");
        }
    } else {
        result->NotImplemented();
    }
}

void ArControlLiveStudioAudioPlugin::InitNativeMixer() {
    if (mixer_initialized_) return;

    // --- Native Audio Engine Initialization ---
    // This is where you would initialize your platform-specific audio engine.
    // Examples:
    // - Android: Oboe (create AudioStreamBuilder, open stream)
    // - iOS/macOS: AudioUnit, AVAudioEngine
    // - Windows: WASAPI, XAudio2
    // - Linux: ALSA, PulseAudio
    // This setup would typically involve setting sample rate, buffer size, etc.
    std::cout << "Native Audio Plugin: Initializing native audio mixer (conceptual)..." << std::endl;
    mixer_initialized_ = true;
}

void ArControlLiveStudioAudioPlugin::RegisterNativeSource(const std::string& source_id, const std::string& media_stream_track_id) {
    std::lock_guard<std::mutex> lock(audio_sources_mutex_);
    if (audio_sources_.count(source_id)) {
        std::cout << "Native Audio Plugin: Source " << source_id << " already registered." << std::endl;
        return;
    }

    auto source = std::make_unique<AudioSource>();
    source->id = source_id;
    source->media_stream_track_id = media_stream_track_id;
    source->target_volume = 0.0f; // Start muted
    source->current_volume = 0.0f;

    // --- Native Audio Source Creation ---
    // Here, you would create a native audio source/track within your audio engine.
    // - For WebRTC sources, you'd connect to the `media_stream_track_id` to get its audio samples.
    // - For local microphone, you'd open a mic input stream.
    // - For file playback, you'd open an audio file decoder.
    std::cout << "Native Audio Plugin: Registering source " << source_id << " (track: " << media_stream_track_id << ") (conceptual)..." << std::endl;
    audio_sources_[source_id] = std::move(source);
}

void ArControlLiveStudioAudioPlugin::SetNativeSourceVolume(const std::string& source_id, float volume) {
    std::lock_guard<std::mutex> lock(audio_sources_mutex_);
    auto it = audio_sources_.find(source_id);
    if (it != audio_sources_.end()) {
        it->second->target_volume = volume; // Update target volume
        std::cout << "Native Audio Plugin: Setting target volume for " << source_id << " to " << volume << std::endl;
    } else {
        std::cerr << "Native Audio Plugin: Source " << source_id << " not found for volume control." << std::endl;
    }
}

void ArControlLiveStudioAudioPlugin::CrossfadeNative(const std::string& from_id, const std::string& to_id, float to_target_volume, int duration_ms) {
    std::lock_guard<std::mutex> lock(audio_sources_mutex_);
    
    // Set the target volume for the source that is fading out to 0.
    if (!from_id.empty()) {
        auto it_from = audio_sources_.find(from_id);
        if (it_from != audio_sources_.end()) {
            it_from->second->target_volume = 0.0f;
        }
    }

    // Set the target volume for the source that is fading in.
    auto it_to = audio_sources_.find(to_id);
    if (it_to != audio_sources_.end()) {
        it_to->second->target_volume = to_target_volume;
    }
}

void ArControlLiveStudioAudioPlugin::DisposeNativeSource(const std::string& source_id) {
    std::lock_guard<std::mutex> lock(audio_sources_mutex_);
    auto it = audio_sources_.find(source_id);
    if (it != audio_sources_.end()) {
        // --- Native Audio Source Disposal ---
        // Release any native audio resources associated with this source.
        std::cout << "Native Audio Plugin: Disposing source " << source_id << " (conceptual)..." << std::endl;
        audio_sources_.erase(it);
    }
}

void ArControlLiveStudioAudioPlugin::AudioProcessingLoop() {
    // This thread simulates the native audio engine's processing loop.
    // In a real application, this would be driven by audio callbacks
    // from the OS (e.g., Oboe's AudioStreamDataCallback, CoreAudio render callback).
    const int processing_interval_ms = 10;
    // The rate of change per second. A value of 3.33 means it takes ~300ms to go from 0 to 1.
    const float crossfade_rate_per_second = 1.0f / 0.3f; 
    const float crossfade_step = crossfade_rate_per_second * (processing_interval_ms / 1000.0f);

    while (!stop_audio_processing_) {
        if (mixer_initialized_) {
            std::lock_guard<std::mutex> lock(audio_sources_mutex_);
            for (auto const& [id, source] : audio_sources_) {
                // --- Real Cross-fade Logic ---
                // Smoothly transition current_volume towards target_volume
                if (std::abs(source->target_volume.load() - source->current_volume.load()) > 0.001f) {
                    if (source->target_volume.load() > source->current_volume.load()) { // Fading in
                        source->current_volume = std::min(source->target_volume.load(), source->current_volume.load() + crossfade_step);
                    } else { // Fading out
                        source->current_volume = std::max(source->target_volume.load(), source->current_volume.load() - crossfade_step);
                    }
                    // Apply source->current_volume to the actual native audio samples here.
                    // This would involve getting audio samples from the source, multiplying by current_volume,
                    // and mixing them into the main output buffer.
                    // std::cout << "Source " << id << " fading to " << source->current_volume.load() << std::endl;
                }
            }
            // Mix all sources and send to output device (conceptual)
        }
        std::this_thread::sleep_for(std::chrono::milliseconds(processing_interval_ms)); // Simulate processing interval
    }
    std::cout << "Native Audio Plugin: Audio processing thread stopped." << std::endl;
}

} // namespace ar_control_live_studio
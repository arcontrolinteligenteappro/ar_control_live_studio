#ifndef AR_CONTROL_LIVE_STUDIO_TEXTURE_PLUGIN_H
#define AR_CONTROL_LIVE_STUDIO_TEXTURE_PLUGIN_H

#include <flutter/plugin_registrar.h> // Generic registrar, use platform-specific for actual plugin
#include <flutter/texture_registrar.h>
#include <flutter/method_channel.h>
#include <flutter/standard_method_codec.h>

#include <memory>
#include <mutex>
#include <map>
#include <vector>

// Forward declaration for our custom texture
class ReplayFlutterTexture;

namespace ar_control_live_studio {

class ArControlLiveStudioTexturePlugin : public flutter::Plugin {
public:
    static void RegisterWithRegistrar(flutter::PluginRegistrar* registrar);

    ArControlLiveStudioTexturePlugin(flutter::TextureRegistrar* texture_registrar);
    virtual ~ArControlLiveStudioTexturePlugin();

private:
    void HandleMethodCall(
        const flutter::MethodCall<flutter::EncodableValue>& method_call,
        std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);

    flutter::TextureRegistrar* texture_registrar_;
    std::map<int64_t, std::unique_ptr<ReplayFlutterTexture>> textures_;
    std::mutex textures_mutex_; // Protects access to textures_ map
};

// Global function pointers to be set by the plugin and called by ReplayEngine C++ code
// These provide a bridge for the ReplayEngine to update Flutter textures.
extern "C" {
    // This function would be implemented by the plugin to update the pixel data of a Flutter texture.
    // It would typically copy `pixels` into the `ReplayFlutterTexture`'s internal buffer.
    void native_texture_plugin_update_texture_pixels(int64_t texture_id, const uint8_t* pixels, int width, int height);
    
    // This function would be implemented by the plugin to notify Flutter that a new frame is available.
    // It would call `texture_registrar_->MarkTextureFrameAvailable(texture_id)`.
    void native_texture_plugin_mark_texture_frame_available(int64_t texture_id);
}

} // namespace ar_control_live_studio

#endif // AR_CONTROL_LIVE_STUDIO_TEXTURE_PLUGIN_H
#include "ar_control_live_studio_texture_plugin.h"
#include <iostream>
#include <cstring> // For std::memcpy
#include <android/hardware_buffer_jni.h> // Para AHardwareBuffer

// --- Implementación Específica para Android ---

namespace ar_control_live_studio {

// Global pointer to the plugin instance to allow C-style callbacks to access it.
// This is a common pattern for bridging C++ FFI with Flutter plugins.
static ArControlLiveStudioTexturePlugin* g_texture_plugin_instance = nullptr;

// --- Implementación de Textura Personalizada para Android ---
// Esta clase gestiona un AHardwareBuffer, que es la forma más eficiente
// de compartir datos de imagen entre la CPU (FFmpeg) y la GPU (Flutter/Skia) en Android.
class ReplayFlutterTexture : public flutter::Texture {
public:
    ReplayFlutterTexture(flutter::TextureRegistrar* texture_registrar)
        : flutter::Texture(texture_registrar) {
        // No se inicializa el AHardwareBuffer aquí, se crea bajo demanda
        // cuando se recibe el primer frame, para saber las dimensiones correctas.
        hardware_buffer_ = nullptr;
        width_ = 0;
        height_ = 0;
    }

    ~ReplayFlutterTexture() {
        // Libera el AHardwareBuffer si existe.
        if (hardware_buffer_) {
            AHardwareBuffer_release(hardware_buffer_);
            hardware_buffer_ = nullptr;
        }
    }

    // Este método es llamado por Flutter para obtener la textura.
    // Devolvemos una HardwareBufferTexture, que es la más eficiente en Android.
    flutter::TextureVariant GetTextureVariant() const override {
        if (!hardware_buffer_) {
            // Devuelve una textura vacía si el buffer aún no está listo.
            return flutter::PixelBufferTexture(0, 0, nullptr, flutter::PixelFormat::kRGBA8888);
        }
        return flutter::HardwareBufferTexture(hardware_buffer_);
    }

    // Actualiza los píxeles del AHardwareBuffer desde el ReplayEngine.
    void UpdatePixels(const uint8_t* pixels, int width, int height) {
        std::lock_guard<std::mutex> lock(buffer_mutex_);

        // Si las dimensiones cambian o el buffer no existe, se crea uno nuevo.
        if (!hardware_buffer_ || width_ != width || height_ != height) {
            if (hardware_buffer_) {
                AHardwareBuffer_release(hardware_buffer_);
            }
            width_ = width;
            height_ = height;

            AHardwareBuffer_Desc desc = {};
            desc.width = width;
            desc.height = height;
            desc.layers = 1;
            desc.format = AHARDWAREBUFFER_FORMAT_R8G8B8A8_UNORM;
            desc.usage = AHARDWAREBUFFER_USAGE_CPU_WRITE_RARELY | AHARDWAREBUFFER_USAGE_GPU_SAMPLED_IMAGE;

            if (AHardwareBuffer_allocate(&desc, &hardware_buffer_) != 0) {
                std::cerr << "Error: Falló la asignación de AHardwareBuffer." << std::endl;
                hardware_buffer_ = nullptr;
                return;
            }
        }

        // Bloquea el buffer para escribir en él desde la CPU.
        uint8_t* buffer_data = nullptr;
        if (AHardwareBuffer_lock(hardware_buffer_, AHARDWAREBUFFER_USAGE_CPU_WRITE_RARELY, -1, nullptr,
                                 reinterpret_cast<void**>(&buffer_data)) == 0) {
            // Copia los píxeles decodificados por FFmpeg al buffer de hardware.
            std::memcpy(buffer_data, pixels, width * height * 4); // Asumiendo RGBA (4 bytes por píxel)
            AHardwareBuffer_unlock(hardware_buffer_, nullptr);
        } else {
            std::cerr << "Error: Falló el bloqueo de AHardwareBuffer." << std::endl;
        }
    }

private:
    AHardwareBuffer* hardware_buffer_;
    int width_;
    int height_;
    mutable std::mutex buffer_mutex_;
};

// --- Plugin Implementation ---

void ArControlLiveStudioTexturePlugin::RegisterWithRegistrar(flutter::PluginRegistrar* registrar) {
    auto channel =
        std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
            registrar->messenger(), "ar_control_live_studio/texture",
            &flutter::StandardMethodCodec::GetInstance());

    auto plugin = std::make_unique<ArControlLiveStudioTexturePlugin>(registrar->texture_registrar());

    // Set the global plugin instance for C-style callbacks
    g_texture_plugin_instance = plugin.get();

    channel->SetMethodCallHandler(
        [plugin_pointer = plugin.get()](const auto& call, auto result) {
            plugin_pointer->HandleMethodCall(call, std::move(result));
        });

    registrar->AddPlugin(std::move(plugin));
}

ArControlLiveStudioTexturePlugin::ArControlLiveStudioTexturePlugin(flutter::TextureRegistrar* texture_registrar)
    : texture_registrar_(texture_registrar) {
    // Assign the global function pointers to the actual plugin methods
    native_texture_plugin_update_texture_pixels = [](int64_t texture_id, const uint8_t* pixels, int width, int height) {
        if (g_texture_plugin_instance) {
            std::lock_guard<std::mutex> lock(g_texture_plugin_instance->textures_mutex_);
            auto it = g_texture_plugin_instance->textures_.find(texture_id);
            if (it != g_texture_plugin_instance->textures_.end()) {
                it->second->UpdatePixels(pixels, width, height);
            }
        }
    };
    native_texture_plugin_mark_texture_frame_available = [](int64_t texture_id) {
        if (g_texture_plugin_instance && g_texture_plugin_instance->texture_registrar_) {
            g_texture_plugin_instance->texture_registrar_->MarkTextureFrameAvailable(texture_id);
        }
    };
}

ArControlLiveStudioTexturePlugin::~ArControlLiveStudioTexturePlugin() {
    // Unregister all textures
    std::lock_guard<std::mutex> lock(textures_mutex_);
    for (auto const& [id, texture] : textures_) {
        texture_registrar_->UnregisterTexture(id);
    }
    textures_.clear();
    g_texture_plugin_instance = nullptr; // Clear global instance
}

void ArControlLiveStudioTexturePlugin::HandleMethodCall(
    const flutter::MethodCall<flutter::EncodableValue>& method_call,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
    
    if (method_call.method_name().compare("createTexture") == 0) {
        auto texture = std::make_unique<ReplayFlutterTexture>(texture_registrar_);
        int64_t texture_id = texture_registrar_->RegisterTexture(texture.get());
        std::lock_guard<std::mutex> lock(textures_mutex_);
        textures_[texture_id] = std::move(texture);
        result->Success(flutter::EncodableValue(texture_id));
    } else if (method_call.method_name().compare("disposeTexture") == 0) {
        const auto* arguments = std::get_if<flutter::EncodableMap>(method_call.arguments());
        if (arguments) {
            int64_t texture_id = std::get<int64_t>(arguments->at(flutter::EncodableValue("textureId")));
            std::lock_guard<std::mutex> lock(textures_mutex_);
            auto it = textures_.find(texture_id);
            if (it != textures_.end()) {
                texture_registrar_->UnregisterTexture(texture_id);
                textures_.erase(it);
                result->Success();
            } else {
                result->Error("Texture not found", "Texture with ID " + std::to_string(texture_id) + " not registered.");
            }
        } else {
            result->Error("Invalid arguments", "Expected map with textureId.");
        }
    } else {
        result->NotImplemented();
    }
}

// Global function pointers implementation (defined in the header)
void native_texture_plugin_update_texture_pixels(int64_t texture_id, const uint8_t* pixels, int width, int height) {
    if (g_texture_plugin_instance) {
        std::lock_guard<std::mutex> lock(g_texture_plugin_instance->textures_mutex_);
        auto it = g_texture_plugin_instance->textures_.find(texture_id);
        if (it != g_texture_plugin_instance->textures_.end()) {
            it->second->UpdatePixels(pixels, width, height);
        }
    }
}

void native_texture_plugin_mark_texture_frame_available(int64_t texture_id) {
    if (g_texture_plugin_instance && g_texture_plugin_instance->texture_registrar_) {
        g_texture_plugin_instance->texture_registrar_->MarkTextureFrameAvailable(texture_id);
    }
}

} // namespace ar_control_live_studio
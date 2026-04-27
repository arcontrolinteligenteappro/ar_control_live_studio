#ifndef REPLAY_ENGINE_H
#define REPLAY_ENGINE_H

#include <stdint.h>
#include <stddef.h>

// Usa extern "C" para prevenir la "decoración" de nombres de C++, 
// facilitando que FFI encuentre las funciones.
#ifdef __cplusplus
extern "C" {
#endif

// Puntero opaco a la estructura del búfer nativo. Dart solo conoce la dirección, no la implementación.
typedef struct ReplayBuffer ReplayBuffer;

__attribute__((visibility("default"))) __attribute__((used))
ReplayBuffer* replay_buffer_create(int capacity_seconds, int frames_per_second);

__attribute__((visibility("default"))) __attribute__((used))
void replay_buffer_add_frame(ReplayBuffer* buffer, const uint8_t* frame_data, size_t frame_size, bool is_key_frame);

__attribute__((visibility("default"))) __attribute__((used))
int32_t replay_buffer_save_to_file(ReplayBuffer* buffer, const char* output_path);

__attribute__((visibility("default"))) __attribute__((used))
void replay_buffer_start_playback(ReplayBuffer* buffer, int64_t texture_id);

__attribute__((visibility("default"))) __attribute__((used))
void replay_buffer_stop_playback(ReplayBuffer* buffer);

__attribute__((visibility("default"))) __attribute__((used))
void replay_buffer_destroy(ReplayBuffer* buffer);

#ifdef __cplusplus
}
#endif

#endif // REPLAY_ENGINE_H
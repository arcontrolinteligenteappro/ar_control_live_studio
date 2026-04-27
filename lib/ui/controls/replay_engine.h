#include <stdint.h>
#include <stddef.h>

// Usa extern "C" para prevenir la "decoración" de nombres de C++, 
// facilitando que FFI encuentre las funciones.
#ifdef __cplusplus
extern "C" {
#endif

// Puntero opaco a la estructura del búfer nativo. Dart solo conoce la dirección, no la implementación.
typedef struct ReplayBuffer ReplayBuffer;

/**
 * Crea un nuevo ring buffer.
 * @param capacity_seconds La duración del búfer en segundos.
 * @param frames_per_second Los FPS del video.
 * @param bitrate El bitrate del codificador en bits/segundo.
 * @return Un puntero al búfer creado, o NULL si falla.
 */
ReplayBuffer* replay_buffer_create(int capacity_seconds, int frames_per_second, int bitrate);

/**
 * Añade un frame de video crudo al búfer.
 * El búfer lo codificará a H.264 y gestionará la memoria internamente.
 * @param buffer Un puntero a la instancia de ReplayBuffer.
 * @param y_plane Puntero al plano Y.
 * @param y_stride Stride del plano Y.
 * @param u_plane Puntero al plano U.
 * @param u_stride Stride del plano U.
 * @param v_plane Puntero al plano V.
 * @param v_stride Stride del plano V.
 * @param width Ancho del frame.
 * @param height Alto del frame.
 */
void replay_buffer_add_frame(ReplayBuffer* buffer, const uint8_t* y_plane, int y_stride, const uint8_t* u_plane, int u_stride, const uint8_t* v_plane, int v_stride, int width, int height);

/**
 * Guarda el contenido del ring buffer en un archivo. Esta operación es bloqueante.
 * @param buffer Un puntero a la instancia de ReplayBuffer.
 * @param output_path La ruta codificada en UTF-8 para guardar el archivo MP4.
 * @return 0 si tiene éxito, un valor distinto de cero si falla.
 */
int32_t replay_buffer_save_to_file(ReplayBuffer* buffer, const char* output_path);

/**
 * Destruye el búfer y libera toda la memoria asociada.
 * @param buffer Un puntero a la instancia de ReplayBuffer.
 */
void replay_buffer_destroy(ReplayBuffer* buffer);

#ifdef __cplusplus
}
#endif
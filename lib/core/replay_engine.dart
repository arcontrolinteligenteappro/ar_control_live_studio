import 'dart:ffi';
import 'package:ffi/ffi.dart';
import 'package:flutter/foundation.dart';
import 'package:camera/camera.dart';
import 'native_texture_plugin.dart';

class ReplayBindings {} // Placeholder
/// ReplayEngine: Abstracción en Dart para el búfer nativo de Instant Replay.
/// Gestiona el ciclo de vida del ring buffer nativo a través de FFI.
/// Este enfoque mantiene los grandes búferes de video fuera del heap de Dart, evitando pausas del GC.
class ReplayEngine {  
  // ignore: unused_field
  late final ReplayBindings _bindings;
  Pointer<Void>? _buffer;
  final ValueNotifier<int?> playbackTextureId = ValueNotifier(null);
  final NativeTexturePlugin _nativeTexturePlugin;

  bool _isBuffering = false;

  static final ReplayEngine _instance = ReplayEngine._internal();
  factory ReplayEngine() => _instance;

  @visibleForTesting
  ReplayEngine.createForTest({required ReplayBindings bindings, required NativeTexturePlugin texturePlugin})
      : _bindings = bindings, _nativeTexturePlugin = texturePlugin;

  ReplayEngine._internal() : _nativeTexturePlugin = NativeTexturePlugin() {
    // try {
    //   _bindings = bindings ?? ReplayBindings();
    // } catch (e) {
    //   debugPrint("FALLO AL CARGAR LIBRERÍA NATIVA REPLAY ENGINE: $e");
    //   // In a test environment, we might not have the native library.
    //   // The mock will be injected, so this is fine.
    // }
  } 

  /// Crea el ring buffer nativo con una capacidad específica.
  /// [durationInSeconds] es la duración de la repetición (ej. 5 para 5 segundos).
  /// [fps] son los fotogramas por segundo esperados.
  void startBuffering({int durationInSeconds = 5, int fps = 30, int bitrate = 2000000}) {
    if (_isBuffering) {
      debugPrint("Replay buffer ya está activo.");
      return;
    }
    // _buffer = _bindings.createBuffer(durationInSeconds, fps, bitrate);
    // if (_buffer != null && _buffer != Pointer.fromAddress(0)) {
    //   _isBuffering = true;
    //   debugPrint("ReplayEngine: Búfer nativo creado para $durationInSeconds s a $fps fps con bitrate $bitrate.");
    // } else {
    //   debugPrint("ReplayEngine: Fallo al crear el búfer nativo.");
    // }
  }

  /// Añade un frame de video (como lista de bytes) al búfer nativo.
  /// El motor nativo se encargará de la codificación.
  void addFrame(CameraImage image) {
    if (!_isBuffering || _buffer == null) return;

    // Asigna memoria nativa para cada plano y copia los datos.
    final yPtr = calloc<Uint8>(image.planes[0].bytes.length);
    yPtr.asTypedList(image.planes[0].bytes.length).setAll(0, image.planes[0].bytes);

    final uPtr = calloc<Uint8>(image.planes[1].bytes.length);
    uPtr.asTypedList(image.planes[1].bytes.length).setAll(0, image.planes[1].bytes);

    final vPtr = calloc<Uint8>(image.planes[2].bytes.length);
    vPtr.asTypedList(image.planes[2].bytes.length).setAll(0, image.planes[2].bytes);

    // _bindings.addFrame(
    //     _buffer!,
    //     yPtr, image.planes[0].bytesPerRow,
    //     uPtr, image.planes[1].bytesPerRow,
    //     vPtr, image.planes[2].bytesPerRow,
    //     image.width,
    //     image.height
    // );

    calloc.free(yPtr);
    calloc.free(uPtr);
    calloc.free(vPtr);
  }

  /// Dispara el código nativo para guardar los frames del búfer en un archivo.
  /// Devuelve la ruta del archivo guardado si tiene éxito, o null si falla.
  Future<String?> triggerSave(String fileName) async {
    if (!_isBuffering || _buffer == null) {
      debugPrint("No se puede guardar la repetición, el búfer no está activo.");
      return null;
    }
    
    debugPrint("ReplayEngine: Disparando guardado a $fileName...");
    final pathPointer = fileName.toNativeUtf8();
    // final result = _bindings.saveToFile(_buffer!, pathPointer);
    calloc.free(pathPointer);

    return null; // (result == 0) ? fileName : null;
  }

  /// Inicia la reproducción del contenido del búfer a una textura de Flutter.
  /// Actualiza `playbackTextureId` con el ID de la textura.
  Future<void> startPlayback() async {
    if (_buffer == null) {
      debugPrint("ReplayEngine: No se puede iniciar la reproducción, el búfer no está activo.");
      return;
    }

    // Obtener un textureId real del plugin de Flutter.
    final int? newTextureId = await _nativeTexturePlugin.createFlutterTexture();
    playbackTextureId.value = newTextureId;

    // Pasar el textureId al lado nativo para que sepa dónde renderizar.
    // _bindings.startPlayback(_buffer!, newTextureId ?? 0); // Pass the actual Flutter texture ID
    debugPrint("ReplayEngine: Playback iniciado. Texture ID: $newTextureId");
  }

  /// Detiene la reproducción del búfer.
  void stopPlayback() {
    if (_buffer == null) return;
    // _bindings.stopPlayback(_buffer!);
    if (playbackTextureId.value != null) _nativeTexturePlugin.disposeFlutterTexture(playbackTextureId.value!);
    playbackTextureId.value = null;
    debugPrint("ReplayEngine: Playback detenido.");
  }

  /// Destruye el búfer nativo y libera toda su memoria.
  void stopBuffering() {
    if (_buffer != null && _buffer != Pointer.fromAddress(0)) {
      // _bindings.destroyBuffer(_buffer!);
      stopPlayback(); // Asegurarse de detener la reproducción si está activa.
    }
    _buffer = null;
    _isBuffering = false;
  }
}
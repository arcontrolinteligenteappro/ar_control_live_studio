import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';

/// Interfaz Dart para un plugin de audio nativo que gestiona la mezcla y el volumen.
///
/// Este plugin conceptual se encargaría de:
/// 1. Inicializar un motor de audio nativo (ej. Core Audio en iOS/macOS, OpenSL ES/AAudio en Android).
/// 2. Registrar fuentes de audio (ej. streams WebRTC, entradas de micrófono local).
/// 3. Aplicar volumen y realizar cross-fades a nivel de muestras de audio.
class NativeAudioPlugin {
  static const MethodChannel _channel = MethodChannel('ar_control_live_studio/audio');

  /// Inicializa el motor de audio nativo.
  Future<void> initMixer() async {
    try {
      await _channel.invokeMethod('initMixer');
      debugPrint('NativeAudioPlugin: Mixer inicializado.');
    } on PlatformException catch (e) {
      debugPrint("Failed to init mixer: '${e.message}'.");
    }
  }

  /// Registra una fuente de audio con el motor nativo.
  /// `sourceId` es el identificador único de la fuente.
  /// `mediaStreamTrackId` es el ID de la pista de audio (ej. de WebRTC) para que el nativo la pueda enganchar.
  Future<void> registerSource(String sourceId, String? mediaStreamTrackId) async {
    try {
      await _channel.invokeMethod('registerSource', {'sourceId': sourceId, 'trackId': mediaStreamTrackId});
      debugPrint('NativeAudioPlugin: Fuente de audio $sourceId registrada.');
    } on PlatformException catch (e) {
      debugPrint("Failed to register source $sourceId: '${e.message}'.");
    }
  }

  /// Establece el volumen de una fuente de audio específica en el motor nativo.
  Future<void> setSourceVolume(String sourceId, double volume) async {
    await _channel.invokeMethod('setSourceVolume', {'sourceId': sourceId, 'volume': volume});
  }

  /// Inicia un cross-fade en el motor de audio nativo.
  Future<void> crossfade({String? fromSourceId, required String toSourceId, required double toSourceTargetVolume, required int durationMs}) async {
    await _channel.invokeMethod('crossfade', {
      'fromSourceId': fromSourceId,
      'toSourceId': toSourceId,
      'toSourceTargetVolume': toSourceTargetVolume,
      'durationMs': durationMs,
    });
  }
}
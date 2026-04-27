import 'package:flutter/foundation.dart';
import 'package:ar_control_live_studio/core/replay_engine.dart';
import 'hal.dart';

/// Implementación de una fuente de video desde el motor nativo ReplayEngine.
class ReplaySourceHAL extends VideoSourceHAL {
  @override
  final String id = 'replay_output';
  @override
  final String name = 'Replay Engine';

  final ReplayEngine _replayEngine;

  @override
  final ValueNotifier<int?> textureIdNotifier = ValueNotifier(null);

  ReplaySourceHAL(this._replayEngine);

  @override
  Future<void> initialize() async {
    debugPrint('ReplaySourceHAL inicializado. Iniciando reproducción del ReplayEngine.');
    
    await _replayEngine.startPlayback();
    // Escuchar los cambios en el textureId del ReplayEngine
    _replayEngine.playbackTextureId.addListener(_updateTextureId);
  }

  void _updateTextureId() {
    textureIdNotifier.value = _replayEngine.playbackTextureId.value;
  }

  @override
  void dispose() {
    _replayEngine.stopPlayback();
    _replayEngine.playbackTextureId.removeListener(_updateTextureId);
    textureIdNotifier.dispose();
    super.dispose();
    debugPrint('ReplaySourceHAL liberado.');
  }
}
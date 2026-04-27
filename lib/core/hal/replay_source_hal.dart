import 'package:ar_control_live_studio/core/hal.dart';
import 'package:ar_control_live_studio/core/replay_engine.dart';
import 'package:flutter/foundation.dart';

class ReplaySourceHAL extends VideoSourceHAL {
  final ReplayEngine _replayEngine;
  final ValueNotifier<bool> isPlaying = ValueNotifier(false);

  ReplaySourceHAL(this._replayEngine);

  @override
  String get id => 'replay';

  @override
  String get label => 'Instant Replay';

  ValueNotifier<int?> get textureIdNotifier => _replayEngine.playbackTextureId;

  @override
  Future<void> initialize() async {
    // Placeholder for replay source initialization
    _replayEngine.startBuffering();
  }

  Future<void> startPlayback() async {
    await _replayEngine.startPlayback();
    isPlaying.value = true;
  }

  Future<String?> saveReplay(String fileName) async {
    return await _replayEngine.triggerSave(fileName);
  }

  void stopPlayback() {
    _replayEngine.stopPlayback();
    isPlaying.value = false;
  }

  @override
  Future<void> dispose() async {
    _replayEngine.stopBuffering();
    isPlaying.dispose();
  }
}
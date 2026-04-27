import 'package:flutter_riverpod/flutter_riverpod.dart';

class AudioSource {
  final String id;
  final String? trackId;
  double volume;
  AudioSource({required this.id, this.trackId, this.volume = 1.0});
}

class AudioEngine extends StateNotifier<List<AudioSource>> {
  AudioEngine() : super([]);

  void addSource(String id, String? trackId) {
    if (!state.any((s) => s.id == id)) {
      state = [...state, AudioSource(id: id, trackId: trackId)];
    }
  }

  void setVolume(String id, double volume) {
    state = [
      for (final s in state)
        if (s.id == id) AudioSource(id: s.id, trackId: s.trackId, volume: volume) else s
    ];
  }
}

final audioEngineProvider = StateNotifierProvider<AudioEngine, List<AudioSource>>((ref) {
  return AudioEngine();
});
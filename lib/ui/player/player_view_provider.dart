import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:audioplayers/audioplayers.dart';

/// Estado inmutable para la vista del reproductor.
@immutable
class PlayerState {
  final bool teleprompter;
  final String? selectedCastingDevice;
  final bool syncConnected;
  final bool isCastingBuffering;
  final double teleprompterSpeed; // New: Teleprompter scroll speed multiplier

  const PlayerState({
    this.teleprompter = false,
    this.selectedCastingDevice,
    this.syncConnected = false,
    this.isCastingBuffering = false,
    this.teleprompterSpeed = 1.0, // Default speed
  });

  PlayerState copyWith({
    bool? teleprompter,
    String? selectedCastingDevice,
    bool? syncConnected,
    bool clearCastingDevice = false,
    bool? isCastingBuffering,
    double? teleprompterSpeed,
  }) {
    return PlayerState(
      teleprompter: teleprompter ?? this.teleprompter,
      selectedCastingDevice: clearCastingDevice ? null : selectedCastingDevice ?? this.selectedCastingDevice,
      syncConnected: syncConnected ?? this.syncConnected,
      isCastingBuffering: isCastingBuffering ?? this.isCastingBuffering,
      teleprompterSpeed: teleprompterSpeed ?? this.teleprompterSpeed,
    );
  }
}

/// Notificador que gestiona el estado de la vista del reproductor.
class PlayerNotifier extends StateNotifier<PlayerState> {
  PlayerNotifier() : super(const PlayerState());

  void toggleTeleprompter() => state = state.copyWith(teleprompter: !state.teleprompter);
  
  void selectCastingDevice(String? deviceName) {
    // Si estamos seleccionando un nuevo dispositivo
    if (deviceName != null && state.selectedCastingDevice != deviceName) {
      state = state.copyWith(selectedCastingDevice: deviceName, isCastingBuffering: true);
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted && state.selectedCastingDevice == deviceName) {
          state = state.copyWith(isCastingBuffering: false);
        }
      });
    } 
    // De lo contrario, estamos deseleccionando (ya sea tocando el mismo dispositivo o pasando nulo)
    else {
      state = state.copyWith(clearCastingDevice: true, isCastingBuffering: false);
    }
  }

  void setTeleprompterSpeed(double speed) => state = state.copyWith(teleprompterSpeed: speed);

  void toggleSync() => state = state.copyWith(syncConnected: !state.syncConnected);
}

/// Provider que expone el estado de la vista del reproductor.
final playerProvider = StateNotifierProvider<PlayerNotifier, PlayerState>((ref) {
  return PlayerNotifier();
});

/// Provider para una instancia de AudioPlayer para efectos de sonido.
final audioPlayerProvider = Provider<AudioPlayer>((ref) {
  final audioPlayer = AudioPlayer();
  ref.onDispose(() {
    audioPlayer.dispose();
  });
  return audioPlayer;
});
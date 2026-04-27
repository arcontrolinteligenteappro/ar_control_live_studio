import 'dart:async';
import 'package:flutter/foundation.dart';
import 'dart:math' as math;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:camera/camera.dart';

enum RtmpConnectionState { disconnected, connecting, live, failed, stopped }

@immutable
class RtmpStreamState {
  final RtmpConnectionState connectionState;
  final String? url;
  final Duration duration;
  final String? errorMessage;
  final int currentBitrate; // in kbps
  final double currentFps;
  final List<int> bitrateHistory;

  const RtmpStreamState({
    this.connectionState = RtmpConnectionState.disconnected,
    this.url,
    this.duration = Duration.zero,
    this.errorMessage,
    this.currentBitrate = 0,
    this.currentFps = 0.0,
    this.bitrateHistory = const [],
  });

  RtmpStreamState copyWith({
    RtmpConnectionState? connectionState,
    String? url,
    Duration? duration,
    String? errorMessage,
    bool clearError = false,
    int? currentBitrate,
    double? currentFps,
    List<int>? bitrateHistory,
  }) {
    return RtmpStreamState(
      connectionState: connectionState ?? this.connectionState,
      url: url ?? this.url,
      duration: duration ?? this.duration,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      currentBitrate: currentBitrate ?? this.currentBitrate,
      currentFps: currentFps ?? this.currentFps,
      bitrateHistory: bitrateHistory ?? this.bitrateHistory,
    );
  }
}

class RtmpStreamEngine extends StateNotifier<RtmpStreamState> {
  Timer? _timer;
  // En una implementación real, esto sería una clase de streamer nativa vía FFI.
  // Por ahora, simulamos su comportamiento.

  RtmpStreamEngine() : super(const RtmpStreamState());

  Future<void> startStream(String url) async {
    if (state.connectionState == RtmpConnectionState.connecting || state.connectionState == RtmpConnectionState.live) {
      return;
    }

    state = state.copyWith(connectionState: RtmpConnectionState.connecting, url: url, duration: Duration.zero, clearError: true);
    debugPrint("RTMP: Connecting to $url...");

    // Simula un retraso de conexión
    await Future.delayed(const Duration(seconds: 2));

    // Simula éxito/fallo
    if (url.startsWith('rtmp://')) {
      state = state.copyWith(connectionState: RtmpConnectionState.live);
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        // Simula estadísticas de transmisión
        final newBitrate = 2000 + math.Random().nextInt(500) - 250; // Fluctúa alrededor de 2000 kbps
        final newFps = 29.5 + math.Random().nextDouble(); // Fluctúa alrededor de 29.5-30.5

        final newHistory = List<int>.from(state.bitrateHistory);
        newHistory.add(newBitrate);
        if (newHistory.length > 60) { // Keep last 60 seconds
          newHistory.removeAt(0);
        }

        state = state.copyWith(
            duration: Duration(seconds: state.duration.inSeconds + 1),
            currentBitrate: newBitrate,
            currentFps: newFps,
            bitrateHistory: newHistory);
      });
      debugPrint("RTMP: Stream is live.");
    } else {
      state = state.copyWith(connectionState: RtmpConnectionState.failed, errorMessage: "Invalid RTMP URL");
      debugPrint("RTMP: Connection failed.");
    }
  }

  void stopStream() {
    if (state.connectionState == RtmpConnectionState.disconnected || state.connectionState == RtmpConnectionState.stopped) return;
    _timer?.cancel();
    state = state.copyWith(
      connectionState: RtmpConnectionState.stopped,
      duration: Duration.zero,
      currentBitrate: 0,
      currentFps: 0.0,
      bitrateHistory: [],
    );
    debugPrint("RTMP: Stream stopped.");
    Future.delayed(const Duration(seconds: 1), () {
      if (state.connectionState == RtmpConnectionState.stopped) state = const RtmpStreamState();
    });
  }

  void addFrame(CameraImage image) {
    if (state.connectionState != RtmpConnectionState.live) return;
    // Aquí se pasarían los frames al codificador/streamer nativo.
  }
}

final rtmpStreamEngineProvider = StateNotifierProvider<RtmpStreamEngine, RtmpStreamState>((ref) {
  return RtmpStreamEngine();
});
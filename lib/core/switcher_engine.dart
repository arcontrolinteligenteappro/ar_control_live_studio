import 'package:flutter/foundation.dart';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ar_control_live_studio/core/replay_engine.dart';
import 'package:ar_control_live_studio/core/hal.dart';
import 'package:ar_control_live_studio/core/audio_engine.dart';
import 'package:ar_control_live_studio/core/rtmp_stream_engine.dart';

@immutable
class SwitcherState {
  final Map<String, VideoSourceHAL> sources;
  final String? previewSourceId;
  final String? programSourceId;
  final bool inTransition;
  final double transitionProgress;
  final bool isRecording;

  const SwitcherState({
    this.sources = const {},
    this.previewSourceId,
    this.programSourceId,
    this.inTransition = false,
    this.transitionProgress = 0.0,
    this.isRecording = false,
  });

  SwitcherState copyWith({
    Map<String, VideoSourceHAL>? sources,
    String? previewSourceId,
    String? programSourceId,
    bool? inTransition,
    double? transitionProgress,
    bool? isRecording,
  }) {
    return SwitcherState(
      sources: sources ?? this.sources,
      previewSourceId: previewSourceId ?? this.previewSourceId,
      programSourceId: programSourceId ?? this.programSourceId,
      inTransition: inTransition ?? this.inTransition,
      transitionProgress: transitionProgress ?? this.transitionProgress,
      isRecording: isRecording ?? this.isRecording,
    );
  }
}

class SwitcherEngine extends StateNotifier<SwitcherState> {
  final Ref _ref;
  SwitcherEngine(this._ref) : super(const SwitcherState());

  final _programAudioSourceIdController = StreamController<String?>.broadcast();
  Stream<String?> get programAudioSourceIdStream => _programAudioSourceIdController.stream;

  // Motor de grabación dedicado.
  ReplayEngine? _recordEngine;

  // Suscripción al stream de frames para grabación.
  StreamSubscription? _frameSubscription;

  void addSource(VideoSourceHAL source) {
    state = state.copyWith(sources: {...state.sources, source.id: source});
    
    // Lógica corregida de asignación inicial
    if (state.programSourceId == null) {
      state = state.copyWith(programSourceId: source.id);
    } else if (state.previewSourceId == null) {
      state = state.copyWith(previewSourceId: source.id);
    }

    // Integración con AudioEngine
    final audioNotifier = _ref.read(audioEngineProvider.notifier);
    // Nota: El acceso a renderer depende de tu implementación de WebRTC
    String? audioTrackId;
    try {
       // audioTrackId = (source is RemoteVideoSourceHAL) ? source.renderer?.srcObject?.getAudioTracks().first.id : null;
    } catch (_) {}
    
    audioNotifier.addSource(source.id, audioTrackId);
    _programAudioSourceIdController.add(state.programSourceId);
    _updateAllTallyLights();
  }

  void selectForPreview(String sourceId) {
    if (state.sources.containsKey(sourceId) && sourceId != state.programSourceId) {
      state = state.copyWith(previewSourceId: sourceId);
    }
  }

  void executeCut() {
    if (state.previewSourceId != null && !state.inTransition) {
      final newProgramId = state.previewSourceId;
      state = state.copyWith(programSourceId: newProgramId);
      _programAudioSourceIdController.add(newProgramId);
      if (state.isRecording) {
        // Si estamos grabando, cambiamos la fuente de frames.
        _subscribeToProgramSource();
        _updateAllTallyLights();
      }
    }
  }

  Future<void> executeAuto(Duration duration, {void Function(double progress)? onProgress}) async {
    if (state.previewSourceId == null || state.inTransition) return;

    state = state.copyWith(inTransition: true);

    // Simula el progreso de la transición
    final steps = 50;
    final stepDuration = Duration(milliseconds: duration.inMilliseconds ~/ steps);

    for (int i = 1; i <= steps; i++) {
      await Future.delayed(stepDuration);
      final progress = i / steps;
      state = state.copyWith(transitionProgress: progress);
      onProgress?.call(progress);
    }

    final newProgramId = state.previewSourceId;
    state = state.copyWith(
        programSourceId: newProgramId,
        inTransition: false,
        transitionProgress: 0.0);
    _programAudioSourceIdController.add(newProgramId);
    if (state.isRecording) {
      // Si estamos grabando, cambiamos la fuente de frames.
      _subscribeToProgramSource();
      _updateAllTallyLights();
    }
  }

  void _subscribeToProgramSource() {
    // Detener cualquier suscripción anterior en todas las fuentes.
    _frameSubscription?.cancel();
    state.sources.values.forEach((s) => s.stopImageStream());

    if (!state.isRecording || _recordEngine == null) return;

    final programSource = state.sources[state.programSourceId];

    if (programSource != null) {
      if (programSource is RemoteVideoSourceHAL) {
        debugPrint("ADVERTENCIA: La grabación de fuentes remotas (WebRTC) no está implementada de forma nativa y no se incluirá en la grabación.");
      }
      final rtmpEngine = _ref.read(rtmpStreamEngineProvider.notifier);
      programSource.startImageStream((image) {
        if (!state.isRecording || _recordEngine == null) {
          programSource.stopImageStream();
          return;
        }
        // Pasa el objeto de imagen completo al motor de grabación, que se encarga de la codificación.
        _recordEngine!.addFrame(image);

        // Pasa también el frame al motor de streaming si está activo.
        rtmpEngine.addFrame(image);
      });
    }
  }

  void _updateAllTallyLights() {
    final programId = state.programSourceId;
    for (final source in state.sources.values) {
      if (source is RemoteVideoSourceHAL) {
        final isProgram = source.id == programId;
        // Send notification without waiting for it. 
        http.post(
          Uri.parse('http://${source.ip}:8080/tally'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'isProgram': isProgram}),
        ).catchError((e) {
          // Log error but don't block.
          debugPrint("Failed to send tally to ${source.id} at ${source.ip}: $e");
          return http.Response('', 500);
        });
      }
    }
  }

  void startRecording({int bitrate = 2000000}) {
    if (state.isRecording) return;

    _recordEngine = ReplayEngine();
    // Usar un búfer de muy larga duración para simular una sesión de grabación.
    _recordEngine!.startBuffering(durationInSeconds: 3600, bitrate: bitrate); // 1 hora
    state = state.copyWith(isRecording: true);
    _subscribeToProgramSource();
    debugPrint("GRABACIÓN INICIADA: Bitrate: $bitrate. Los frames ahora se codifican a H.264 en el motor nativo.");
  }

  Future<String?> stopRecording(String fileName) async {
    if (!state.isRecording || _recordEngine == null) return null;

    // Detener la suscripción a los frames.
    await Future.wait(state.sources.values.map((s) => s.stopImageStream()));
    _frameSubscription?.cancel();
    _frameSubscription = null;

    debugPrint("Deteniendo grabación y guardando en $fileName...");
    // En una implementación real, se esperaría a que se procesen los frames en cola.
    final filePath = await _recordEngine!.triggerSave(fileName);

    _recordEngine!.stopBuffering();
    _recordEngine = null;

    state = state.copyWith(isRecording: false);

    if (filePath != null) {
      debugPrint("Grabación guardada con éxito en $filePath");
    } else {
      debugPrint("Fallo al guardar la grabación.");
    }
    return filePath;
  }

  @override
  void dispose() {
    _programAudioSourceIdController.close();
    super.dispose();
  }
}

final switcherEngineProvider = StateNotifierProvider<SwitcherEngine, SwitcherState>((ref) {
  return SwitcherEngine(ref);
});
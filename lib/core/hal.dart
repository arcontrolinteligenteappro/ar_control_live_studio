import 'dart:async';
import 'dart:convert';

import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:flutter/foundation.dart';
import 'package:camera/camera.dart'; 
import 'package:http/http.dart' as http;
import 'package:ar_control_live_studio/core/replay_engine.dart';
// Importamos tu cliente proxy, aunque no lo usemos directamente aquí, 
// previene errores de "Target of URI doesn't exist" si otros archivos dependen de esto.
// import 'package:ar_control_live_studio/core/network/proxy_aware_http_client.dart'; 

// --- BASE VIDEO HAL ---
abstract class VideoSourceHAL {
  String get id;
  String get label;
  String get name => label; 
  
  Future<void> initialize();
  // Placeholders para la suscripción al stream. Los HALs concretos deben sobreescribir esto.
  Future<void> startImageStream(void Function(CameraImage image) onAvailable) async {}
  Future<void> stopImageStream() async {}
  ValueNotifier<int?> get textureIdNotifier; 
  
  // Soluciona el error "Missing concrete implementation of dispose"
  Future<void> dispose() async {} 
}

// --- CAMARAS REMOTAS (WEBRTC) ---
class RemoteVideoSourceHAL extends VideoSourceHAL {
  @override
  final String id;
  @override
  final String label;
  final String ip;
  late final RTCVideoRenderer renderer;
  RTCPeerConnection? _peerConnection;
  bool get supportsPTZ => true; // Remote cameras are assumed to support PTZ
  final ValueNotifier<RTCPeerConnectionState?> connectionState = ValueNotifier(null);

  @override
  final ValueNotifier<int?> textureIdNotifier = ValueNotifier(null);

  RemoteVideoSourceHAL({
    required this.id, 
    required this.label, 
    required this.ip,
  }) {
    renderer = RTCVideoRenderer();
  }

  @override
  Future<void> initialize() async {
    await renderer.initialize();
    
    renderer.addListener(() {
      textureIdNotifier.value = renderer.textureId;
    });

    _peerConnection = await createPeerConnection({
      'iceServers': [
        {'urls': 'stun:stun.l.google.com:19302'},
      ]
    });

    _peerConnection!.onConnectionState = (state) {
      connectionState.value = state;
    };

    _peerConnection!.onTrack = (event) {
      if (event.track.kind == 'video' && event.streams.isNotEmpty) {
        renderer.srcObject = event.streams[0];
      }
    };

    await _peerConnection!.addTransceiver(
      kind: RTCRtpMediaType.RTCRtpMediaTypeVideo, 
      init: RTCRtpTransceiverInit(direction: TransceiverDirection.RecvOnly)
    );

    final offer = await _peerConnection!.createOffer();
    await _peerConnection!.setLocalDescription(offer);

    // Signaling
    try {
      final response = await http.post(
        Uri.parse('http://$ip:8080/offer'), 
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(offer.toMap()),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final answer = RTCSessionDescription(data['sdp'], data['type']);
        await _peerConnection!.setRemoteDescription(answer);
      }
    } catch (e) {
      debugPrint('Fallo en la señalización WebRTC: $e'); // Cambiado a debugPrint
    }
  }

  @override
  Future<void> dispose() async {
    await _peerConnection?.close();
    await renderer.dispose(); 
    connectionState.dispose();
    textureIdNotifier.dispose();
  }

  Future<void> controlPTZ({double pan = 0, double tilt = 0, double zoom = 0}) async {
    try {
      await http.post(
        Uri.parse('http://$ip:8080/ptz'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'pan': pan.clamp(-1.0, 1.0),
          'tilt': tilt.clamp(-1.0, 1.0),
          'zoom': zoom.clamp(-1.0, 1.0),
        }),
      ).timeout(const Duration(milliseconds: 500));
    } catch (e) {
      if (e is! TimeoutException) debugPrint("PTZ command failed for $id: $e"); // Cambiado a debugPrint
    }
  }

  Future<void> goToPtzPosition({required double pan, required double tilt, required double zoom}) async {
    try {
      await http.post(
        Uri.parse('http://$ip:8080/ptz_goto'), 
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'pan': pan,
          'tilt': tilt,
          'zoom': zoom,
        }),
      ).timeout(const Duration(seconds: 1));
    } catch (e) {
      debugPrint("Go to PTZ position command failed for $id: $e"); // Cambiado a debugPrint
    }
  }

  @override
  Future<void> startImageStream(void Function(CameraImage image) onAvailable) async {
    debugPrint("ADVERTENCIA: La captura de frames desde fuentes WebRTC remotas no está implementada."); // Cambiado a debugPrint
  }

  @override
  Future<void> stopImageStream() async {}
}

// --- CAMARA NATIVA (HAL Corregido) ---
class CameraHAL extends VideoSourceHAL {
  @override
  final String id;
  @override
  final String label;
  final CameraDescription cameraDescription;

  CameraController? _controller;
  @override
  final ValueNotifier<int?> textureIdNotifier = ValueNotifier(null); 
  final ValueNotifier<bool> isInitialized = ValueNotifier(false);

  CameraHAL({required this.id, required this.label, required this.cameraDescription});

  CameraController? get controller => _controller;

  @override
  Future<void> initialize() async {
    _controller = CameraController(
      cameraDescription,
      ResolutionPreset.high,
      enableAudio: false,
    );

    try {
      await _controller!.initialize();
      textureIdNotifier.value = _controller!.cameraId; // FIX CRÍTICO: .textureId no existe en CameraController, es .cameraId
      isInitialized.value = true;
    } on CameraException catch (e) {
      debugPrint('Error al inicializar la cámara $label: $e'); // Cambiado a debugPrint
      _controller = null;
      textureIdNotifier.value = null;
      isInitialized.value = false;
    }
  }
  
  @override
  Future<void> dispose() async {
    await stopImageStream();
    await _controller?.dispose();
    textureIdNotifier.dispose(); 
    isInitialized.dispose();
  }

  @override
  Future<void> startImageStream(void Function(CameraImage image) onAvailable) async {
    if (_controller != null && _controller!.value.isInitialized && !_controller!.value.isStreamingImages) {
      await _controller!.startImageStream(onAvailable);
    }
  }

  @override
  Future<void> stopImageStream() async {
    if (_controller != null && _controller!.value.isStreamingImages) {
      await _controller!.stopImageStream();
    }
  }
}

// --- INSTANT REPLAY HAL ---
class ReplaySourceHAL extends VideoSourceHAL {
  @override
  String get id => 'replay';
  @override
  String get label => 'Instant Replay';
  final ReplayEngine _replayEngine;
  final ValueNotifier<bool> isPlaying = ValueNotifier(false);

  ReplaySourceHAL(this._replayEngine);

  @override
  ValueNotifier<int?> get textureIdNotifier => _replayEngine.playbackTextureId;

  @override
  Future<void> initialize() async {
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
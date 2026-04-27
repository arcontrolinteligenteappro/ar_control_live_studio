import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'hal.dart';
import 'package:ar_control_live_studio/core/network/node_discovery_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ar_control_live_studio/core/settings_provider.dart';

/// Representa una fuente de video que proviene de un nodo 'CAMERA' remoto en la red.
class RemoteVideoSourceHAL extends VideoSourceHAL {
  @override
  final String id;
  @override
  final String name;
  final String ipAddress;
  final NodeDiscoveryService _discoveryService;
  final WidgetRef _ref;

  @override
  final ValueNotifier<int?> textureIdNotifier = ValueNotifier(null);

  RTCPeerConnection? _peerConnection;
  final RTCVideoRenderer _renderer = RTCVideoRenderer();
  Timer? _statsTimer;
  int _lastPacketsLost = 0;

  /// Expone el renderer para que otros módulos (como el AudioEngine) puedan acceder al stream.
  RTCVideoRenderer? get renderer => _renderer;

  RemoteVideoSourceHAL({
    required this.id,
    required this.name,
    required this.ipAddress,
    required NodeDiscoveryService discoveryService,
    required WidgetRef ref,
  })  : _discoveryService = discoveryService,
        _ref = ref;

  @override
  Future<void> initialize() async {
    debugPrint('RemoteVideoSourceHAL ($name en $ipAddress) inicializando WebRTC...');
    await _renderer.initialize();

    final Map<String, dynamic> configuration = {
      'iceServers': [{'urls': 'stun:stun.l.google.com:19302'}]
    };
    _peerConnection = await createPeerConnection(configuration);

    _peerConnection!.onConnectionState = (state) {
      debugPrint('RemoteVideoSourceHAL ($name): Connection state changed to $state');
      if (state == RTCPeerConnectionState.RTCPeerConnectionStateConnected) {
        _startStatsMonitoring();
      } else {
        _stopStatsMonitoring();
        networkWarningNotifier.value = false;
      }
    };

    _peerConnection!.onIceCandidate = (candidate) {
      if (candidate.candidate != null) {
        _discoveryService.sendDirectMessage(
          ipAddress,
          jsonEncode({'type': 'iceCandidate', 'candidate': candidate.toMap()}),
        );
      }
    };

    _peerConnection!.onTrack = (event) {
      if (event.track.kind == 'video' && event.streams.isNotEmpty) {
        _renderer.srcObject = event.streams[0];
        textureIdNotifier.value = _renderer.textureId;
        debugPrint('RemoteVideoSourceHAL ($name): Video track recibido y renderizando.');
      }
      if (event.track.kind == 'audio' && event.streams.isNotEmpty) {
        debugPrint('RemoteVideoSourceHAL ($name): Audio track recibido.');
      }
    };

    final offer = await _peerConnection!.createOffer({
      'offerToReceiveVideo': true,
      'offerToReceiveAudio': true,
    });
    await _peerConnection!.setLocalDescription(offer);

    debugPrint('RemoteVideoSourceHAL ($name): Enviando oferta a $ipAddress');
    _discoveryService.sendDirectMessage(
      ipAddress,
      jsonEncode({'type': 'offer', 'sdp': offer.sdp, 'type': offer.type}),
    );

    _discoveryService.discoveredNodes.listen((nodeInfo) async {
      if (nodeInfo.ipAddress == ipAddress) {
        try {
          final message = jsonDecode(nodeInfo.status);
          if (message['type'] == 'answer') {
            if (_peerConnection?.getRemoteDescription() == null) {
              debugPrint('RemoteVideoSourceHAL ($name): Recibida respuesta de $ipAddress');
              await _peerConnection!.setRemoteDescription(
                RTCSessionDescription(message['sdp'], message['type']),
              );
            }
          } else if (message['type'] == 'iceCandidate') {
            await _peerConnection!.addCandidate(
              RTCIceCandidate(
                message['candidate']['candidate'],
                message['candidate']['sdpMid'],
                message['candidate']['sdpMLineIndex'],
              ),
            );
          }
        } catch (e) {
          // Ignorar
        }
      }
    });
  }

  void _startStatsMonitoring() {
    _statsTimer?.cancel();
    _statsTimer = Timer.periodic(const Duration(seconds: 2), (_) async {
      if (_peerConnection == null) return;
      final stats = await _peerConnection!.getStats();
      for (var report in stats) {
        if (report.type == 'inbound-rtp' && report.values['kind'] == 'video') {
          final packetsLost = report.values['packetsLost'] ?? 0;
          if (packetsLost > _lastPacketsLost) {
            networkWarningNotifier.value = true;
          } else {
            networkWarningNotifier.value = false;
          }
          _lastPacketsLost = packetsLost;
          break;
        }
      }
    });
  }

  void _stopStatsMonitoring() {
    _statsTimer?.cancel();
    _statsTimer = null;
  }

  @override
  void dispose() {
    _stopStatsMonitoring();
    _renderer.srcObject = null;
    _renderer.dispose();
    _peerConnection?.close();
    _peerConnection = null;
    textureIdNotifier.dispose();
    super.dispose();
    debugPrint('RemoteVideoSourceHAL ($name) liberado.');
  }
}
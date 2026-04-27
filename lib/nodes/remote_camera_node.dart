import 'dart:async';
import 'dart:convert';

import 'package:ar_control_live_studio/core/network/node_discovery_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:permission_handler/permission_handler.dart';

/// Punto de entrada para la aplicación de nodo de cámara remota.
void main() {
  runApp(const ProviderScope(child: RemoteCameraApp()));
}

class RemoteCameraApp extends StatelessWidget {
  const RemoteCameraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AR Control - Camera Node',
      theme: ThemeData.dark(),
      home: const RemoteCameraNodeView(),
    );
  }
}

class RemoteCameraNodeView extends ConsumerStatefulWidget {
  const RemoteCameraNodeView({super.key});

  @override
  ConsumerState<RemoteCameraNodeView> createState() => _RemoteCameraNodeViewState();
}

class _RemoteCameraNodeViewState extends ConsumerState<RemoteCameraNodeView> {
  final RTCVideoRenderer _localRenderer = RTCVideoRenderer();
  MediaStream? _localStream;
  RTCPeerConnection? _peerConnection;
  Timer? _broadcastTimer;
  String _status = "Initializing...";

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    await [Permission.camera, Permission.microphone].request();
    await _localRenderer.initialize();

    try {
      _localStream = await navigator.mediaDevices.getUserMedia({
        'audio': true,
        'video': {'facingMode': 'user'}
      });
      _localRenderer.srcObject = _localStream;
      setState(() { _status = "Waiting for ENGINE..."; });

      _startNetworkServices();
    } catch (e) {
      setState(() { _status = "Error: Could not access camera/mic."; });
      debugPrint("Error getting media stream: $e");
    }
  }

  void _startNetworkServices() {
    final discoveryNotifier = ref.read(nodeDiscoveryProvider.notifier);
    discoveryNotifier.start();

    // Anunciarse como 'CAMERA' cada segundo.
    _broadcastTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      discoveryNotifier.broadcastPresence();
    });

    // Escuchar ofertas del ENGINE.
    ref.listen<List<RemoteNode>>(nodeDiscoveryProvider, (previous, next) {
      for (final node in next) {
        if (node.type == 'ENGINE') {
          try {
            final message = jsonDecode(node.name); // Assuming status is in name for this example
            if (message['type'] == 'offer' && _peerConnection == null) {
              debugPrint("Offer received from ENGINE at ${node.ip}. Creating connection...");
              setState(() { _status = "Connecting to ${node.ip}..."; });
              _createPeerConnection(node.ip, message);
            }
          } catch (e) {
            // Ignore parse errors, status might not be signal data
          }
        }
      }
    });
  }

  Future<void> _createPeerConnection(String engineIp, Map<String, dynamic> offer) async {
    final config = {
      'iceServers': [{'urls': 'stun:stun.l.google.com:19302'}]
    };
    _peerConnection = await createPeerConnection(config);

    // Añadir tracks de audio y video a la conexión.
    _localStream?.getTracks().forEach((track) {
      _peerConnection?.addTrack(track, _localStream!);
    });

    _peerConnection!.onIceCandidate = (candidate) {
      if (candidate.candidate != null) {
        ref.read(nodeDiscoveryProvider.notifier).sendDirectMessage(
          engineIp,
          jsonEncode({'type': 'iceCandidate', 'candidate': candidate.toMap()}),
        );
      }
    };

    _peerConnection!.onConnectionState = (state) {
      debugPrint("Connection state: $state");
      setState(() {
        _status = "Connection: ${state.name}";
      });
      if (state == RTCPeerConnectionState.RTCPeerConnectionStateDisconnected ||
          state == RTCPeerConnectionState.RTCPeerConnectionStateFailed) {
        _peerConnection?.close();
        _peerConnection = null;
      }
    };

    await _peerConnection!.setRemoteDescription(
      RTCSessionDescription(offer['sdp'], offer['type']),
    );

    final answer = await _peerConnection!.createAnswer();
    
    // Forzar bitrate de 5Mbps en el SDP de la respuesta.
    String sdp = answer.sdp!;
    sdp = sdp.replaceAll('b=AS:30', 'b=AS:5000'); // Reemplaza el bitrate por defecto.
    final highBitrateAnswer = RTCSessionDescription(sdp, answer.type);

    await _peerConnection!.setLocalDescription(highBitrateAnswer);

    ref.read(nodeDiscoveryProvider.notifier).sendDirectMessage(
      engineIp,
      jsonEncode({
        'type': 'answer',
        'sdp': highBitrateAnswer.sdp,
        'type': highBitrateAnswer.type,
      }),
    );
  }

  @override
  void dispose() {
    _broadcastTimer?.cancel();
    _localStream?.getTracks().forEach((track) => track.stop());
    _localRenderer.dispose();
    _peerConnection?.dispose();
    // No detenemos el discovery service aquí, ya que es un provider global.
    // Riverpod se encargará de su ciclo de vida.
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: RTCVideoView(_localRenderer, objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover),
            ),
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.black,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "NODE: CAMERA",
                    style: TextStyle(color: Colors.cyan, fontFamily: 'Courier'),
                  ),
                  Text(
                    _status.toUpperCase(),
                    style: const TextStyle(color: Colors.white, fontFamily: 'Courier'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
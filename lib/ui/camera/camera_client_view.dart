import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:ar_control_live_studio/core/app_session.dart';
import 'package:ar_control_live_studio/ui/master_scaffold.dart';
import 'package:ar_control_live_studio/core/theme/cyberpunk_theme.dart';

class CameraClientView extends ConsumerStatefulWidget {
  const CameraClientView({super.key}); 

  @override
  ConsumerState<CameraClientView> createState() => _CameraClientViewState();
}

class _CameraClientViewState extends ConsumerState<CameraClientView> {
  String? _shareType;
  String? _lensType;
  bool _isProgram = false; // Reemplaza a _connectedToEngine para el Tally
  bool _ndiRunning = false;
  bool _srtRunning = false;
  bool _rtspRunning = false;
  HttpServer? _signalingServer;
  RTCPeerConnection? _peerConnection;
  MediaStream? _localStream;
  Timer? _statsTimer;
  double _audioLevel = 0.0;
  final RTCVideoRenderer _localRenderer = RTCVideoRenderer();

  @override
  void initState() {
    super.initState();
    _localRenderer.initialize();
  }

  @override
  void dispose() {
    _signalingServer?.close();
    _peerConnection?.close();
    _localStream?.getTracks().forEach((track) => track.stop());
    _localStream?.dispose();
    _statsTimer?.cancel();
    _localRenderer.dispose();
    super.dispose();
  }

  Future<void> _startSignalingServer() async {
    _signalingServer = await HttpServer.bind(InternetAddress.anyIPv4, 8080);
    debugPrint('>>> Servidor de señalización WebRTC escuchando en el puerto 8080');

    await for (HttpRequest request in _signalingServer!) {
      if (request.method == 'POST' && request.uri.path == '/offer') {
        final content = await utf8.decodeStream(request);
        final offer = jsonDecode(content);
        await _handleOffer(RTCSessionDescription(offer['sdp'], offer['type']), request.response);
      } else if (request.method == 'POST' && request.uri.path == '/tally') {
        final content = await utf8.decodeStream(request);
        final data = jsonDecode(content);
        if (mounted) {
          setState(() {
            _isProgram = data['isProgram'] ?? false;
          });
        }
        request.response.statusCode = HttpStatus.ok;
        await request.response.close();
      } else if (request.method == 'POST' && request.uri.path == '/ptz') {
        final content = await utf8.decodeStream(request);
        final data = jsonDecode(content);
        // En una implementación real, esto se traduciría a comandos VISCA/Pelco-D
        debugPrint(">>> PTZ Command Received: Pan=${data['pan']}, Tilt=${data['tilt']}, Zoom=${data['zoom']}");
        request.response.statusCode = HttpStatus.ok;
        await request.response.close();
      } else if (request.method == 'POST' && request.uri.path == '/ptz_goto') {
        final content = await utf8.decodeStream(request);
        final data = jsonDecode(content);
        debugPrint(">>> PTZ GoTo Command Received: Pan=${data['pan']}, Tilt=${data['tilt']}, Zoom=${data['zoom']}");
        request.response.statusCode = HttpStatus.ok;
        await request.response.close();
      } else {
        request.response.statusCode = HttpStatus.methodNotAllowed;
        request.response.write('Unsupported method: ${request.method}');
        await request.response.close();
      }
    }
  }

  Future<void> _handleOffer(RTCSessionDescription remoteOffer, HttpResponse response) async {
    _peerConnection = await createPeerConnection({
      'iceServers': [ {'urls': 'stun:stun.l.google.com:19302'} ]
    });

    _statsTimer?.cancel();
    _statsTimer = Timer.periodic(const Duration(milliseconds: 200), (timer) async {
      if (!mounted || _peerConnection == null || _localStream == null) {
        timer.cancel();
        return;
      }

      final audioTracks = _localStream!.getAudioTracks();
      if (audioTracks.isEmpty) return;
      final audioTrack = audioTracks.first;

      RTCRtpSender? audioSender;
      final senders = await _peerConnection!.getSenders();
      for (final s in senders) {
        if (s.track?.id == audioTrack.id) {
          audioSender = s;
          break;
        }
      }

      if (audioSender != null) {
        final stats = await audioSender.getStats();
        for (final report in stats) {
          if (report.type == 'media-source' && report.values['kind'] == 'audio') {
            if (mounted) setState(() => _audioLevel = (report.values['audioLevel'] as double?) ?? 0.0);
            break;
          }
        }
      }
    });

    // Usa el stream local ya existente
    if (_localStream != null) {
      _localStream!
          .getTracks()
          .forEach((track) => _peerConnection!.addTrack(track, _localStream!));
    }

    await _peerConnection!.setRemoteDescription(remoteOffer);
    final answer = await _peerConnection!.createAnswer();
    await _peerConnection!.setLocalDescription(answer);

    response.headers.contentType = ContentType.json;
    response.write(jsonEncode(answer.toMap()));
    await response.close();
    debugPrint('>>> Oferta WebRTC manejada, respuesta enviada.');
  }

  Future<void> _initializeLocalStream() async {
    _localStream = await navigator.mediaDevices.getUserMedia({
      'audio': true,
      'video': {'facingMode': _lensType == 'Frontal' ? 'user' : 'environment'}
    });
    setState(() {
      _localRenderer.srcObject = _localStream;
    });
  }

  void _startEngines() {
    setState(() {
      _ndiRunning = true;
      _srtRunning = true;
      _rtspRunning = true;
    });
    _initializeLocalStream().then((_) => _startSignalingServer());
  }

  Widget _buildStatusChip(String label, bool active) {
    final color = active ? CyberpunkTheme.cyanNeon : CyberpunkTheme.panel;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        border: Border.all(color: color),
        color: color.withOpacity(0.2),
      ),
      child: Text(label, style: CyberpunkTheme.terminalStyle.copyWith(color: active ? CyberpunkTheme.cyanNeon : CyberpunkTheme.textMain)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sessionNotifier = ref.read(appSessionProvider.notifier);

    if (_shareType == null) {
      return MasterScaffold(
        child: Padding( 
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('>> CONFIG_NODE // SHARING_PROTOCOL', style: CyberpunkTheme.terminalStyle.copyWith(fontSize: 16, color: CyberpunkTheme.magentaNeon)),
              const Divider(color: CyberpunkTheme.magentaNeon),
              const SizedBox(height: 24),
              _selectionButton('A / CÁMARA LENTE', () {
                sessionNotifier.setShareType('Cámara');
                setState(() => _shareType = 'Cámara');
              }),
              _selectionButton('B / PANTALLA (SCREEN CAST)', () {
                sessionNotifier.setShareType('Pantalla');
                setState(() {
                  _shareType = 'Pantalla';
                });
                _startEngines();
              }),
            ],
          ),
      );
    }

    if (_shareType == 'Cámara' && _lensType == null) {
      return MasterScaffold(
        child: Padding( 
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('>> CONFIG_NODE // HARDWARE_LENS', style: CyberpunkTheme.terminalStyle.copyWith(fontSize: 16, color: CyberpunkTheme.magentaNeon)),
              const Divider(color: CyberpunkTheme.magentaNeon),
              const SizedBox(height: 24),
              _selectionButton('1 / LENTE FRONTAL', () {
                sessionNotifier.setLensType('Frontal');
                setState(() => _lensType = 'Frontal');
                _startEngines();
              }),
              _selectionButton('2 / LENTE TRASERA', () {
                sessionNotifier.setLensType('Trasera');
                setState(() => _lensType = 'Trasera');
                _startEngines();
              }),
              _selectionButton('3 / DUAL CAMERA (MULTI-CAM)', () {
                sessionNotifier.setLensType('Dual Camera');
                setState(() => _lensType = 'Dual Camera');
                _startEngines();
              }),
            ],
          ),
      );
    }

    // VISTA PRINCIPAL DEL CAMERA CLIENT (Glass UI)
    return MasterScaffold(
      child: Stack(
        children: [
          // 1. CAPA BASE DE VIDEO (Immutable RenderLayer)
          RepaintBoundary(
            child: _localRenderer.textureId != null
                ? RTCVideoView(_localRenderer,
                    mirror: _lensType == 'Frontal', // Espejar la cámara frontal
                    objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover)
                : Container(color: Colors.black),
          ),

          // 2. CAPA SUPERIOR: HUD (Transparente)
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Tally Bar / Header Info
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      border: Border(left: BorderSide(color: _isProgram ? CyberpunkTheme.errorRed : CyberpunkTheme.panel, width: 4)),
                      color: CyberpunkTheme.background.withOpacity(0.6),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('SRC: ${_shareType?.toUpperCase()} [${_lensType?.toUpperCase()}]', style: CyberpunkTheme.terminalStyle),
                        _buildStatusChip('TALLY', _isProgram), 
                      ],
                    ),
                  ),
                  const Spacer(),
                  
                  // Controles Inferiores (Node Links)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(border: Border.all(color: CyberpunkTheme.cyanNeon.withOpacity(0.5)), color: CyberpunkTheme.background.withOpacity(0.7)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [ 
                        Text('ENGINE PROTOCOLS:', style: CyberpunkTheme.terminalStyle.copyWith(color: CyberpunkTheme.magentaNeon)),
                        const SizedBox(height: 12),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Expanded(
                              child: Wrap(spacing: 8, runSpacing: 8, children: [
                                _buildStatusChip('NDI', _ndiRunning),
                                _buildStatusChip('SRT', _srtRunning),
                                _buildStatusChip('RTSP', _rtspRunning),
                              ]),
                            ),
                            const SizedBox(width: 16),
                            // _AudioLevelMeter(level: _audioLevel), // Widget duplicado y con errores, eliminado temporalmente
                          ],
                        ),
                        const SizedBox(height: 16),
                        _selectionButton('LINK_TO_ENGINE', () {
                          // La luz de Tally ahora es automática. Este botón podría usarse para otras funciones.
                          debugPrint("Link to engine action triggered.");
                        }, color: _isProgram ? CyberpunkTheme.errorRed : CyberpunkTheme.cyanNeon),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _selectionButton(String label, VoidCallback onTap, {Color? color}) {
    final neon = color ?? CyberpunkTheme.cyanNeon;
    return Padding( 
      padding: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          decoration: BoxDecoration(border: Border.all(color: neon), color: neon.withOpacity(0.1)),
          child: Text(label, style: CyberpunkTheme.terminalStyle.copyWith(color: neon, shadows: [Shadow(color: neon, blurRadius: 4)])),
        ),
      ),
    );
  }

  Widget _smallPanel(String label, String value, Color color) {
    return Expanded( 
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: color.withOpacity(0.2), borderRadius: BorderRadius.circular(12), border: Border.all(color: color)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(color: Colors.white70)),
            const SizedBox(height: 8),
            Text(value, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
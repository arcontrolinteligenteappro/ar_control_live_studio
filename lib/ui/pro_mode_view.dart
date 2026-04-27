import 'package:ar_control_live_studio/core/replay_engine.dart';
import 'package:ar_control_live_studio/ui/audio_mixer.dart';
import 'package:ar_control_live_studio/ui/shared/widgets/macro_panel.dart';
import 'dart:async';
import 'dart:math' as math;
import 'package:ar_control_live_studio/ui/shared/widgets/status_view.dart';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ar_control_live_studio/core/switcher_engine.dart';
import 'package:ar_control_live_studio/core/theme/cyberpunk_theme.dart';
import 'package:ar_control_live_studio/ui/master_scaffold.dart';
import 'package:ar_control_live_studio/ui/control_button.dart';
import 'package:ar_control_live_studio/core/rtmp_stream_engine.dart';
import 'package:ar_control_live_studio/core/ptz_engine.dart';
// import 'stream_engine_workspace.dart'; // Archivo no proporcionado, comentado
import 'package:ar_control_live_studio/core/hal.dart';

class ProModeView extends ConsumerStatefulWidget {
  final List<CameraDescription> cameras;
  const ProModeView({super.key, required this.cameras});

  @override
  ConsumerState<ProModeView> createState() => _ProModeViewState();
}

class _ProModeViewState extends ConsumerState<ProModeView> {
  // Opciones de calidad de grabación
  final Map<String, int> _qualityOptions = {
    'Baja (1Mbps)': 1000000,
    'Media (2Mbps)': 2000000,
    'Alta (5Mbps)': 5000000,
  };
  late int _selectedBitrate;

  // Estado para el indicador de almacenamiento
  Timer? _recordTimer;
  Duration _recordingDuration = Duration.zero;
  static const double _totalStorageGB = 64.0; // Simulación de almacenamiento total del dispositivo

  @override
  void initState() { 
    super.initState();
    // Después del primer frame, inicializa y añade todas las fuentes de hardware disponibles.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Tarea 1: Corregir Acceso Ilegal a Riverpod
      final sources = ref.read(switcherEngineProvider).sources; 
      final switcher = ref.read(switcherEngineProvider.notifier);
      if (sources.isEmpty) {
        // 1. Añade todas las cámaras físicas encontradas en el dispositivo.
        for (var i = 0; i < widget.cameras.length; i++) {
          final camera = widget.cameras[i];
          final cameraHAL = CameraHAL(id: 'cam$i', label: 'Local Cam ${camera.lensDirection.name}', cameraDescription: camera);
          switcher.addSource(cameraHAL);
          cameraHAL.initialize(); // Esto es asíncrono, pero no necesitamos esperarlo.
        }

        // 2. Añade el motor de repetición como una fuente.
        final replayEngine = ReplayEngine(); // Obtiene la instancia singleton
        final replaySource = ReplaySourceHAL(replayEngine);
        switcher.addSource(replaySource);
        replaySource.initialize();

        // Seleccionar una fuente para preview inicialmente (ej. la primera cámara local)
        if (widget.cameras.isNotEmpty) {
          switcher.selectForPreview('cam0');
        }
      }
    });

    _selectedBitrate = _qualityOptions.values.elementAt(1); // Default a Media
  }

  @override
  void dispose() {
    _recordTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final switcherState = ref.watch(switcherEngineProvider);
    final switcherNotifier = ref.read(switcherEngineProvider.notifier);

    return MasterScaffold(
      child: Column(
        children: [
          Expanded(
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Paneles de Video
                  Expanded(
                    flex: 3,
                    child: Column(
                      children: [
                        Expanded(child: _VideoRenderLayer(sourceId: switcherState.previewSourceId, label: 'PREVIEW', borderColor: CyberpunkTheme.magentaNeon)), 
                        Expanded(child: _VideoRenderLayer(sourceId: switcherState.programSourceId, label: 'PROGRAM', borderColor: CyberpunkTheme.cyanNeon)), 
                      ],
                    ),
                  ),
                  // Panel de Estado del Sistema
                  Expanded(
                    flex: 1,
                    child: Column(
                      children: [
                        StatusView(status: "SYSTEM OK", isWarning: false),
                        const SizedBox(height: 8),
                        if (switcherState.isRecording)
                          _StorageIndicator(
                            recordingDuration: _recordingDuration,
                            bitrate: _selectedBitrate,
                            totalStorageGB: _totalStorageGB,
                          ),
                        const Spacer(),
                        const _PtzControlPanel(),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Panel de Streaming RTMP
          const SizedBox(
            height: 120,
            child: _RtmpControlPanel(),
          ),
          // Panel de Macros
          const SizedBox(
            height: 180,
            child: MacroPanel(),
          ),
          // Panel del Mezclador de Audio
          const SizedBox(
            height: 250,
            child: AudioMixer(),
          ),
          // Controles CUT/AUTO
          Container(
            padding: const EdgeInsets.all(16),
            color: CyberpunkTheme.panel, 
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                ControlButton(
                  label: 'CUT',
                  color: CyberpunkTheme.cyanNeon,
                  onTap: switcherNotifier.executeCut,
                ),
                ControlButton(
                  label: 'AUTO',
                  color: switcherState.inTransition ? CyberpunkTheme.errorRed : CyberpunkTheme.cyanNeon,
                  onTap: () => switcherNotifier.executeAuto(const Duration(seconds: 1)),
                ),
                Row(
                  children: [
                    DropdownButton<int>(
                      value: _selectedBitrate,
                      dropdownColor: CyberpunkTheme.panel,
                      style: CyberpunkTheme.terminalStyle.copyWith(fontSize: 12),
                      underline: Container(height: 1, color: CyberpunkTheme.neonPurple),
                      icon: Icon(Icons.arrow_drop_down, color: switcherState.isRecording ? Colors.grey : CyberpunkTheme.neonPurple),
                      items: _qualityOptions.entries.map((entry) {
                        return DropdownMenuItem<int>(
                          value: entry.value,
                          child: Text(entry.key),
                        );
                      }).toList(),
                      onChanged: switcherState.isRecording ? null : (value) {
                        if (value != null) setState(() => _selectedBitrate = value);
                      },
                    ),
                    const SizedBox(width: 12),
                    ControlButton(
                      label: switcherState.isRecording ? 'STOP REC' : 'REC',
                      color: switcherState.isRecording ? CyberpunkTheme.errorRed : CyberpunkTheme.cyanNeon,
                      onTap: () {
                        if (switcherState.isRecording) {
                          _recordTimer?.cancel();
                          switcherNotifier.stopRecording('program_recording.mp4').then((path) {
                            if (mounted) {
                              if (path != null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Grabación guardada en $path')),
                                );
                              }
                              setState(() => _recordingDuration = Duration.zero);
                            }
                          });
                        } else {
                          setState(() => _recordingDuration = Duration.zero);
                          _recordTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
                            if (mounted) {
                              setState(() {
                                _recordingDuration = Duration(seconds: _recordingDuration.inSeconds + 1);
                              });
                            } else {
                              timer.cancel();
                            }
                          });
                          switcherNotifier.startRecording(bitrate: _selectedBitrate);
                        }
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RtmpControlPanel extends ConsumerStatefulWidget {
  const _RtmpControlPanel();

  @override
  ConsumerState<_RtmpControlPanel> createState() => _RtmpControlPanelState();
}

class _RtmpControlPanelState extends ConsumerState<_RtmpControlPanel> {
  late final TextEditingController _urlController;

  @override
  void initState() {
    super.initState();
    _urlController = TextEditingController(text: 'rtmp://a.rtmp.youtube.com/live2/your-stream-key');
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final rtmpState = ref.watch(rtmpStreamEngineProvider);
    final rtmpNotifier = ref.read(rtmpStreamEngineProvider.notifier);
    final isStreaming = rtmpState.connectionState == RtmpConnectionState.live || rtmpState.connectionState == RtmpConnectionState.connecting;
    final isDisconnected = rtmpState.connectionState == RtmpConnectionState.disconnected;

    String statusText;
    Color statusColor;

    switch (rtmpState.connectionState) {
      case RtmpConnectionState.live:
        statusText = 'LIVE: ${rtmpState.duration.toString().split('.').first.padLeft(8, "0")}';
        statusColor = CyberpunkTheme.errorRed;
        break;
      case RtmpConnectionState.connecting:
        statusText = 'CONNECTING...';
        statusColor = Colors.yellowAccent;
        break;
      case RtmpConnectionState.failed:
        statusText = 'FAILED: ${rtmpState.errorMessage ?? 'Unknown Error'}';
        statusColor = CyberpunkTheme.errorRed;
        break;
      default:
        statusText = 'STREAM OFFLINE';
        statusColor = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: CyberpunkTheme.panel.withOpacity(0.8),
        border: Border.all(color: CyberpunkTheme.neonPurple, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('>> RTMP_STREAM_ENGINE', style: CyberpunkTheme.terminalStyle.copyWith(color: CyberpunkTheme.magentaNeon)),
          const Divider(color: CyberpunkTheme.neonPurple),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: TextField(
                    controller: _urlController,
                    readOnly: !isDisconnected,
                    style: CyberpunkTheme.terminalStyle.copyWith(fontSize: 12, color: isDisconnected ? Colors.white : Colors.grey),
                    decoration: const InputDecoration(
                      labelText: 'RTMP URL',
                      labelStyle: TextStyle(color: CyberpunkTheme.neonCyan),
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(statusText, style: CyberpunkTheme.terminalStyle.copyWith(color: statusColor, fontSize: 12), textAlign: TextAlign.center),
                      if (rtmpState.connectionState == RtmpConnectionState.live)
                        Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Text('${rtmpState.currentBitrate} kbps | ${rtmpState.currentFps.toStringAsFixed(1)} FPS', style: CyberpunkTheme.terminalStyle.copyWith(color: Colors.white70, fontSize: 10)),
                        ),
                      const SizedBox(height: 8),
                      ControlButton(
                        label: isStreaming ? 'STOP STREAM' : 'START STREAM',
                        color: isStreaming ? CyberpunkTheme.errorRed : CyberpunkTheme.cyanNeon,
                        onTap: () {
                          if (isStreaming) {
                            rtmpNotifier.stopStream();
                          } else {
                            rtmpNotifier.startStream(_urlController.text);
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PtzControlPanel extends ConsumerStatefulWidget {
  const _PtzControlPanel();

  @override
  ConsumerState<_PtzControlPanel> createState() => _PtzControlPanelState();
}

class _PtzControlPanelState extends ConsumerState<_PtzControlPanel> {
  double _zoomSpeed = 0.0;

  void _handleZoomEnd(RemoteVideoSourceHAL source) {
    setState(() => _zoomSpeed = 0.0);
    source.controlPTZ(zoom: 0);
  }

  @override
  Widget build(BuildContext context) {
    final previewSourceId = ref.watch(switcherEngineProvider.select((s) => s.previewSourceId));
    final source = ref.watch(switcherEngineProvider.select((s) => s.sources[previewSourceId]));

    final RemoteVideoSourceHAL? ptzSource = (source is RemoteVideoSourceHAL && source.supportsPTZ) ? source : null;
    final bool isPtzSupported = ptzSource != null;

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        border: Border.all(color: isPtzSupported ? CyberpunkTheme.neonCyan.withOpacity(0.5) : Colors.grey.withOpacity(0.3)),
        color: CyberpunkTheme.panel.withOpacity(0.5),
      ),
      child: Column(
        children: [
          Text('PTZ CONTROL (PREVIEW)', style: CyberpunkTheme.terminalStyle.copyWith(fontSize: 10, color: isPtzSupported ? CyberpunkTheme.neonCyan : Colors.grey)),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              GestureDetector(
                onPanUpdate: isPtzSupported ? (details) {
                  ptzSource.controlPTZ(
                    pan: (details.delta.dx / 10).clamp(-1.0, 1.0),
                    tilt: -(details.delta.dy / 10).clamp(-1.0, 1.0),
                  );
                } : null,
                onPanEnd: isPtzSupported ? (details) {
                  ptzSource.controlPTZ(pan: 0, tilt: 0);
                } : null,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: isPtzSupported ? CyberpunkTheme.neonCyan : Colors.grey, width: 2),
                  ),
                  child: Icon(Icons.control_camera, color: isPtzSupported ? CyberpunkTheme.neonCyan : Colors.grey),
                ),
              ),
              const SizedBox(width: 16),
              SizedBox(
                height: 100,
                child: RotatedBox(
                  quarterTurns: -1,
                  child: SliderTheme(
                    data: SliderTheme.of(context).copyWith(trackHeight: 2.0, thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8.0), overlayShape: const RoundSliderOverlayShape(overlayRadius: 16.0), activeTrackColor: CyberpunkTheme.neonCyan, inactiveTrackColor: CyberpunkTheme.darkGrey, thumbColor: CyberpunkTheme.neonPurple),
                    child: Slider(
                      value: _zoomSpeed,
                      min: -1.0,
                      max: 1.0,
                      onChanged: isPtzSupported ? (value) {
                        setState(() => _zoomSpeed = value);
                        ptzSource.controlPTZ(zoom: value);
                      } : null,
                      onChangeEnd: isPtzSupported ? (value) => _handleZoomEnd(ptzSource) : null,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// Widget de placeholder para el renderizado de video
class _VideoRenderLayer extends ConsumerWidget {
  final String? sourceId;
  final String label;
  final Color borderColor;

  _VideoRenderLayer({this.sourceId, required this.label, required this.borderColor}); 

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final source = ref.watch(switcherEngineProvider.select((s) => s.sources[sourceId]));

    Widget videoContent;

    if (source == null) {
      videoContent = Center(
        child: Text("NONE", style: TextStyle(color: borderColor, fontWeight: FontWeight.bold)),
      );
    } else if (source is CameraHAL) {
      videoContent = ValueListenableBuilder<int?>(
        valueListenable: source.textureIdNotifier,
        builder: (context, textureId, child) {
          if (textureId == null || !source.isInitialized.value || source.controller == null) {
            return const Center(child: Text("INITIALIZING CAMERA...", style: TextStyle(color: Colors.white70)));
          }
          return SizedBox.expand(
            child: FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: source.controller!.value.previewSize!.height,
                height: source.controller!.value.previewSize!.width,
                child: Texture(textureId: textureId),
              ),
            ),
          );
        },
      );
    } else if (source is ReplaySourceHAL) {
      videoContent = ValueListenableBuilder<int?>(
        valueListenable: source.textureIdNotifier,
        builder: (context, textureId, child) {
          return Stack(
            fit: StackFit.expand,
            alignment: Alignment.center,
            children: [
              if (textureId != null)
                Center(
                  child: AspectRatio(
                    aspectRatio: 16 / 9,
                    child: Texture(textureId: textureId),
                  ),
                )
              else
                const Center(child: Text("REPLAY IDLE", style: TextStyle(color: Colors.white70))),
              // Controles restringidos a PREVIEW para evitar cortes accidentales en PROGRAM
              if (label == 'PREVIEW')
                Positioned(
                  bottom: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ValueListenableBuilder<bool>(
                          valueListenable: source.isPlaying,
                          builder: (context, isPlaying, child) {
                            return ControlButton(
                              label: isPlaying ? 'STOP REPLAY' : 'PLAY REPLAY',
                              color: isPlaying ? CyberpunkTheme.errorRed : CyberpunkTheme.cyanNeon,
                              onTap: () {
                                if (isPlaying) {
                                  source.stopPlayback();
                                } else {
                                  source.startPlayback();
                                }
                              },
                            );
                          },
                        ),
                        const SizedBox(width: 8),
                        ControlButton(
                          label: 'SAVE REPLAY',
                          color: CyberpunkTheme.cyanNeon,
                          onTap: () {
                            source.saveReplay('instant_replay_${DateTime.now().millisecondsSinceEpoch}.mp4').then((path) {
                              if (path != null && context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Repetición guardada: $path')),
                                );
                              }
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          );
        },
      );
    } else if (source is RemoteVideoSourceHAL) {
      if (source.renderer.srcObject == null) {
        videoContent = const Center(child: Text("CONNECTING WEBRTC...", style: TextStyle(color: Colors.white70)));
      } else {
        videoContent = Stack(
          fit: StackFit.expand,
          children: [
            RTCVideoView(source.renderer, objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover),
            ValueListenableBuilder<RTCPeerConnectionState?>(
              valueListenable: source.connectionState,
              builder: (context, state, child) {
                if (state == RTCPeerConnectionState.RTCPeerConnectionStateFailed ||
                    state == RTCPeerConnectionState.RTCPeerConnectionStateDisconnected) {
                  return const _GlitchEffect();
                }
                return const SizedBox.shrink();
              },
            ),
          ],
        );
      }
    } else {
      videoContent = Center(
        child: Text("UNKNOWN SOURCE TYPE", style: TextStyle(color: borderColor, fontWeight: FontWeight.bold)),
      );
    }

    return Container(
      margin: const EdgeInsets.all(8),
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(border: Border.all(color: borderColor, width: 2)),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Container(color: Colors.black),
          videoContent,
          Positioned(
            left: 8,
            top: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              color: Colors.black.withOpacity(0.7),
              child: Text("$label: ${sourceId ?? 'NONE'}", style: TextStyle(color: borderColor, fontWeight: FontWeight.bold, fontSize: 12)),
            ),
          ),
        ],
      ),
    );
  }
}

class _GlitchEffect extends StatefulWidget {
  const _GlitchEffect();

  @override
  State<_GlitchEffect> createState() => _GlitchEffectState();
}

class _GlitchEffectState extends State<_GlitchEffect> {
  Timer? _timer;
  final _random = math.Random();

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 70), (timer) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _GlitchPainter(_random),
      child: const SizedBox.expand(),
    );
  }
}

class _GlitchPainter extends CustomPainter {
  final math.Random _random;
  _GlitchPainter(this._random);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    // Draw horizontal glitch lines
    for (int i = 0; i < 10; i++) {
      final y = _random.nextDouble() * size.height;
      final h = _random.nextDouble() * 20 + 2;
      final xOffset = _random.nextDouble() * 40 - 20;
      paint.color = [CyberpunkTheme.neonCyan, CyberpunkTheme.magentaNeon, Colors.white, Colors.black][_random.nextInt(4)]
          .withOpacity(0.5 + _random.nextDouble() * 0.5);

      canvas.drawRect(Rect.fromLTWH(xOffset, y, size.width, h), paint);
    }

    // Draw vertical color channel shifts
    final channel = _random.nextInt(3);
    final xOffset = _random.nextDouble() * 10 - 5;
    paint.color = [const Color(0x66FF0000), const Color(0x6600FF00), const Color(0x660000FF)][channel];
    paint.blendMode = BlendMode.plus;
    canvas.drawRect(Rect.fromLTWH(xOffset, 0, size.width, size.height), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _StorageIndicator extends StatelessWidget {
  final Duration recordingDuration;
  final int bitrate;
  final double totalStorageGB;

  const _StorageIndicator({
    required this.recordingDuration,
    required this.bitrate,
    required this.totalStorageGB,
  });

  @override
  Widget build(BuildContext context) {
    final bytesPerSecond = bitrate / 8;
    final usedBytes = bytesPerSecond * recordingDuration.inSeconds;
    final totalBytes = totalStorageGB * 1024 * 1024 * 1024;
    final remainingBytes = (totalBytes - usedBytes).clamp(0, totalBytes);
    final remainingGB = remainingBytes / (1024 * 1024 * 1024);
    final usedPercentage = (usedBytes / totalBytes).clamp(0.0, 1.0);

    String formatDuration(Duration d) => d.toString().split('.').first.padLeft(8, "0");

    return Container(
      padding: const EdgeInsets.all(8),
      margin: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        border: Border.all(color: CyberpunkTheme.neonPurple.withOpacity(0.5)),
        color: CyberpunkTheme.panel.withOpacity(0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('REC TIME: ${formatDuration(recordingDuration)}', style: CyberpunkTheme.terminalStyle.copyWith(fontSize: 12, color: CyberpunkTheme.errorRed)),
          const SizedBox(height: 8),
          Text('STORAGE REMAINING: ${remainingGB.toStringAsFixed(2)} GB', style: CyberpunkTheme.terminalStyle.copyWith(fontSize: 10, color: Colors.white70)),
          const SizedBox(height: 4),
          LinearProgressIndicator(
            value: 1.0 - usedPercentage,
            backgroundColor: CyberpunkTheme.errorRed.withOpacity(0.3),
            valueColor: AlwaysStoppedAnimation<Color>(
              usedPercentage > 0.9 ? CyberpunkTheme.errorRed : CyberpunkTheme.terminalGreen,
            ),
          ),
        ],
      ),
    );
  }
}
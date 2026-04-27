import 'dart:async';

import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:ar_control_live_studio/core/event_bus.dart'; // Import corregido
import 'package:ar_control_live_studio/modules/analytics_dashboard.dart';
import 'package:ar_control_live_studio/modules/audio_mixer_screen.dart';
import 'package:ar_control_live_studio/modules/cloud_sync_module.dart';
import 'package:ar_control_live_studio/modules/drone_control_screen.dart';
import 'package:ar_control_live_studio/modules/dj_control_screen.dart';
import 'package:ar_control_live_studio/modules/log_viewer_screen.dart';
import 'package:ar_control_live_studio/modules/ndi_control_screen.dart';
import 'package:ar_control_live_studio/modules/overlay_control_screen.dart';
import 'package:ar_control_live_studio/modules/hardware_engine.dart';
import 'package:ar_control_live_studio/modules/replay_engine.dart';
import 'package:ar_control_live_studio/modules/screen_recorder_engine.dart';
import 'package:ar_control_live_studio/modules/sports_control_screen.dart';
import 'package:ar_control_live_studio/modules/stream_module.dart';
import 'package:ar_control_live_studio/modules/system_logs.dart';
import 'package:ar_control_live_studio/modules/video_module.dart';
import 'package:ar_control_live_studio/services/service_locator.dart';

// --- Placeholder Classes to fix compilation ---
class ServiceLocator {
  static final StreamEngine streamEngine = StreamEngine();
  static final HardwareEngine hardwareEngine = HardwareEngine();
  static final VideoEngine videoEngine = VideoEngine();
  static final CloudSyncEngine cloudSyncEngine = CloudSyncEngine();
}
class StreamEngine {
  Stream<Map<String, dynamic>> get statusStream => Stream.value({'status': 'OFFLINE'});
  String get streamState => 'OFFLINE';
  bool get isStreaming => false;
  void toggleStream() {}
}
class HardwareEngine {
  bool get ptzConnected => false;
  bool get nativeBridgeAvailable => false;
  double get panPosition => 0;
  double get tiltPosition => 0;
  double get zoomLevel => 0;
  void scanControllers() {}
  void panPTZ(double pan) {}
  void tiltPTZ(double tilt) {}
  void zoomPTZ(double zoom) {}
  Future<void> refreshPTZStatus() async {}
}
class VideoEngine {
  String get activeSource => 'CAM1';
  List<String> get availableSources => ['CAM1', 'CAM2', 'REMOTE'];
  void switchSource(String source) {}
}
class ReplayEngineWidget extends StatelessWidget { const ReplayEngineWidget({super.key}); @override Widget build(BuildContext context) => const Scaffold(body: Center(child: Text("Replay Engine")));}
class ScreenRecorderScreen extends StatelessWidget { const ScreenRecorderScreen({super.key}); @override Widget build(BuildContext context) => const Scaffold(body: Center(child: Text("Screen Recorder")));}
class DJControlScreen extends StatelessWidget { const DJControlScreen({super.key}); @override Widget build(BuildContext context) => const Scaffold(body: Center(child: Text("DJ Control")));}

enum DashboardMode { single, studio, pro }

class MainDashboard extends StatefulWidget {
  const MainDashboard({super.key});

  @override
  State<MainDashboard> createState() => _MainDashboardState();
}

class _MainDashboardState extends State<MainDashboard> {
  CameraController? _controller;
  bool _isReady = false;
  bool _isPtzPanelExpanded = true;
  bool _loadingPeers = false;
  DashboardMode _mode = DashboardMode.studio;
  String _timeString = '';
  List<String> _cloudPeers = [];

  final StreamEngine _streamEngine = ServiceLocator.streamEngine;
  final HardwareEngine _hardwareEngine = ServiceLocator.hardwareEngine;
  final VideoEngine _videoEngine = ServiceLocator.videoEngine;
  final CloudSyncEngine _cloudSyncEngine = ServiceLocator.cloudSyncEngine;

  late final StreamSubscription<StreamStateChangedEvent> _streamStatusSubscription;
  late final StreamSubscription<PTZStatusChangedEvent> _ptzStatusSubscription;
  late final StreamSubscription<CameraSourceChangedEvent> _sourceSubscription;
  late final StreamSubscription<bool> _cloudSyncSubscription;
  Timer? _clockTimer;

  @override
  void initState() {
    super.initState();
    _timeString = _formatCurrentTime();
    _requestPermissions();
    _hardwareEngine.scanControllers();

    _streamStatusSubscription = AppEventBus.instance.on<StreamStateChangedEvent>().listen((_) {
      if (mounted) setState(() {});
    });

    _ptzStatusSubscription = AppEventBus.instance.on<PTZStatusChangedEvent>().listen((_) {
      if (mounted) setState(() {});
    });

    _sourceSubscription = AppEventBus.instance.on<CameraSourceChangedEvent>().listen((_) {
      if (mounted) setState(() {});
    });

    _cloudSyncSubscription = _cloudSyncEngine.syncStream.listen((_) {
      if (mounted) setState(() {});
    });

    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {
        _timeString = _formatCurrentTime();
      });
    });

    _refreshCloudPeers();
  }

  Future<void> _requestPermissions() async {
    final status = await Permission.camera.request();
    final micStatus = await Permission.microphone.request();
    if (status.isGranted && micStatus.isGranted) {
      _initCamera();
    }
  }

  Future<void> _initCamera() async {
    final cameras = await availableCameras();
    if (cameras.isEmpty) return;
    _controller = CameraController(cameras[0], ResolutionPreset.medium);
    await _controller!.initialize();
    if (mounted) setState(() => _isReady = true);
  }

  void _toggleLive() {
    setState(() {
      _streamEngine.toggleStream();
    });
  }

  void _switchSource(String source) {
    setState(() {
      _videoEngine.switchSource(source);
    });
  }

  void _adjustPTZ({double? pan, double? tilt, double? zoom}) {
    if (!_hardwareEngine.ptzConnected) return;
    if (pan != null) _hardwareEngine.panPTZ(pan);
    if (tilt != null) _hardwareEngine.tiltPTZ(tilt);
    if (zoom != null) _hardwareEngine.zoomPTZ(zoom);
    setState(() {});
  }

  void _toggleCloudSync() async {
    if (_cloudSyncEngine.isSyncActive) {
      await _cloudSyncEngine.stopSync();
    } else {
      await _cloudSyncEngine.startSync();
    }
    setState(() {});
  }

  void _toggleMode(DashboardMode mode) {
    setState(() {
      _mode = mode;
    });
  }

  void _togglePtzPanel() {
    setState(() {
      _isPtzPanelExpanded = !_isPtzPanelExpanded;
    });
  }

  Future<void> _refreshCloudPeers() async {
    setState(() {
      _loadingPeers = true;
    });
    final peers = await _cloudSyncEngine.discoverPeers();
    if (!mounted) return;
    setState(() {
      _cloudPeers = peers;
      _loadingPeers = false;
    });
  }

  String _formatCurrentTime() {
    final now = DateTime.now();
    return '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    _streamStatusSubscription.cancel();
    _ptzStatusSubscription.cancel();
    _sourceSubscription.cancel();
    _cloudSyncSubscription.cancel();
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sourceLabel = _videoEngine.activeSource;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('AR CONTROL LIVE - MASTER PANEL'),
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.cyanAccent),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshCloudPeers,
          ),
        ],
      ),
      drawer: _buildNavigationDrawer(),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeader(sourceLabel),
          Expanded(child: _buildVisualizerGrid()),
          _buildControlBar(),
          _buildPTZPanel(),
          _buildAnimatedFooter(),
        ],
      ),
    );
  }

  Widget _buildNavigationDrawer() {
    return Drawer(
      backgroundColor: Colors.black,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(color: Colors.black),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text('AR CONTROL MENU', style: TextStyle(color: Colors.cyanAccent, fontSize: 18, fontWeight: FontWeight.bold)),
                SizedBox(height: 6),
                Text('Seleccione módulo', style: TextStyle(color: Colors.white54, fontSize: 12)),
              ],
            ),
          ),
          _buildDrawerItem('Overlay Control', Icons.layers, () => _navigateTo(const OverlayControlScreen())),
          _buildDrawerItem('Sports Control', Icons.sports_soccer, () => _navigateTo(const SportsControlScreen())),
          _buildDrawerItem('Drone Control', Icons.flight, () => _navigateTo(const DroneControlScreen())),
          _buildDrawerItem('NDI Streaming', Icons.stream, () => _navigateTo(const NDIControlScreen())),
          _buildDrawerItem('Audio Mixer', Icons.audiotrack, () => _navigateTo(const AudioMixerScreen())),
          _buildDrawerItem('System Logs', Icons.terminal, () => _navigateTo(const SystemLogsScreen())),
          _buildDrawerItem('Analytics', Icons.analytics, () => _navigateTo(const AnalyticsDashboard())),
          _buildDrawerItem('Replay Library', Icons.history, () => _navigateTo(const ReplayEngineWidget())),
          _buildDrawerItem('Screen Capture', Icons.videocam, () => _navigateTo(const ScreenRecorderScreen())),
          _buildDrawerItem('DJ PRO', Icons.headphones, () => _navigateTo(const DJControlScreen())),
          _buildDrawerItem('Log Viewer', Icons.list_alt, () => _navigateTo(const LogViewerScreen())),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(String title, IconData icon, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: Colors.cyanAccent),
      title: Text(title, style: const TextStyle(color: Colors.white)),
      onTap: onTap,
    );
  }

  void _navigateTo(Widget screen) {
    Navigator.pop(context);
    Navigator.push(context, MaterialPageRoute(builder: (context) => screen));
  }

  Widget _buildHeader(String sourceLabel) {
    return Container(
      height: 100,
      color: Colors.black,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('AR CONTROL LIVE - MASTER PANEL', style: TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                  const SizedBox(height: 4),
                  Text('Fuente activa: $sourceLabel', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  StreamBuilder<Map<String, dynamic>>(
                    stream: _streamEngine.statusStream,
                    initialData: {'status': _streamEngine.streamState},
                    builder: (context, snapshot) {
                      final status = snapshot.data?['status'] ?? _streamEngine.streamState;
                      final color = status == 'LIVE' ? Colors.greenAccent : Colors.redAccent;
                      return Text('STREAM: $status', style: TextStyle(color: color, fontWeight: FontWeight.bold));
                    },
                  ),
                  const SizedBox(height: 4),
                  Text('PTZ: ${_hardwareEngine.ptzConnected ? 'CONNECTED' : 'DISCONNECTED'}', style: TextStyle(color: _hardwareEngine.ptzConnected ? Colors.greenAccent : Colors.white38, fontSize: 12)),
                  const SizedBox(height: 4),
                  Text('NATIVE BRIDGE: ${_hardwareEngine.nativeBridgeAvailable ? 'OK' : 'OFFLINE'}', style: TextStyle(color: _hardwareEngine.nativeBridgeAvailable ? Colors.lightGreenAccent : Colors.white38, fontSize: 12)),
                  const SizedBox(height: 4),
                  Text('SYNC: ${_cloudSyncEngine.isSyncActive ? 'ACTIVE' : 'IDLE'}', style: TextStyle(color: _cloudSyncEngine.isSyncActive ? Colors.blueAccent : Colors.white38, fontSize: 12)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          _buildModeSelector(),
        ],
      ),
    );
  }

  Widget _buildVisualizerGrid() {
    final tiles = _videoEngine.availableSources.map((source) {
      return _buildSelectableBox(source, source == 'CAM1' ? 'CAM 1 - LIVE' : source == 'CAM2' ? 'CAM 2 - NDI' : source, _sourcePreviewWidget(source));
    }).toList();

    if (_mode == DashboardMode.pro) {
      tiles.add(_buildSystemPanel());
    }

    final crossAxisCount = _mode == DashboardMode.single ? 1 : 2;

    return Padding(
      padding: const EdgeInsets.all(10),
      child: GridView.count(
        crossAxisCount: crossAxisCount,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: _mode == DashboardMode.single ? 2 : 1.1,
        children: tiles,
      ),
    );
  }

  Widget _sourcePreviewWidget(String source) {
    if (source == 'CAM1') {
      return _isReady ? CameraPreview(_controller!) : const Center(child: CircularProgressIndicator());
    }

    if (source == 'CAM2') {
      return const Center(child: Icon(Icons.lan, color: Colors.white10, size: 50));
    }

    if (source == 'REMOTE') {
      return const Center(child: Icon(Icons.cloud_off, color: Colors.white10, size: 50));
    }

    return const Center(child: Icon(Icons.layers, color: Colors.white10, size: 50));
  }

  Widget _buildSelectableBox(String source, String label, Widget child) {
    final isActive = _videoEngine.activeSource == source;
    return GestureDetector(
      onTap: () => _switchSource(source),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: isActive ? Colors.cyanAccent : Colors.white24, width: isActive ? 2 : 1),
          color: Colors.white10,
        ),
        child: Stack(
          children: [
            Positioned.fill(child: child),
            Container(
              color: Colors.black54,
              padding: const EdgeInsets.all(6),
              child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 10)),
            ),
            if (isActive)
              const Positioned(
                top: 6,
                right: 6,
                child: Icon(Icons.check_circle, color: Colors.cyanAccent, size: 18),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlBar() {
    final isStreaming = _streamEngine.isStreaming;
    return Container(
      height: 100,
      color: Colors.black,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('OP: ChrisRey91', style: TextStyle(color: Colors.white38)),
              const SizedBox(height: 6),
              Text('Modo ${_mode.name.toUpperCase()}', style: const TextStyle(color: Colors.white54, fontSize: 12)),
            ],
          ),
          ElevatedButton(
            onPressed: _toggleCloudSync,
            style: ElevatedButton.styleFrom(backgroundColor: _cloudSyncEngine.isSyncActive ? Colors.blue : Colors.grey),
            child: Text(_cloudSyncEngine.isSyncActive ? 'STOP SYNC' : 'START SYNC'),
          ),
          TextButton(
            onPressed: _refreshCloudPeers,
            style: TextButton.styleFrom(foregroundColor: Colors.white70),
            child: const Text('REFRESH PEERS'),
          ),
          ElevatedButton(
            onPressed: _toggleLive,
            style: ElevatedButton.styleFrom(backgroundColor: isStreaming ? Colors.green : Colors.red),
            child: Text(isStreaming ? 'STOP LIVE' : 'GO LIVE'),
          ),
        ],
      ),
    );
  }

  Widget _buildPTZPanel() {
    return AnimatedSize(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      child: Container(
        color: const Color(0xFF050505),
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('PTZ CONTROL', style: TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold)),
                IconButton(
                  icon: Icon(_isPtzPanelExpanded ? Icons.expand_less : Icons.expand_more, color: Colors.cyanAccent),
                  onPressed: _togglePtzPanel,
                ),
              ],
            ),
            if (_isPtzPanelExpanded) ...[
              const SizedBox(height: 10),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildPtzButton('PAN +', () => _adjustPTZ(pan: _hardwareEngine.panPosition + 15)),
                    const SizedBox(width: 8),
                    _buildPtzButton('PAN -', () => _adjustPTZ(pan: _hardwareEngine.panPosition - 15)),
                    const SizedBox(width: 8),
                    _buildPtzButton('TILT +', () => _adjustPTZ(tilt: _hardwareEngine.tiltPosition + 10)),
                    const SizedBox(width: 8),
                    _buildPtzButton('TILT -', () => _adjustPTZ(tilt: _hardwareEngine.tiltPosition - 10)),
                    const SizedBox(width: 8),
                    _buildPtzButton('ZOOM +', () => _adjustPTZ(zoom: _hardwareEngine.zoomLevel + 1)),
                    const SizedBox(width: 8),
                    _buildPtzButton('ZOOM -', () => _adjustPTZ(zoom: _hardwareEngine.zoomLevel - 1)),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _hardwareEngine.nativeBridgeAvailable ? () async {
                        await _hardwareEngine.refreshPTZStatus();
                        if (mounted) setState(() {});
                      } : null,
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.cyanAccent),
                      child: const Text('REFRESH PTZ', style: TextStyle(fontSize: 10, color: Colors.black)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text('PAN: ${_hardwareEngine.panPosition.toStringAsFixed(0)}°  TILT: ${_hardwareEngine.tiltPosition.toStringAsFixed(0)}°  ZOOM: ${_hardwareEngine.zoomLevel.toStringAsFixed(1)}x', style: const TextStyle(color: Colors.white54, fontSize: 12)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPtzButton(String label, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: _hardwareEngine.ptzConnected ? onPressed : null,
      style: ElevatedButton.styleFrom(backgroundColor: Colors.grey.shade900),
      child: Text(label, style: const TextStyle(fontSize: 10, color: Colors.white)),
    );
  }

  Widget _buildModeSelector() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: DashboardMode.values.map((mode) {
        final selected = _mode == mode;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: ChoiceChip(
            label: Text(mode.name.toUpperCase(), style: TextStyle(color: selected ? Colors.black : Colors.white)),
            selected: selected,
            selectedColor: Colors.cyanAccent,
            backgroundColor: Colors.white10,
            onSelected: (_) => _toggleMode(mode),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSystemPanel() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.white24),
        color: const Color(0xFF0A0A0A),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('SYSTEM STATUS', style: TextStyle(color: Colors.orangeAccent, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Text('Stream: ${_streamEngine.streamState}', style: const TextStyle(color: Colors.white70, fontSize: 12)),
          Text('Sync: ${_cloudSyncEngine.isSyncActive ? 'ACTIVE' : 'IDLE'}', style: const TextStyle(color: Colors.white70, fontSize: 12)),
          Text('PTZ: ${_hardwareEngine.ptzConnected ? 'CONNECTED' : 'DISCONNECTED'}', style: const TextStyle(color: Colors.white70, fontSize: 12)),
          const SizedBox(height: 10),
          Text('Source: ${_videoEngine.activeSource}', style: const TextStyle(color: Colors.white54, fontSize: 11)),
          const SizedBox(height: 10),
          const Text('PEERS', style: TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold, fontSize: 11)),
          if (_loadingPeers)
            const Padding(
              padding: EdgeInsets.only(top: 8.0),
              child: SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.cyanAccent)),
            )
          else if (_cloudPeers.isEmpty)
            const Text('No peers found', style: TextStyle(color: Colors.white38, fontSize: 11))
          else
            ..._cloudPeers.map((peer) => Text(peer, style: const TextStyle(color: Colors.white54, fontSize: 11))),
        ],
      ),
    );
  }

  Widget _buildAnimatedFooter() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 500),
      height: 40,
      color: Colors.black,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: Text(
              'STATUS: ${_streamEngine.streamState} | SYNC: ${_cloudSyncEngine.isSyncActive ? 'ACTIVE' : 'IDLE'} | $_timeString',
              key: ValueKey<String>(_timeString),
              style: const TextStyle(color: Colors.white54, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

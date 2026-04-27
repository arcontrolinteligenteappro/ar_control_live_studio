import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ar_control_live_studio/providers/app_session.dart';

class EngineStudioView extends ConsumerStatefulWidget {
  const EngineStudioView({super.key});

  @override
  ConsumerState<EngineStudioView> createState() => _EngineStudioViewState();
}

class _EngineStudioViewState extends ConsumerState<EngineStudioView> {
  bool _recActive = false;
  bool _streamActive = false;
  String? _stage;
  bool _completedQuestions = false;
  late String _selectedType;
  late String _selectedMode;
  final ValueNotifier<Duration> _recordDuration = ValueNotifier(Duration.zero);
  final ValueNotifier<Duration> _streamDuration = ValueNotifier(Duration.zero);

  Timer? _recTimer;
  Timer? _streamTimer;

  @override
  void initState() {
    super.initState();
    _stage = 'type';
    _selectedType = '';
    _selectedMode = '';
  }

  @override
  void dispose() {
    _recTimer?.cancel();
    _streamTimer?.cancel();
    _recordDuration.dispose();
    _streamDuration.dispose();
    super.dispose();
  }

  void _startRec() {
    setState(() {
      _recActive = true;
    });
    _recordDuration.value = Duration.zero;
    _recTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _recordDuration.value += const Duration(seconds: 1);
    });
  }

  void _stopRec() {
    _recTimer?.cancel();
    setState(() {
      _recActive = false;
    });
    _showReplayPreview('REC', _recordDuration.value);
  }

  void _startStream() {
    setState(() {
      _streamActive = true;
    });
    _streamDuration.value = Duration.zero;
    _streamTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _streamDuration.value += const Duration(seconds: 1);
    });
  }

  void _stopStream() {
    _streamTimer?.cancel();
    setState(() {
      _streamActive = false;
    });
    _showReplayPreview('STREAM', _streamDuration.value);
  }

  void _showReplayPreview(String type, Duration duration) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.black,
          title: Text('$type Preview', style: const TextStyle(color: Colors.cyanAccent)),
          content: Text('Duración: ${duration.inMinutes}m ${duration.inSeconds % 60}s', style: const TextStyle(color: Colors.white)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cerrar', style: TextStyle(color: Colors.cyanAccent)),
            ),
          ],
        );
      },
    );
  }

  Widget _buildQuestionCard({required String question, required List<String> options, required ValueChanged<String> onSelect}) {
    return Card(
      color: Colors.white10,
      margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(question, style: const TextStyle(color: Colors.cyanAccent, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 14),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: options.map((option) {
                return ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _selectedType == option || _selectedMode == option ? Colors.pinkAccent : Colors.grey[900],
                  ),
                  onPressed: () => onSelect(option),
                  child: Text(option, style: const TextStyle(color: Colors.white)),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(String label, Color color) {
    return Chip(label: Text(label, style: const TextStyle(color: Colors.white)), backgroundColor: color.withOpacity(0.9));
  }

  @override
  Widget build(BuildContext context) {
    final sessionState = ref.watch(appSessionProvider);
    final sessionNotifier = ref.read(appSessionProvider.notifier);

    if (!_completedQuestions) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildQuestionCard(
                question: '¿Qué tipo de transmisión vas a realizar?',
                options: ['Deportes', 'Compra/Venta', 'Podcast/Entrevista', 'General'],
                onSelect: (value) {
                  sessionNotifier.setTransmissionType(value);
                  _selectedType = value;
                  setState(() {
                    _stage = 'mode';
                  });
                },
              ),
              if (_stage == 'mode')
                _buildQuestionCard(
                  question: '¿Qué modo visual prefieres?',
                  options: ['Single Mode', 'Studio', 'Pro', 'OB Van'],
                  onSelect: (value) {
                    sessionNotifier.setVisualMode(value);
                    _selectedMode = value;
                    setState(() {
                      _completedQuestions = true;
                    });
                  },
                ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(color: Colors.black87, border: Border(bottom: BorderSide(color: Colors.cyanAccent.withOpacity(0.3)))),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('ENGINE Studio', style: TextStyle(color: Colors.cyanAccent, fontSize: 20, fontWeight: FontWeight.bold)),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('Tipo: ${sessionState.transmissionType ?? 'N/A'}', style: const TextStyle(color: Colors.white70)),
                      Text('Modo: ${sessionState.visualMode ?? 'N/A'}', style: const TextStyle(color: Colors.white70)),
                    ],
                  ),
                  StreamBuilder(
                    stream: Stream.periodic(const Duration(seconds: 1)),
                    builder: (context, _) {
                      final localTime = DateTime.now();
                      return Text('${localTime.hour.toString().padLeft(2, '0')}:${localTime.minute.toString().padLeft(2, '0')}', style: const TextStyle(color: Colors.white, fontSize: 16));
                    },
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildPrimaryPanel(),
                          const SizedBox(height: 16),
                          _buildSwitcherPanel(sessionState, sessionNotifier),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 2,
                      child: _buildSidePanels(),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrimaryPanel() {
    return Card(
      color: Colors.white10,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Control Principal', style: TextStyle(color: Colors.pinkAccent, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              children: [
                _buildStatusChip(_recActive ? 'REC ON' : 'REC OFF', _recActive ? Colors.red : Colors.grey),
                _buildStatusChip(_streamActive ? 'STREAM ON' : 'STREAM OFF', _streamActive ? Colors.green : Colors.grey),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: _recActive ? Colors.redAccent : Colors.cyanAccent),
                  onPressed: _recActive ? _stopRec : _startRec,
                  child: Text(_recActive ? 'Stop REC' : 'Start REC'),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: _streamActive ? Colors.redAccent : Colors.greenAccent),
                  onPressed: _streamActive ? _stopStream : _startStream,
                  child: Text(_streamActive ? 'Stop STREAM' : 'Start STREAM'),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Text('Estado actual', style: TextStyle(color: Colors.white70)),
            const SizedBox(height: 8),
            ValueListenableBuilder<Duration>(
              valueListenable: _recordDuration,
              builder: (context, duration, child) {
                return Text('Grabando: ${_recActive ? 'Sí' : 'No'} • ${duration.inMinutes}m ${duration.inSeconds % 60}s', 
                  style: const TextStyle(color: Colors.white));
              },
            ),
            ValueListenableBuilder<Duration>(
              valueListenable: _streamDuration,
              builder: (context, duration, child) {
                return Text('Transmitiendo: ${_streamActive ? 'Sí' : 'No'} • ${duration.inMinutes}m ${duration.inSeconds % 60}s', 
                  style: const TextStyle(color: Colors.white));
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSwitcherPanel(AppSessionState sessionState, AppSessionNotifier sessionNotifier) {
    final modes = ['Single Mode', 'Studio', 'Pro', 'OB Van'];
    return Card(
      color: Colors.white10,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Switcher Seamless', style: TextStyle(color: Colors.cyanAccent, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              children: modes.map((mode) {
                final active = sessionState.visualMode == mode;
                return OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: active ? Colors.pinkAccent : Colors.white24),
                  ),
                  onPressed: () => sessionNotifier.setVisualMode(mode),
                  child: Text(mode, style: TextStyle(color: active ? Colors.pinkAccent : Colors.white)),
                );
              }).toList(),
            ),
            const SizedBox(height: 14),
            const Text('Vista en vivo: Program', style: TextStyle(color: Colors.white70)),
          ],
        ),
      ),
    );
  }

  Widget _buildSidePanels() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildMiniPanel('Drones', Icons.flight, 'Control de Drones'),
        const SizedBox(height: 12),
        _buildMiniPanel('PTZ', Icons.videocam, 'Control PTZ avanzado'),
        const SizedBox(height: 12),
        _buildMiniPanel('Audio/DJ Mixer', Icons.music_note, 'Mezcla de audio y decks'),
        const SizedBox(height: 12),
        _buildMiniPanel('Chat Control', Icons.chat, 'Monitoreo Twitch/YouTube'),
      ],
    );
  }

  Widget _buildMiniPanel(String title, IconData icon, String subtitle) {
    return Card(
      color: Colors.white10,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Colors.cyanAccent),
                const SizedBox(width: 8),
                Expanded(child: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
              ],
            ),
            const SizedBox(height: 12),
            Text(subtitle, style: const TextStyle(color: Colors.white70)),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.pinkAccent),
                onPressed: () {},
                child: const Text('Abrir'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

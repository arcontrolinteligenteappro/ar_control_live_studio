import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

class ScreenRecorderScreen extends StatefulWidget {
  const ScreenRecorderScreen({super.key});
  @override
  State<ScreenRecorderScreen> createState() => _ScreenRecorderScreenState();
}

class _ScreenRecorderScreenState extends State<ScreenRecorderScreen> {
  // COMENTADO: La variable del paquete eliminado
  // EdScreenRecorder? screenRecorder; 
  
  bool _isRecording = false;
  int _elapsedSeconds = 0;
  Timer? _timer;
  String? _lastRecordingPath;

  @override
  void initState() {
    super.initState();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) setState(() => _elapsedSeconds++);
    });
  }

  void _stopTimer() {
    _timer?.cancel();
  }

  Future<File> _createMockRecordingFile(int seconds) async {
    final directory = await getApplicationDocumentsDirectory();
    final fileName = 'recording_${DateTime.now().millisecondsSinceEpoch}.mp4';
    final file = File('${directory.path}${Platform.pathSeparator}$fileName');
    await file.writeAsBytes(List<int>.generate(256, (index) => (index + seconds) % 256));
    return file;
  }

  Future<void> _toggleRecording() async {
    if (_isRecording) {
      _stopTimer();
      final file = await _createMockRecordingFile(_elapsedSeconds);
      if (!mounted) return;
      setState(() {
        _isRecording = false;
        _lastRecordingPath = file.path;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('CAPTURADO: ${file.path.split(Platform.pathSeparator).last}', style: const TextStyle(color: Colors.greenAccent, fontFamily: 'Courier New')),
          backgroundColor: const Color(0xFF101010),
        ),
      );
      return;
    }

    if (mounted) {
      setState(() {
        _isRecording = true;
        _elapsedSeconds = 0;
      });
      _startTimer();
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('GRABACIÓN INICIADA (Modo Simulación)', style: TextStyle(color: Colors.cyanAccent, fontFamily: 'Courier New')), 
          backgroundColor: Color(0xFF111111),
        ),
      );
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('SCREEN CAPTURE', style: TextStyle(fontFamily: 'Courier New', color: Colors.cyanAccent)), 
        backgroundColor: Colors.black, 
        iconTheme: const IconThemeData(color: Colors.cyanAccent)
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _isRecording ? Icons.fiber_manual_record : Icons.screen_share, 
              size: 100, 
              color: _isRecording ? Colors.red : Colors.cyanAccent
            ),
            const SizedBox(height: 30),
            Text(
              _isRecording ? 'GRABANDO: ${_elapsedSeconds}s' : 'STANDBY',
              style: TextStyle(
                color: _isRecording ? Colors.redAccent : Colors.cyanAccent, 
                fontFamily: 'Courier New', 
                fontSize: 24, 
                fontWeight: FontWeight.bold,
              ),
            ),
            if (_lastRecordingPath != null) ...[
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Text(
                  'Último archivo: ${_lastRecordingPath!.split(Platform.pathSeparator).last}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white54, fontSize: 12, fontFamily: 'Courier New'),
                ),
              ),
            ],
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: _toggleRecording,
              style: ElevatedButton.styleFrom(
                backgroundColor: _isRecording ? Colors.red[900] : Colors.cyan[900], 
                padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 20)
              ),
              child: Text(
                _isRecording ? 'DETENER' : 'INICIAR CAPTURA', 
                style: const TextStyle(color: Colors.white, fontFamily: 'Courier New', fontWeight: FontWeight.bold)
              ),
            ),
          ],
        ),
      ),
    );
  }
}
import 'package:flutter/material.dart';
import '../../core/recording_engine.dart';
import '../../core/theme/cyberpunk_theme.dart';

/// RecordControl: Control de grabación.
/// Botones para iniciar/detener grabación.
class RecordControl extends StatefulWidget {
  const RecordControl({super.key});

  @override
  _RecordControlState createState() => _RecordControlState();
}

class _RecordControlState extends State<RecordControl> {
  final RecordingEngine _engine = RecordingEngine();
  final TextEditingController _pathController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFFF0000).withOpacity(0.5)),
        color: CyberpunkTheme.panel,
      ),
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('>> RECORD_ENGINE', style: CyberpunkTheme.terminalStyle.copyWith(color: const Color(0xFFFF0000), fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(border: Border.all(color: CyberpunkTheme.textMain.withOpacity(0.3)), color: CyberpunkTheme.background),
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: TextField(
              controller: _pathController,
              decoration: InputDecoration(
                border: InputBorder.none,
                icon: Text('PATH:', style: CyberpunkTheme.terminalStyle.copyWith(color: CyberpunkTheme.textMain)),
              ),
              style: CyberpunkTheme.terminalStyle.copyWith(color: CyberpunkTheme.cyanNeon),
              cursorColor: CyberpunkTheme.magentaNeon,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _actionButton('>> START_REC', () => _engine.startRecording(_pathController.text), color: const Color(0xFFFF0000)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _actionButton('>> STOP', () => _engine.stopRecording(), color: CyberpunkTheme.textMain),
              ),
            ],
          ),
        ],
      ),
    );
  }


  Widget _actionButton(String label, VoidCallback onTap, {required Color color}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          border: Border.all(color: color),
          color: color.withOpacity(0.1),
        ),
        alignment: Alignment.center,
        child: Text(label, style: CyberpunkTheme.terminalStyle.copyWith(color: color, fontWeight: FontWeight.bold)),
      ),
    );
  }
}
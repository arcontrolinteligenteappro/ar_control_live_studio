import 'package:flutter/material.dart';
import '../../core/streaming_engine.dart';
import '../../core/theme/cyberpunk_theme.dart';

/// StreamControl: Control de streaming.
/// Botones para iniciar/detener streaming.
class StreamControl extends StatefulWidget {
  const StreamControl({super.key});

  @override
  _StreamControlState createState() => _StreamControlState();
}

class _StreamControlState extends State<StreamControl> {
  final StreamingEngine _engine = StreamingEngine();
  final TextEditingController _urlController = TextEditingController();
  final TextEditingController _keyController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: CyberpunkTheme.cyanNeon.withOpacity(0.5)),
        color: CyberpunkTheme.panel,
      ),
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('>> STREAM_ENGINE', style: CyberpunkTheme.terminalStyle.copyWith(color: CyberpunkTheme.cyanNeon, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          _buildTextField(_urlController, 'URL'),
          const SizedBox(height: 8),
          _buildTextField(_keyController, 'KEY'),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _actionButton('>> GO_LIVE', () => _engine.startStream(_urlController.text, _keyController.text), color: CyberpunkTheme.cyanNeon),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _actionButton('>> STOP', () => _engine.stopStream(), color: const Color(0xFFFF0000)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label) {
    return Container(
      decoration: BoxDecoration(border: Border.all(color: CyberpunkTheme.textMain.withOpacity(0.3)), color: CyberpunkTheme.background),
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          border: InputBorder.none,
          icon: Text('$label:', style: CyberpunkTheme.terminalStyle.copyWith(color: CyberpunkTheme.textMain)),
        ),
        style: CyberpunkTheme.terminalStyle.copyWith(color: CyberpunkTheme.cyanNeon),
        cursorColor: CyberpunkTheme.magentaNeon,
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
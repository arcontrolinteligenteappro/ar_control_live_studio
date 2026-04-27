import 'package:flutter/material.dart';
import '../../core/overlay_engine.dart';
import '../../core/theme/cyberpunk_theme.dart';

/// OverlayControl: Control de overlays.
/// Añadir/remover overlays de texto.
class OverlayControl extends StatefulWidget {
  const OverlayControl({super.key});

  @override
  _OverlayControlState createState() => _OverlayControlState();
}

class _OverlayControlState extends State<OverlayControl> {
  final OverlayEngine _engine = OverlayEngine();
  final TextEditingController _textController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: CyberpunkTheme.magentaNeon.withOpacity(0.5)),
        color: CyberpunkTheme.panel,
      ),
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('>> OVERLAY_CG_ENGINE', style: CyberpunkTheme.terminalStyle.copyWith(color: CyberpunkTheme.magentaNeon, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(border: Border.all(color: CyberpunkTheme.textMain.withOpacity(0.3)), color: CyberpunkTheme.background),
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: TextField(
              controller: _textController,
              decoration: InputDecoration(
                border: InputBorder.none,
                icon: Text('TEXT:', style: CyberpunkTheme.terminalStyle.copyWith(color: CyberpunkTheme.textMain)),
              ),
              style: CyberpunkTheme.terminalStyle.copyWith(color: CyberpunkTheme.cyanNeon),
              cursorColor: CyberpunkTheme.magentaNeon,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(child: _actionButton('>> PUSH_GFX', () {
                  _engine.addTextOverlay(_textController.text, const Offset(100, 100), const TextStyle(color: Colors.white, fontSize: 24));
                  setState(() {});
                }, color: CyberpunkTheme.magentaNeon)),
              const SizedBox(width: 12),
              Expanded(child: _actionButton('>> CLEAR', () {
                  _engine.clearOverlays();
                  setState(() {});
                }, color: CyberpunkTheme.textMain)),
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
        decoration: BoxDecoration(border: Border.all(color: color), color: color.withOpacity(0.1)),
        alignment: Alignment.center,
        child: Text(label, style: CyberpunkTheme.terminalStyle.copyWith(color: color, fontWeight: FontWeight.bold)),
      ),
    );
  }
}
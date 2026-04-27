import 'package:flutter/material.dart';
import '../../core/ai_engine.dart';
import '../../core/theme/cyberpunk_theme.dart';

/// AIControl: Control de IA.
/// Botones para análisis y sugerencias.
class AIControl extends StatelessWidget {
  const AIControl({super.key});

  @override
  Widget build(BuildContext context) {
    final AIEngine _ai = AIEngine();

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: CyberpunkTheme.cyanNeon.withOpacity(0.5)),
        color: CyberpunkTheme.panel,
      ),
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('>> AI_DIRECTOR_MODULE', style: CyberpunkTheme.terminalStyle.copyWith(color: CyberpunkTheme.cyanNeon, fontWeight: FontWeight.bold)),
          const Spacer(),
          _actionButton('>> AUTO_FRAMING', () => _ai.suggestFraming(), color: CyberpunkTheme.cyanNeon),
          const SizedBox(height: 12),
          _actionButton('>> SCENE_DETECT', () => _ai.detectSceneChange(null), color: CyberpunkTheme.magentaNeon),
          const Spacer(),
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
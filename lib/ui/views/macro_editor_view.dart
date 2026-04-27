import 'package:flutter/material.dart';
import 'package:ar_control_live_studio/core/theme/cyberpunk_theme.dart';

class MacroEditorView extends StatelessWidget {
  const MacroEditorView({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: CyberpunkTheme.glassPanel,
      child: const Center(
        child: Text(
          "MACRO EDITOR", 
          style: TextStyle(color: CyberpunkTheme.magentaNeon, fontWeight: FontWeight.bold)
        ),
      ),
    );
  }
}
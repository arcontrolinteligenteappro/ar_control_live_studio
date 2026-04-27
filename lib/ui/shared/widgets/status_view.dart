import 'package:flutter/material.dart';
import 'package:ar_control_live_studio/core/theme/cyberpunk_theme.dart';

class StatusView extends StatelessWidget {
  final String status;
  final bool isWarning;

  StatusView({super.key, required this.status, this.isWarning = false}); 

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: isWarning ? CyberpunkTheme.errorRed.withOpacity(0.2) : Colors.black,
        border: Border.all(color: isWarning ? CyberpunkTheme.errorRed : CyberpunkTheme.neonCyan),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: isWarning ? CyberpunkTheme.errorRed : CyberpunkTheme.neonCyan,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
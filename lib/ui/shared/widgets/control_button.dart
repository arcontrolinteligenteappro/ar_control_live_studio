import 'package:flutter/material.dart';
import 'package:ar_control_live_studio/core/theme/cyberpunk_theme.dart';

class ControlButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final bool isActive;

  ControlButton({ 
    super.key,
    required this.label,
    required this.onPressed,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? CyberpunkTheme.neonCyan.withOpacity(0.2) : Colors.transparent,
          border: Border.all(
            color: isActive ? CyberpunkTheme.neonCyan : CyberpunkTheme.neonPurple,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(2),
        ),
        child: Text(
          label.toUpperCase(),
          style: TextStyle(
            color: isActive ? Colors.white : CyberpunkTheme.neonCyan,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
      ),
    );
  }
}
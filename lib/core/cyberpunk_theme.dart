import 'package:flutter/material.dart';

class CyberpunkTheme {
  static const Color background = Color(0xFF0F0F1A);
  static const Color panel = Color(0xFF1A1A2A);
  static const Color textMain = Color(0xFFB0B0C0);

  static const Color cyanNeon = Color(0xFF00FFFF);
  static const Color magentaNeon = Color(0xFFFF00FF);

  static final TextStyle terminalStyle = TextStyle(
    fontFamily: 'monospace',
    color: textMain,
    fontSize: 14,
    shadows: [
      Shadow(color: cyanNeon.withOpacity(0.5), blurRadius: 2),
    ],
  );
}
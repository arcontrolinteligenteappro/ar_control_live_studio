import 'package:flutter/material.dart';

class CyberpunkTheme {
  static const Color background = Color(0xFF000000);
  static const Color panel = Color(0xFF111111);
  static const Color cyanNeon = Color(0xFF00FFFF);
  static const Color magentaNeon = Color(0xFFFF00FF);
  static const Color tallyRed = Color(0xFFFF4444);
  static const Color tallyGreen = Color(0xFF44FF44);
  static const Color tallyWarning = Color(0xFFFFFF00);
  static const Color foregroundColor = Color(0xFFE0E0E0);
  static const Color textMain = Color(0xFFE0E0E0);
  
  static const String fontFamily = 'Courier'; // Tipografía monoespaciada requerida

  static final TextStyle terminalStyle = const TextStyle(
    fontFamily: fontFamily,
    color: cyanNeon,
    fontSize: 12,
    letterSpacing: 1.2,
    shadows: [Shadow(color: cyanNeon, blurRadius: 4)],
  );
}
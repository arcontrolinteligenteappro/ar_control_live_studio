import 'package:flutter/material.dart';

class CyberpunkTheme {
  // --- Colores Base ---
  static const Color black = Color(0xFF000000);
  static const Color neonCyan = Color(0xFF00FFFF);
  static const Color neonPurple = Color(0xFFBC13FE);
  static const Color terminalGreen = Color(0xFF33FF33);
  static const Color errorRed = Color(0xFFFF3131);
  static const Color darkGrey = Color(0xFF121212);

  // --- ALIAS (Para matar los errores de las vistas generadas) ---
  static const Color cyanNeon = neonCyan;
  static const Color magentaNeon = neonPurple;
  static const Color panel = darkGrey;
  static const Color tallyRed = errorRed;
  static const Color tallyWarning = Colors.yellowAccent;
  static const Color background = black;
  static const Color textMain = neonCyan;
  static const String fontFamily = 'Courier';

  // --- Estilos Globales ---
  static ThemeData get theme => ThemeData.dark().copyWith(
    scaffoldBackgroundColor: background,
    primaryColor: neonCyan,
    colorScheme: const ColorScheme.dark(
      primary: neonCyan,
      secondary: neonPurple,
      surface: panel,
    ),
  );

  // Resuelve los errores "getter 'terminalStyle' isn't defined"
  static TextStyle get terminalStyle => const TextStyle(
    fontFamily: fontFamily,
    color: terminalGreen,
    fontWeight: FontWeight.bold,
  );

  static BoxDecoration glassPanel = BoxDecoration(
    color: Colors.black.withOpacity(0.8),
    border: Border.all(color: neonCyan.withOpacity(0.5), width: 1.5),
    borderRadius: BorderRadius.circular(4),
  );
}
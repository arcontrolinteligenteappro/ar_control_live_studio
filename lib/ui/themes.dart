import 'package:flutter/material.dart';

/// Themes: Sistema de diseño estricto Cyberpunk/Hacker HUD.
/// Fondos #000000, acentos Cyan Neón (#00FFFF) y Magenta (#FF00FF).
/// Fuentes monoespaciadas y bordes angulares.
class ARThemes {
  static const Color bgBlack = Color(0xFF000000);
  static const Color cyanNeon = Color(0xFF00FFFF);
  static const Color magentaNeon = Color(0xFFFF00FF);
  static const Color gridLines = Color(0xFF0A0A0A);

  static ThemeData cyberpunkTheme = ThemeData(
    brightness: Brightness.dark,
    primaryColor: cyanNeon,
    scaffoldBackgroundColor: bgBlack,
    fontFamily: 'Courier', // Forzamos fuente monoespaciada tipo terminal
    appBarTheme: const AppBarTheme(
      backgroundColor: bgBlack,
      elevation: 0,
      iconTheme: IconThemeData(color: cyanNeon),
      titleTextStyle: TextStyle(color: cyanNeon, fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 2.0),
    ),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: cyanNeon, fontSize: 16),
      bodyMedium: TextStyle(color: cyanNeon, fontSize: 14),
      headlineLarge: TextStyle(color: magentaNeon, fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 1.5),
    ),
    buttonTheme: const ButtonThemeData(
      buttonColor: bgBlack,
      textTheme: ButtonTextTheme.primary,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: bgBlack,
        foregroundColor: cyanNeon,
        side: const BorderSide(color: cyanNeon, width: 1.5),
        shape: const BeveledRectangleBorder(
          borderRadius: BorderRadius.only(topLeft: Radius.circular(10), bottomRight: Radius.circular(10)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      ),
    ),
    inputDecorationTheme: const InputDecorationTheme(
      filled: true,
      fillColor: gridLines,
      border: OutlineInputBorder(
        borderSide: BorderSide(color: cyanNeon),
        borderRadius: BorderRadius.zero,
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(color: magentaNeon, width: 2.0),
        borderRadius: BorderRadius.zero,
      ),
      labelStyle: TextStyle(color: cyanNeon),
    ),
  );

  /// Tema adaptativo para diferentes modos (Single/Studio/Pro).
  static ThemeData getAdaptiveTheme(String mode) {
    switch (mode) {
      case 'Studio':
        return cyberpunkTheme.copyWith(
          primaryColor: Colors.greenAccent,
        );
      case 'Pro':
        return cyberpunkTheme.copyWith(
          primaryColor: Colors.redAccent,
        );
      default: // Single
        return cyberpunkTheme;
    }
  }
}
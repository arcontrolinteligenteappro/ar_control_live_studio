import 'package:flutter/material.dart';
import 'dart:ui' as ui;

/// ARFooter: Footer global persistente.
/// Texto animado: "Elaborado por ChrisRey91 / www.arcontrolinteligente.com"
/// Efecto Scorpion: Escribe -> Espera 3s -> Destello/Glow -> Borra -> Repite
class ARFooter extends StatefulWidget {
  const ARFooter({super.key});

  @override
  _ARFooterState createState() => _ARFooterState();
}

class _ARFooterState extends State<ARFooter> with TickerProviderStateMixin {
  late AnimationController _controller;
  final String _text = "Elaborado por ChrisRey91 / www.arcontrolinteligente.com";
  String _displayText = "";
  bool _isGlowing = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 8));
    _runScorpionCycle();
  }

  Future<void> _runScorpionCycle() async {
    while (mounted) {
      // 1. Escribir (Typewriter)
      for (int i = 0; i <= _text.length; i++) {
        if (!mounted) return;
        setState(() => _displayText = _text.substring(0, i));
        await Future.delayed(const Duration(milliseconds: 30));
      }
      
      // 2. Esperar 3 segundos
      await Future.delayed(const Duration(seconds: 3));
      
      // 3. Efecto Glow/Destello
      if (!mounted) return;
      setState(() => _isGlowing = true);
      await Future.delayed(const Duration(milliseconds: 300));
      setState(() => _isGlowing = false);
      await Future.delayed(const Duration(milliseconds: 100));

      // 4. Borrar rápidamente
      for (int i = _text.length; i >= 0; i--) {
        if (!mounted) return;
        setState(() => _displayText = _text.substring(0, i));
        await Future.delayed(const Duration(milliseconds: 10));
      }
      
      await Future.delayed(const Duration(seconds: 1));
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 4.0),
        color: Colors.transparent,
        child: Text(
          _displayText + (_displayText.length < _text.length ? "_" : ""),
          style: TextStyle(
            color: _isGlowing ? const Color(0xFF00FFFF) : const Color(0xFF00AAAA),
            fontSize: 11,
            fontFamily: 'Courier',
            letterSpacing: 1.2,
            shadows: _isGlowing ? [const Shadow(color: Color(0xFF00FFFF), blurRadius: 10)] : [],
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:ar_control_live_studio/core/theme/cyberpunk_theme.dart';

/// Scaffold estricto que envuelve cada vista. Garantiza uso de SafeArea, 
/// Header persistente y Footer interactivo según requerimientos de AR Control Live.
class MasterScaffold extends StatelessWidget {
  final Widget child;

  const MasterScaffold({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CyberpunkTheme.background,
      body: SafeArea(
        child: Stack(
          children: [
            OrientationBuilder(
              builder: (context, orientation) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const _TerminalHeader(),
                    Expanded(child: child),
                    const _AnimatedFooter(),
                  ],
                );
              },
            ),
            // const _GlitchOverlay(), // New: Glitch effect overlay - Comentado para corregir error de compilación
            const _ScanlineOverlay(), // Efecto de línea de escaneo superpuesto
          ],
        ),
      ),
    );
  }
}

class _TerminalHeader extends StatefulWidget {
  const _TerminalHeader();
  @override
  State<_TerminalHeader> createState() => _TerminalHeaderState();
}

class _TerminalHeaderState extends State<_TerminalHeader> {
  late Timer _timer;
  late String _timeString;

  @override
  void initState() {
    super.initState();
    _updateTime();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) => _updateTime());
  }

  void _updateTime() {
    final now = DateTime.now();
    setState(() {
      _timeString = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: CyberpunkTheme.cyanNeon, width: 1)),
        color: CyberpunkTheme.background,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('AR_CONTROL_LIVE_OS // SYS.ONLINE', style: CyberpunkTheme.terminalStyle),
          Text('[$_timeString]', style: CyberpunkTheme.terminalStyle),
        ],
      ),
    );
  }
}

/// Widget que dibuja una línea de escaneo animada sobre la pantalla.
class _ScanlineOverlay extends StatefulWidget {
  const _ScanlineOverlay();

  @override
  State<_ScanlineOverlay> createState() => _ScanlineOverlayState();
}

class _ScanlineOverlayState extends State<_ScanlineOverlay> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Positioned(
          top: MediaQuery.of(context).size.height * _controller.value,
          left: 0,
          right: 0,
          child: Container(
            height: 2,
            decoration: BoxDecoration(
              color: CyberpunkTheme.cyanNeon.withOpacity(0.1),
              boxShadow: [const BoxShadow(color: CyberpunkTheme.cyanNeon, blurRadius: 6, spreadRadius: 1)],
            ),
          ),
        );
      },
    );
  }
}

class _AnimatedFooter extends StatefulWidget {
  const _AnimatedFooter();
  @override
  State<_AnimatedFooter> createState() => _AnimatedFooterState();
}

class _AnimatedFooterState extends State<_AnimatedFooter> with SingleTickerProviderStateMixin {
  final String _targetText = "Elaborado Por ChrisRey91 / www.arcontrolinteligente.com";
  String _displayText = "";
  bool _showGlow = false;
  
  // State Machine
  int _charIndex = 0;
  bool _isDeleting = false;
  Timer? _typingTimer;

  @override
  void initState() {
    super.initState();
    _startTypingSequence();
  }

  void _startTypingSequence() {
    _typingTimer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      setState(() {
        if (!_isDeleting) {
          // Typewriter IN
          if (_charIndex < _targetText.length) {
            _charIndex++;
            _displayText = _targetText.substring(0, _charIndex);
          } else {
            // Finished typing, trigger Glow and Wait 3 seconds
            timer.cancel();
            _showGlow = true;
            Future.delayed(const Duration(seconds: 3), () {
              if (mounted) {
                setState(() {
                  _showGlow = false;
                  _isDeleting = true;
                });
                _startTypingSequence(); // Restart timer for deletion
              }
            });
          }
        } else {
          // Typewriter OUT (Erasing)
          if (_charIndex > 0) {
            _charIndex--;
            _displayText = _targetText.substring(0, _charIndex);
          } else {
            // Finished deleting, restart typing
            _isDeleting = false;
          }
        }
      });
    });
  }

  @override
  void dispose() {
    _typingTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: CyberpunkTheme.cyanNeon, width: 1)),
        color: CyberpunkTheme.panel,
      ),
      alignment: Alignment.center,
      child: AnimatedDefaultTextStyle(
        duration: const Duration(milliseconds: 300),
        style: TextStyle(
          fontFamily: CyberpunkTheme.fontFamily,
          fontSize: 10,
          color: CyberpunkTheme.cyanNeon,
          shadows: _showGlow 
            ? const [
                Shadow(color: CyberpunkTheme.cyanNeon, blurRadius: 10),
                Shadow(color: CyberpunkTheme.cyanNeon, blurRadius: 20)
              ] 
            : [],
        ),
        child: Text(_displayText + (_isDeleting || _charIndex == _targetText.length ? "" : "_")),
      ),
    );
  }
}
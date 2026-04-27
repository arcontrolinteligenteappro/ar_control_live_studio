import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:ar_control_live_studio/ui/master_scaffold.dart';
import 'package:ar_control_live_studio/core/theme/cyberpunk_theme.dart';
// Asegúrate de importar la vista del menú principal aquí

class BootSequenceView extends StatefulWidget {
  const BootSequenceView({super.key});

  @override
  State<BootSequenceView> createState() => _BootSequenceViewState();
}

class _BootSequenceViewState extends State<BootSequenceView> with TickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 4500));

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        // Una vez que la animación termina, navega a la pantalla principal.
        // Usar un listener es más robusto que un Timer, ya que se acopla
        // directamente al ciclo de vida de la animación.
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/main');
        }
      }
    });
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MasterScaffold(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return CustomPaint(
            painter: BootSequencePainter(_controller.value),
            child: Container(), // Lienzo transparente
          );
        },
      ),
    );
  }
}

/// Motor de renderizado HUD para la secuencia de inicio
class BootSequencePainter extends CustomPainter {
  final double progress; // De 0.0 a 1.0 (0s a 4.5s)

  BootSequencePainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    // Helpers para calcular el progreso de cada fase en base a los segundos
    // Tiempo total = 4.5s
    double t(double startSec, double endSec) {
      final startVal = startSec / 4.5;
      final endVal = endSec / 4.5;
      if (progress <= startVal) return 0.0;
      if (progress >= endVal) return 1.0;
      return (progress - startVal) / (endVal - startVal);
    }

    // FASE 1 (0.0s - 1.2s): Trim paths Letras A R
    double letterA = t(0.0, 0.6); // A va del 0 al 50% de la fase 1 (0.0s - 0.6s)
    double letterR = t(0.6, 1.2); // R va del 50% al 100% (0.6s - 1.2s)
    bool shouldGlowAR = progress >= (1.2 / 4.5);
    _drawNeonLetters(canvas, center, letterA, letterR, shouldGlowAR, CyberpunkTheme.magentaNeon);

    // FASE 5 (2.0s - 3.2s): Fade-in Hacker Silhouette
    double hackerFade = t(2.0, 3.2);
    if (hackerFade > 0) {
      _drawHackerSilhouette(canvas, center, hackerFade);
    }

    // FASE 3 (1.2s - 2.2s): Circuitos
    double circuitsProgress = t(1.2, 2.2);
    if (circuitsProgress > 0) {
      _drawCircuits(canvas, center, circuitsProgress, CyberpunkTheme.cyanNeon);
    }

    // FASE 2 (0.8s - 1.8s): Explosión de Iconos
    double iconExplosion = t(0.8, 1.8);
    if (iconExplosion > 0) {
      _drawExplodingIcons(canvas, center, iconExplosion, CyberpunkTheme.cyanNeon);
    }

    // FASE 4 (0.5s - 4.0s): Barra HUD
    double hudLoad = t(0.5, 4.0);
    if (hudLoad > 0) {
      _drawHUDBar(canvas, size, hudLoad, CyberpunkTheme.cyanNeon);
    }

    // FASE 6 (3.5s - 4.5s): Texto final y parpadeo LIVE
    double textGlow = t(3.5, 4.5);
    if (textGlow > 0) {
      _drawFinalText(canvas, center, textGlow, CyberpunkTheme.cyanNeon, size);
    }
  }

  void _drawNeonLetters(Canvas canvas, Offset center, double aProg, double rProg, bool showGlow, Color color) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0
      ..strokeCap = StrokeCap.square
      
    if(showGlow) {
       paint.shadows = [Shadow(color: color, blurRadius: 12), Shadow(color: color, blurRadius: 24)];
    }

    // Trazado de la 'A'
    if (aProg > 0) {
      final pathA = Path()
        ..moveTo(center.dx - 40, center.dy + 40)
        ..lineTo(center.dx - 15, center.dy - 40)
        ..lineTo(center.dx + 10, center.dy + 40)
        ..moveTo(center.dx - 30, center.dy + 10)
        ..lineTo(center.dx, center.dy + 10);
      
      _drawTrimPath(canvas, pathA, paint, aProg);
    }

    // Trazado de la 'R'
    if (rProg > 0) {
      final pathR = Path()
        ..moveTo(center.dx + 15, center.dy + 40)
        ..lineTo(center.dx + 15, center.dy - 40)
        ..lineTo(center.dx + 40, center.dy - 40)
        ..quadraticBezierTo(center.dx + 55, center.dy - 40, center.dx + 55, center.dy - 20)
        ..quadraticBezierTo(center.dx + 55, center.dy, center.dx + 40, center.dy)
        ..lineTo(center.dx + 15, center.dy)
        ..moveTo(center.dx + 35, center.dy)
        ..lineTo(center.dx + 55, center.dy + 40);
      
      _drawTrimPath(canvas, pathR, paint, rProg);
    }
  }

  void _drawTrimPath(Canvas canvas, Path path, Paint paint, double progress) {
    final metrics = path.computeMetrics().toList();
    for (var metric in metrics) {
      final extractPath = metric.extractPath(0.0, metric.length * progress);
      canvas.drawPath(extractPath, paint);
    }
  }

  void _drawExplodingIcons(Canvas canvas, Offset center, double progress, Color color) {
    // Inercia suave (easeOut)
    final easeOut = 1.0 - pow(1.0 - progress, 3);
    final radius = 120.0 * easeOut;
    
    // Seis iconos solicitados: cámara, chip, control, avión, micrófono, panel
    final List<IconData> icons = [
      Icons.videocam, Icons.memory, Icons.gamepad, 
      Icons.flight, Icons.mic, Icons.dashboard
    ];

    for (int i = 0; i < 6; i++) {
      final angle = (i * 60) * pi / 180;
      final dx = center.dx + cos(angle) * radius;
      final dy = center.dy + sin(angle) * radius;
      
      final iconPainter = TextPainter(
        text: TextSpan(text: String.fromCharCode(icons[i].codePoint), style: TextStyle(fontFamily: icons[i].fontFamily, fontSize: 24, color: color.withOpacity(1.0 - progress))),
        textDirection: TextDirection.ltr,
      )..layout();
      iconPainter.paint(canvas, Offset(dx - 12, dy - 12));
    }
  }

  void _drawCircuits(Canvas canvas, Offset center, double progress, Color color) {
    final paint = Paint()..color = color.withOpacity(0.5)..style = PaintingStyle.stroke..strokeWidth = 1.0;
    for (int i = 0; i < 6; i++) {
      final angle = (i * 60) * pi / 180;
      final path = Path()
        ..moveTo(center.dx, center.dy)
        ..lineTo(center.dx + cos(angle) * 60, center.dy + sin(angle) * 60)
        ..lineTo(center.dx + cos(angle + 0.4) * 90, center.dy + sin(angle + 0.4) * 90)
        ..lineTo(center.dx + cos(angle + 0.2) * 120, center.dy + sin(angle + 0.2) * 120);
      _drawTrimPath(canvas, path, paint, progress);
    }
  }

  void _drawHUDBar(Canvas canvas, Size size, double progress, Color color) {
    final paintBg = Paint()..color = const Color(0xFF111111)..style = PaintingStyle.fill;
    final paintFg = Paint()..color = color..style = PaintingStyle.fill..shadows = [Shadow(color: color, blurRadius: 8)];
    
    final barWidth = size.width * 0.8;
    final barRectBg = Rect.fromLTWH(size.width * 0.1, size.height * 0.85, barWidth, 4);
    canvas.drawRect(barRectBg, paintBg);
    
    final barRectFg = Rect.fromLTWH(size.width * 0.1, size.height * 0.85, barWidth * progress, 4);
    canvas.drawRect(barRectFg, paintFg);

    // Texto Loading
    final label = progress < 0.2 ? 'INITIALIZING ENGINE...' : 
                  progress < 0.6 ? 'LINKING HARDWARE CODECS...' : 
                  progress < 0.9 ? 'ESTABLISHING WEBRTC NODES...' : 
                  'SYS.ONLINE';

    final textPainter = TextPainter(
      text: TextSpan(text: '>> $label // ${(progress * 100).toInt()}%', style: TextStyle(color: color, fontSize: 10, fontFamily: CyberpunkTheme.fontFamily)),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(size.width * 0.1, size.height * 0.85 + 10));
  }

  void _drawHackerSilhouette(Canvas canvas, Offset center, double opacity) {
    // Representación abstracta vectorial del Hacker en el fondo
    final paint = Paint()
      ..color = const Color(0xFF001A1A).withOpacity(opacity * 0.4)
      ..style = PaintingStyle.fill;
    
    final path = Path()
      ..moveTo(center.dx - 120, center.dy + 250)
      ..lineTo(center.dx - 80, center.dy - 50)
      ..lineTo(center.dx, center.dy - 100) 
      ..lineTo(center.dx + 80, center.dy - 50)
      ..lineTo(center.dx + 120, center.dy + 250)
      ..close();
    canvas.drawPath(path, paint);
  }

  void _drawFinalText(Canvas canvas, Offset center, double progress, Color color, Size size) {
    // Destello de luz izquierda a derecha (Sweep mask sobre el texto)
    final gradient = ui.Gradient.linear(
      Offset(center.dx - 100 + (200 * progress), center.dy), 
      Offset(center.dx - 50 + (200 * progress), center.dy),
      [color.withOpacity(0.2), const Color(0xFFFFFFFF), color.withOpacity(0.2)],
    );

    final textStyle = TextStyle(
      color: color, 
      fontSize: 22, 
      fontFamily: CyberpunkTheme.fontFamily, 
      fontWeight: FontWeight.bold, 
      foreground: Paint()..shader = gradient
    );

    final textPainter = TextPainter(
      text: TextSpan(text: 'CHRISREY91', style: textStyle),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(center.dx - (textPainter.width / 2), center.dy + 70));

    // Parpadeo de "LIVE" en rojo neón (Dos veces estricto)
    bool showLive = (progress > 0.1 && progress < 0.3) || (progress > 0.5 && progress < 0.7) || progress > 0.9;
    if (showLive) {
      final livePainter = TextPainter(
        text: const TextSpan(
          text: '● REC', 
          style: TextStyle(color: Color(0xFFFF0000), fontSize: 16, fontFamily: CyberpunkTheme.fontFamily, fontWeight: FontWeight.bold, shadows: [Shadow(color: Color(0xFFFF0000), blurRadius: 10)])
        ),
        textDirection: TextDirection.ltr,
      );
      livePainter.layout();
      livePainter.paint(canvas, Offset(size.width - livePainter.width - 32, 24));
    }
  }

  @override
  bool shouldRepaint(covariant BootSequencePainter oldDelegate) => oldDelegate.progress != progress;
}

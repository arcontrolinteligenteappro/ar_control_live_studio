import 'package:flutter/material.dart';
import '../../cyberpunk_theme.dart';

/// Un botón de control con estilo cyberpunk, bordes angulares y efecto de neón parpadeante.
class ControlButton extends StatefulWidget {
  final String label;
  final VoidCallback? onTap;
  final Color color;

  const ControlButton({
    super.key,
    required this.label,
    this.onTap,
    required this.color,
  });

  @override
  State<ControlButton> createState() => _ControlButtonState();
}

class _ControlButtonState extends State<ControlButton> with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          // El valor de la animación se usa para crear un parpadeo sutil.
          final flicker = (_animationController.value * 10).floor() % 2 == 0 ? 0.8 : 1.0;
          return CustomPaint(
            painter: _ControlButtonPainter(
              color: widget.color,
              flickerOpacity: flicker,
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              child: Text(
                widget.label,
                style: CyberpunkTheme.terminalStyle.copyWith(
                  color: widget.color,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  shadows: [
                    Shadow(color: widget.color, blurRadius: 10 * flicker),
                    Shadow(color: widget.color, blurRadius: 20 * flicker),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ControlButtonPainter extends CustomPainter {
  final Color color;
  final double flickerOpacity;

  _ControlButtonPainter({required this.color, required this.flickerOpacity});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final path = Path();
    const cornerSize = 10.0;

    // Dibuja el borde angular
    path.moveTo(cornerSize, 0);
    path.lineTo(size.width - cornerSize, 0);
    path.lineTo(size.width, cornerSize);
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.lineTo(0, cornerSize);
    path.close();

    // Dibuja el brillo exterior (neon glow)
    paint.color = color.withOpacity(0.5 * flickerOpacity);
    paint.maskFilter = const MaskFilter.blur(BlurStyle.normal, 5.0);
    canvas.drawPath(path, paint);

    // Dibuja el brillo interior
    paint.color = color.withOpacity(0.7 * flickerOpacity);
    paint.maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.0);
    canvas.drawPath(path, paint);

    // Dibuja la línea principal del borde
    paint.color = color.withOpacity(flickerOpacity);
    paint.maskFilter = null;
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _ControlButtonPainter oldDelegate) {
    return color != oldDelegate.color || flickerOpacity != oldDelegate.flickerOpacity;
  }
}
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

/// OverlayEngine: Motor de overlays para broadcast.
/// Gestiona composición de gráficos, texto, logos sobre video.
/// Independiente del streaming/recording.
class OverlayEngine {
  static final OverlayEngine _instance = OverlayEngine._internal();

  factory OverlayEngine() => _instance;

  OverlayEngine._internal();

  List<OverlayElement> _overlays = [];

  /// Añade overlay de texto.
  void addTextOverlay(String text, Offset position, TextStyle style) {
    _overlays.add(TextOverlay(text, position, style));
  }

  /// Añade overlay gráfico.
  void addGraphicOverlay(ui.Image image, Offset position, Size size) {
    _overlays.add(GraphicOverlay(image, position, size));
  }

  /// Añade logo.
  void addLogoOverlay(ui.Image logo, Offset position, double opacity) {
    _overlays.add(LogoOverlay(logo, position, opacity));
  }

  /// Remueve overlay.
  void removeOverlay(int index) {
    if (index < _overlays.length) {
      _overlays.removeAt(index);
    }
  }

  /// Renderiza overlays sobre canvas.
  void renderOverlays(Canvas canvas, Size videoSize) {
    for (var overlay in _overlays) {
      overlay.render(canvas);
    }
  }

  /// Actualiza posición de overlay.
  void updateOverlayPosition(int index, Offset newPosition) {
    if (index < _overlays.length) {
      _overlays[index].updatePosition(newPosition);
    }
  }

  /// Lista de overlays.
  List<OverlayElement> get overlays => _overlays;

  /// Limpia todos los overlays.
  void clearOverlays() {
    _overlays.clear();
  }
}

/// Base para elementos de overlay.
abstract class OverlayElement {
  Offset position;

  OverlayElement(this.position);

  void render(Canvas canvas);
  void updatePosition(Offset newPosition) {
    position = newPosition;
  }
}

/// Overlay de texto.
class TextOverlay extends OverlayElement {
  final String text;
  final TextStyle style;

  TextOverlay(this.text, Offset position, this.style) : super(position);

  @override
  void render(Canvas canvas) {
    final textPainter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, position);
  }
}

/// Overlay gráfico.
class GraphicOverlay extends OverlayElement {
  final ui.Image image;
  final Size size;

  GraphicOverlay(this.image, Offset position, this.size) : super(position);

  @override
  void render(Canvas canvas) {
    final rect = Rect.fromLTWH(position.dx, position.dy, size.width, size.height);
    canvas.drawImageRect(image, Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()), rect, Paint());
  }
}

/// Overlay de logo.
class LogoOverlay extends OverlayElement {
  final ui.Image logo;
  final double opacity;

  LogoOverlay(this.logo, Offset position, this.opacity) : super(position);

  @override
  void render(Canvas canvas) {
    final paint = Paint()..color = Colors.white.withOpacity(opacity);
    final rect = Rect.fromLTWH(position.dx, position.dy, logo.width.toDouble(), logo.height.toDouble());
    canvas.drawImageRect(logo, Rect.fromLTWH(0, 0, logo.width.toDouble(), logo.height.toDouble()), rect, paint);
  }
}
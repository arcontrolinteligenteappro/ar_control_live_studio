import 'package:flutter/material.dart';
import 'package:ar_control_live_studio/core/theme/cyberpunk_theme.dart';

/// Widget para mostrar un panel de información con estilo cyberpunk.
class InfoPanel extends StatelessWidget {
  final String title;
  final String subtitle;

  const InfoPanel({super.key, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(border: Border(left: BorderSide(color: CyberpunkTheme.cyanNeon, width: 4)), color: CyberpunkTheme.panel),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: CyberpunkTheme.terminalStyle),
            Text(subtitle, style: CyberpunkTheme.terminalStyle.copyWith(color: CyberpunkTheme.textMain, fontSize: 10)),
          ],
        ),
      ),
    );
  }
}

/// Widget reutilizable para un botón de selección con estilo cyberpunk.
class SelectionButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final Color? color;

  const SelectionButton({
    super.key,
    required this.label,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final neon = color ?? CyberpunkTheme.cyanNeon;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: CyberpunkTheme.panel,
          foregroundColor: neon,
          shadowColor: neon,
          elevation: 8,
          shape: const BeveledRectangleBorder(side: BorderSide(color: CyberpunkTheme.cyanNeon, width: 1)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        ),
        onPressed: onTap,
        child: Text(label, style: CyberpunkTheme.terminalStyle.copyWith(fontSize: 14)),
      ),
    );
  }
}

/// Widget para mostrar un chip de acción con estado activo/inactivo.
class ActionChipWidget extends StatelessWidget {
  final String label;
  final bool active;

  const ActionChipWidget({super.key, required this.label, required this.active});

  @override
  Widget build(BuildContext context) {
    final color = active ? CyberpunkTheme.cyanNeon : CyberpunkTheme.textMain;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        border: Border.all(color: color),
        color: active ? color.withOpacity(0.2) : Colors.transparent,
      ),
      child: Text(label, style: CyberpunkTheme.terminalStyle.copyWith(color: color)),
    );
  }
}

/// Muestra una notificación "toast" con estilo cyberpunk.
void showCyberpunkToast(BuildContext context, String message, {Color? color}) {
  final OverlayState? overlayState = Overlay.of(context);
  if (overlayState == null) return;

  OverlayEntry? overlayEntry;

  overlayEntry = OverlayEntry(
    builder: (context) => CyberpunkToastWidget(
      message: message,
      color: color ?? CyberpunkTheme.magentaNeon,
      onDismiss: () {
        overlayEntry?.remove();
      },
    ),
  );

  overlayState.insert(overlayEntry);
}

class CyberpunkToastWidget extends StatefulWidget {
  final String message;
  final Color color;
  final VoidCallback onDismiss;

  const CyberpunkToastWidget({
    super.key,
    required this.message,
    required this.color,
    required this.onDismiss,
  });

  @override
  State<CyberpunkToastWidget> createState() => _CyberpunkToastWidgetState();
}

class _CyberpunkToastWidgetState extends State<CyberpunkToastWidget> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
    _opacity = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));

    _controller.forward().whenComplete(() {
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          _controller.reverse().whenComplete(() => widget.onDismiss());
        }
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 80.0, // Elevado para no chocar con el footer animado
      left: 24,
      right: 24,
      child: FadeTransition(
        opacity: _opacity,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
            decoration: BoxDecoration(
              color: CyberpunkTheme.panel.withOpacity(0.95),
              border: Border.all(color: widget.color, width: 1),
              boxShadow: [BoxShadow(color: widget.color, blurRadius: 8)],
            ),
            child: Text('>> ${widget.message}', textAlign: TextAlign.center, style: CyberpunkTheme.terminalStyle.copyWith(color: widget.color, fontSize: 14)),
          ),
        ),
      ),
    );
  }
}
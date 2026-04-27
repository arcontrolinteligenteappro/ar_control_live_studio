import 'package:flutter/material.dart';
import 'footer.dart';

/// ARLayout: Layout base adaptativo.
/// Detecta orientación, notch, safe areas.
/// Footer persistente.
/// Modos: Single/Studio/Pro.
class ARLayout extends StatelessWidget {
  final Widget child;
  final String mode; // 'Single', 'Studio', 'Pro'

  const ARLayout({super.key, required this.child, this.mode = 'Single'});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            child,
            const ARFooter(),
          ],
        ),
      ),
    );
  }
}

/// AdaptiveGrid: Grid adaptativo para controles.
/// Ajusta columnas según orientación y tamaño.
class AdaptiveGrid extends StatelessWidget {
  final List<Widget> children;
  final int crossAxisCountPortrait;
  final int crossAxisCountLandscape;

  const AdaptiveGrid({
    super.key,
    required this.children,
    this.crossAxisCountPortrait = 2,
    this.crossAxisCountLandscape = 4,
  });

  @override
  Widget build(BuildContext context) {
    final orientation = MediaQuery.of(context).orientation;
    final crossAxisCount = orientation == Orientation.portrait
        ? crossAxisCountPortrait
        : crossAxisCountLandscape;

    return GridView.count(
      crossAxisCount: crossAxisCount,
      children: children,
    );
  }
}
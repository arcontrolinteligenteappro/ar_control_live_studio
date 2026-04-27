import 'package:flutter/material.dart';
import '../core/theme/cyberpunk_theme.dart';

class MasterScaffold extends StatelessWidget {
  final Widget child;
  const MasterScaffold({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CyberpunkTheme.background,
      body: SafeArea(child: child),
    );
  }
}
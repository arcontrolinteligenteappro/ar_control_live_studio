import 'package:flutter/material.dart';

// Placeholder implementation
class MasterScaffold extends StatelessWidget {
  final Widget child;
  const MasterScaffold({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
    );
  }
}
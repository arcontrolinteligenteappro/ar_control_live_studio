import 'package:flutter/material.dart';

class PlaceholderModuleView extends StatelessWidget {
  final String title;
  final String subtitle;

  const PlaceholderModuleView({super.key, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(title, style: const TextStyle(color: Colors.cyanAccent)),
      ),
      body: Center(
        child: Text(subtitle, style: const TextStyle(color: Colors.white70, fontSize: 18), textAlign: TextAlign.center),
      ),
    );
  }
}

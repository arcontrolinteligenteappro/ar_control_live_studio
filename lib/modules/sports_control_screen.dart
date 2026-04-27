import 'package:flutter/material.dart';
import 'package:ar_control_live_studio/modules/sports_module.dart';

class SportsControlScreen extends StatelessWidget {
  const SportsControlScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('SPORTS CONTROL', style: TextStyle(color: Colors.orangeAccent, fontFamily: 'Courier New')),
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.orangeAccent),
      ),
      body: const Padding(
        padding: EdgeInsets.all(16),
        child: SportsModule(),
      ),
    );
  }
}

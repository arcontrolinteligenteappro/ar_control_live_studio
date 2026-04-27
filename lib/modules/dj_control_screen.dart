import 'package:flutter/material.dart';
import 'package:ar_control_live_studio/modules/dj_pro_module.dart';

class DJControlScreen extends StatelessWidget {
  const DJControlScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('DJ PRO CONTROL', style: TextStyle(color: Colors.cyanAccent, fontFamily: 'Courier New')),
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.cyanAccent),
      ),
      body: const Padding(
        padding: EdgeInsets.all(16),
        child: DJProModule(),
      ),
    );
  }
}

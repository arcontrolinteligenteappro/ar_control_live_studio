import 'package:flutter/material.dart';
import 'dart:io';

class AnalyticsDashboard extends StatelessWidget {
  const AnalyticsDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(title: const Text("SYSTEM TELEMETRY", style: TextStyle(color: Colors.orangeAccent, fontFamily: 'Courier New')), backgroundColor: Colors.black, iconTheme: const IconThemeData(color: Colors.orangeAccent)),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("> HARDWARE DETECTADO", style: TextStyle(color: Colors.orangeAccent, fontWeight: FontWeight.bold, fontFamily: 'Courier New')),
            const SizedBox(height: 20),
            ListTile(title: const Text("HILOS DE PROCESAMIENTO", style: TextStyle(color: Colors.white70, fontFamily: 'Courier New')), trailing: Text("${Platform.numberOfProcessors} CORES", style: const TextStyle(color: Colors.orangeAccent, fontWeight: FontWeight.bold))),
            ListTile(title: const Text("VERSIÓN DE KERNEL", style: TextStyle(color: Colors.white70, fontFamily: 'Courier New')), subtitle: Text(Platform.operatingSystemVersion, style: const TextStyle(color: Colors.orangeAccent))),
            ListTile(title: const Text("SISTEMA OPERATIVO", style: TextStyle(color: Colors.white70, fontFamily: 'Courier New')), trailing: Text(Platform.operatingSystem.toUpperCase(), style: const TextStyle(color: Colors.orangeAccent, fontWeight: FontWeight.bold))),
          ],
        ),
      )
    );
  }
}
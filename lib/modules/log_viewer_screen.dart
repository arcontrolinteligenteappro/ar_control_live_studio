import 'package:flutter/material.dart';
import 'package:ar_control_live_studio/modules/log_engine.dart';
import 'package:ar_control_live_studio/services/service_locator.dart';

class LogViewerScreen extends StatefulWidget {
  const LogViewerScreen({super.key});

  @override
  State<LogViewerScreen> createState() => _LogViewerScreenState();
}

class _LogViewerScreenState extends State<LogViewerScreen> {
  final LogEngine _logEngine = ServiceLocator.logEngine;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('LOG VIEWER', style: TextStyle(color: Colors.orangeAccent, fontFamily: 'Courier New')),
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.orangeAccent),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.orangeAccent),
            onPressed: () {
              setState(() {
                _logEngine.clearLogs();
              });
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSection('SYSTEM', _logEngine.systemLogs),
            const SizedBox(height: 20),
            _buildSection('STREAM', _logEngine.streamLogs),
            const SizedBox(height: 20),
            _buildSection('CONNECTION', _logEngine.connectionLogs),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<String> logs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(color: Colors.orangeAccent, fontWeight: FontWeight.bold, fontFamily: 'Courier New')),
        const SizedBox(height: 10),
        if (logs.isEmpty) 
          const Text('No logs available', style: TextStyle(color: Colors.white38))
        else
          ...logs.reversed.map((log) => Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Text(log, style: const TextStyle(color: Colors.white70, fontFamily: 'Courier New', fontSize: 12)),
          )),
      ],
    );
  }
}

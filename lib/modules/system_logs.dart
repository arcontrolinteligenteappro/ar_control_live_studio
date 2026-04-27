import 'package:flutter/material.dart';
import 'dart:async';

class SystemLogsScreen extends StatefulWidget {
  const SystemLogsScreen({super.key});
  @override
  State<SystemLogsScreen> createState() => _SystemLogsScreenState();
}

class _SystemLogsScreenState extends State<SystemLogsScreen> {
  final List<String> _logs = ["> [INIT] AR Control Inteligente v1.0", "> [SYS] Enlace físico establecido."];
  Timer? _timer;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _startLiveLogging();
  }

  void _startLiveLogging() {
    _timer = Timer.periodic(const Duration(milliseconds: 2000), (timer) {
      if (!mounted) return;
      setState(() {
        final now = DateTime.now();
        final timeStr = "${now.hour.toString().padLeft(2,'0')}:${now.minute.toString().padLeft(2,'0')}:${now.second.toString().padLeft(2,'0')}";
        _logs.add("> [$timeStr] [NET] Ping interno: ${12 + (now.millisecond % 15)}ms");
        
        Future.delayed(const Duration(milliseconds: 100), () {
          if (_scrollController.hasClients) {
            _scrollController.animateTo(_scrollController.position.maxScrollExtent, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
          }
        });
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(title: const Text('TERMINAL DE SISTEMA', style: TextStyle(color: Colors.greenAccent, fontFamily: 'Courier New', fontWeight: FontWeight.bold)), backgroundColor: Colors.black, iconTheme: const IconThemeData(color: Colors.greenAccent)),
      body: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(15),
        itemCount: _logs.length,
        itemBuilder: (context, index) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Text(_logs[index], style: const TextStyle(color: Colors.greenAccent, fontFamily: 'Courier New', fontSize: 13)),
        ),
      ),
    );
  }
}
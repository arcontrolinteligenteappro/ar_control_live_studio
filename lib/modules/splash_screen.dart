import 'package:flutter/material.dart'; // ESTO ES LO QUE FALTABA
import 'dart:async';
import 'main_dashboard.dart';

class CyberSplashView extends StatefulWidget {
  const CyberSplashView({super.key});

  @override
  State<CyberSplashView> createState() => _CyberSplashViewState();
}

class _CyberSplashViewState extends State<CyberSplashView> {
  double _progress = 0.0;

  @override
  void initState() {
    super.initState();
    _startLoading();
  }

  void _startLoading() async {
    for (int i = 0; i <= 100; i++) {
      await Future.delayed(const Duration(milliseconds: 30));
      if (mounted) setState(() => _progress = i / 100);
    }
    if (mounted) {
      Navigator.pushReplacement(
        context, 
        MaterialPageRoute(builder: (context) => const MainDashboard())
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "AR CONTROL LIVE", 
              style: TextStyle(
                color: Colors.cyanAccent, 
                fontSize: 24, 
                fontWeight: FontWeight.bold, 
                letterSpacing: 4
              )
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: 200, 
              child: LinearProgressIndicator(
                value: _progress, 
                color: Colors.cyanAccent,
                backgroundColor: Colors.white10,
              )
            ),
            const SizedBox(height: 10),
            const Text(
              "LOADING SYSTEM - ChrisRey91", 
              style: TextStyle(color: Colors.white24, fontSize: 10)
            ),
          ],
        ),
      ),
    );
  }
}
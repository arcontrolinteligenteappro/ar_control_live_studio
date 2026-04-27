// FILE: lib/modules/overlay_engine.dart
import 'package:flutter/material.dart';

class OverlayEngine extends ChangeNotifier {
  bool showScoreboard = false;
  bool showLowerThird = false;
  String announcementText = "AR CONTROL STREAM LIVE";

  bool showBrandBug = true;
  bool showTicker = false;

  void toggleScoreboard() {
    showScoreboard = !showScoreboard;
    notifyListeners();
  }

  void toggleLowerThird() {
    showLowerThird = !showLowerThird;
    notifyListeners();
  }

  void toggleBrandBug() {
    showBrandBug = !showBrandBug;
    notifyListeners();
  }

  void toggleTicker() {
    showTicker = !showTicker;
    notifyListeners();
  }

  void showAnnouncement(String text) {
    announcementText = text;
    showLowerThird = true;
    notifyListeners();
    Future.delayed(const Duration(seconds: 5), () {
      showLowerThird = false;
      notifyListeners();
    });
  }

  // Estética de la marca AR Control Inteligente corregida para Flutter 3.27+
  Color get themeCyan => const Color(0xFF00E5FF);
  Color get themeMagenta => const Color(0xFFFF00FF);

  Color get glassBlack => Colors.black.withOpacity(0.7);
}
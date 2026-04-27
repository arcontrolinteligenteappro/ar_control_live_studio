import 'package:flutter/material.dart';
import 'package:ar_control_live_studio/config/app_config.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AppState with ChangeNotifier {
  bool isDarkTheme = true;
  String nvrIp = AppConfig.nvrIp;
  bool isLive = false;
  String operatorName = "ChrisRey91";

  void toggleTheme() {
    isDarkTheme = !isDarkTheme;
    notifyListeners();
  }
}
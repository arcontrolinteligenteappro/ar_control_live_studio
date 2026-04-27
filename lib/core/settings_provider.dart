import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

@immutable
class AppSettings {
  final int webrtcBitrate;

  const AppSettings({this.webrtcBitrate = 5000}); // Default 5Mbps

  AppSettings copyWith({int? webrtcBitrate}) {
    return AppSettings(webrtcBitrate: webrtcBitrate ?? this.webrtcBitrate);
  }

  Map<String, dynamic> toJson() => {'webrtcBitrate': webrtcBitrate};

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    return AppSettings(webrtcBitrate: json['webrtcBitrate'] ?? 5000);
  }
}

class SettingsNotifier extends StateNotifier<AppSettings> {
  SettingsNotifier() : super(const AppSettings());

  Future<void> setWebrtcBitrate(int bitrate) async {
    state = state.copyWith(webrtcBitrate: bitrate);
    await saveSettings();
  }

  Future<String> get _localPath async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  Future<File> get _localFile async {
    final path = await _localPath;
    return File('$path/app_settings.json');
  }

  Future<void> saveSettings() async {
    try {
      final file = await _localFile;
      final jsonString = jsonEncode(state.toJson());
      await file.writeAsString(jsonString);
    } catch (e) {
      debugPrint('Failed to save app settings: $e');
    }
  }

  Future<void> loadSettings() async {
    try {
      final file = await _localFile;
      if (await file.exists()) {
        final jsonString = await file.readAsString();
        state = AppSettings.fromJson(jsonDecode(jsonString));
        debugPrint('App settings loaded from ${file.path}');
      }
    } catch (e) {
      debugPrint('Failed to load app settings, using defaults: $e');
    }
  }
}

final settingsProvider = StateNotifierProvider<SettingsNotifier, AppSettings>((ref) {
  return SettingsNotifier();
});
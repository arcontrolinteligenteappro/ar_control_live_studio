import 'package:flutter/foundation.dart';
import 'package:ar_control_live_studio/core/errors/app_errors.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:ar_control_live_studio/config/app_config.dart';

class ErrorHandler {
  static const String _logFileName = 'ar_control_logs.json';
  static const int _maxLogEntries = 1000;
  static const Duration _logRetentionDays = Duration(days: 7);

  static void handle(AppError error) {
    if (kDebugMode) {
      debugPrint('[${error.code}] ${error.message}');
      if (error.stackTrace != null) {
        debugPrint(error.stackTrace.toString());
      }
    }
    _logError(error);
    _sendToBackend(error);
  }

  static void logInfo(String message, {Map<String, dynamic>? metadata}) {
    final logEntry = LogEntry(
      level: LogLevel.info,
      message: message,
      timestamp: DateTime.now(),
      metadata: metadata,
    );
    _writeLogEntry(logEntry);
  }

  static void logWarning(String message, {Map<String, dynamic>? metadata}) {
    final logEntry = LogEntry(
      level: LogLevel.warning,
      message: message,
      timestamp: DateTime.now(),
      metadata: metadata,
    );
    _writeLogEntry(logEntry);
  }

  static void logError(String message, {Map<String, dynamic>? metadata, StackTrace? stackTrace}) {
    final logEntry = LogEntry(
      level: LogLevel.error,
      message: message,
      timestamp: DateTime.now(),
      metadata: metadata,
      stackTrace: stackTrace?.toString(),
    );
    _writeLogEntry(logEntry);
    _sendToBackend(
      LogicError(
       message,
      stackTrace: stackTrace,
      ),
    );
  }

  static void _logError(AppError error) {
    final logEntry = LogEntry(
      level: LogLevel.error,
      message: error.message,
      timestamp: DateTime.now(),
      errorCode: error.code,
      stackTrace: error.stackTrace?.toString(),
    );
    _writeLogEntry(logEntry);
  }

  static Future<void> _writeLogEntry(LogEntry entry) async {
    try {
      final logFile = await _getLogFile();
      final logs = await _readLogs();

      logs.add(entry);

      // Mantener solo las últimas entradas
      if (logs.length > _maxLogEntries) {
        logs.removeRange(0, logs.length - _maxLogEntries);
      }

      // Limpiar logs antiguos
      _cleanOldLogs(logs);

      final jsonData = jsonEncode(logs.map((log) => log.toJson()).toList());
      await logFile.writeAsString(jsonData);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Failed to write log entry: $e');
      }
    }
  }

  static Future<void> _sendToBackend(AppError error) async {
    if (!AppConfig.enableBackendLogging) return;

    try {
      final response = await http.post(
        Uri.parse('${AppConfig.backendUrl}/api/logs'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${AppConfig.backendApiKey}',
        },
        body: jsonEncode({
          'timestamp': DateTime.now().toIso8601String(),
          'level': 'error',
          'code': error.code,
          'message': error.message,
          'stackTrace': error.stackTrace?.toString(),
          'platform': Platform.operatingSystem,
          'version': AppConfig.appVersion,
        }),
      );

      if (response.statusCode != 200 && kDebugMode) {
        debugPrint('Failed to send log to backend: ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error sending log to backend: $e');
      }
    }
  }

  static Future<File> _getLogFile() async {
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/$_logFileName');
  }

  static Future<List<LogEntry>> _readLogs() async {
    try {
      final logFile = await _getLogFile();
      if (!await logFile.exists()) return [];

      final jsonData = await logFile.readAsString();
      final jsonList = jsonDecode(jsonData) as List<dynamic>;

      return jsonList.map((json) => LogEntry.fromJson(json)).toList();
    } catch (e) {
      return [];
    }
  }

  static void _cleanOldLogs(List<LogEntry> logs) {
    final cutoffDate = DateTime.now().subtract(_logRetentionDays);
    logs.removeWhere((log) => log.timestamp.isBefore(cutoffDate));
  }

  static Future<List<LogEntry>> getLogs({
    LogLevel? level,
    DateTime? startDate,
    DateTime? endDate,
    int? limit,
  }) async {
    final logs = await _readLogs();

    var filteredLogs = logs;

    if (level != null) {
      filteredLogs = filteredLogs.where((log) => log.level == level).toList();
    }

    if (startDate != null) {
      filteredLogs = filteredLogs.where((log) => log.timestamp.isAfter(startDate)).toList();
    }

    if (endDate != null) {
      filteredLogs = filteredLogs.where((log) => log.timestamp.isBefore(endDate)).toList();
    }

    if (limit != null && filteredLogs.length > limit) {
      filteredLogs = filteredLogs.sublist(filteredLogs.length - limit);
    }

    return filteredLogs.reversed.toList(); // Más recientes primero
  }

  static Future<void> clearLogs() async {
    try {
      final logFile = await _getLogFile();
      if (await logFile.exists()) {
        await logFile.delete();
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Failed to clear logs: $e');
      }
    }
  }

  static Future<Map<String, int>> getLogStats() async {
    final logs = await _readLogs();
    final stats = <String, int>{};

    for (final log in logs) {
      final levelName = log.level.toString().split('.').last;
      stats[levelName] = (stats[levelName] ?? 0) + 1;
    }

    return stats;
  }
}

enum LogLevel {
  info,
  warning,
  error,
}

class LogEntry {
  final LogLevel level;
  final String message;
  final DateTime timestamp;
  final String? errorCode;
  final String? stackTrace;
  final Map<String, dynamic>? metadata;

  LogEntry({
    required this.level,
    required this.message,
    required this.timestamp,
    this.errorCode,
    this.stackTrace,
    this.metadata,
  });

  Map<String, dynamic> toJson() {
    return {
      'level': level.toString().split('.').last,
      'message': message,
      'timestamp': timestamp.toIso8601String(),
      'errorCode': errorCode,
      'stackTrace': stackTrace,
      'metadata': metadata,
    };
  }

  factory LogEntry.fromJson(Map<String, dynamic> json) {
    return LogEntry(
      level: LogLevel.values.firstWhere(
        (e) => e.toString().split('.').last == json['level'],
        orElse: () => LogLevel.info,
      ),
      message: json['message'],
      timestamp: DateTime.parse(json['timestamp']),
      errorCode: json['errorCode'],
      stackTrace: json['stackTrace'],
      metadata: json['metadata'],
    );
  }
}

abstract class AppError implements Exception {
  final String message;
  final StackTrace? stackTrace;

  AppError(this.message, {this.stackTrace});

  String get code;

  @override
  String toString() => '[$code] $message';
}

class HardwareError extends AppError {
  final String device;

  HardwareError(String message, {required this.device, StackTrace? stackTrace})
      : super(message, stackTrace: stackTrace);

  @override
  String get code => 'HARDWARE_ERROR';
}

class CaptureError extends AppError {
  final String source;

  CaptureError(String message, {required this.source, StackTrace? stackTrace})
      : super(message, stackTrace: stackTrace);

  @override
  String get code => 'CAPTURE_ERROR';
}

class NetworkError extends AppError {
  final int? statusCode;

  NetworkError(String message, {this.statusCode, StackTrace? stackTrace})
      : super(message, stackTrace: stackTrace);

  @override
  String get code => 'NETWORK_ERROR';
}

class SyncError extends AppError {
  final String endpoint;

  SyncError(String message, {required this.endpoint, StackTrace? stackTrace})
      : super(message, stackTrace: stackTrace);

  @override
  String get code => 'SYNC_ERROR';
}

class PluginError extends AppError {
  final String pluginName;

  PluginError(String message,
      {required this.pluginName, StackTrace? stackTrace})
      : super(message, stackTrace: stackTrace);

  @override
  String get code => 'PLUGIN_ERROR';
}

class ResourceError extends AppError {
  ResourceError(String message, {StackTrace? stackTrace})
      : super(message, stackTrace: stackTrace);

  @override
  String get code => 'RESOURCE_ERROR';
}

class LogicError extends AppError {
  LogicError(String message, {StackTrace? stackTrace})
      : super(message, stackTrace: stackTrace);

  @override
  String get code => 'LOGIC_ERROR';
}

class AppConfig {
  static const String prodServerIP = '192.168.20.1';
  static const String devServerIP = '192.168.1.100';

  static const String prodPTZAddress = '192.168.20.15';
  static const String devPTZAddress = '192.168.1.100';

  // Backend Configuration
  static const String prodBackendUrl = 'https://api.arcontrolstudio.com';
  static const String devBackendUrl = 'http://localhost:3000';

  static const String prodBackendApiKey = 'your-production-api-key';
  static const String devBackendApiKey = 'dev-api-key-12345';

  // App Configuration
  static const String appVersion = '1.0.0';
  static const bool enableBackendLogging = false; // Set to true in production

  static bool get isProduction =>
      const bool.fromEnvironment('IS_PROD', defaultValue: false);

  static String get serverIP => isProduction ? prodServerIP : devServerIP;
  static String get nvrIp => serverIP;
  static String get ptzAddress => isProduction ? prodPTZAddress : devPTZAddress;

  static String get backendUrl => isProduction ? prodBackendUrl : devBackendUrl;
  static String get backendApiKey => isProduction ? prodBackendApiKey : devBackendApiKey;
}

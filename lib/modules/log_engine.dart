class LogEngine {
  List<String> systemLogs = [];
  List<String> streamLogs = [];
  List<String> connectionLogs = [];

  void logSystem(String msg) { systemLogs.add("[SYS] ${DateTime.now()}: $msg"); }
  void logStream(String msg) { streamLogs.add("[STR] ${DateTime.now()}: $msg"); }
  void logConnection(String msg) { connectionLogs.add("[CON] ${DateTime.now()}: $msg"); }
  void clearLogs() { systemLogs.clear(); streamLogs.clear(); connectionLogs.clear(); }
}
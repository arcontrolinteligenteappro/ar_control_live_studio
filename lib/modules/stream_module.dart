import 'dart:async';
import 'package:ar_control_live_studio/core/event_bus.dart';

class StreamEngine {
  bool isStreaming = false;
  final StreamController<Map<String, dynamic>> _statusController =
      StreamController.broadcast();
  Stream<Map<String, dynamic>> get statusStream => _statusController.stream;

  void startStream() {
    if (isStreaming) return;
    isStreaming = true;
    _statusController.add({'status': 'started', 'timestamp': DateTime.now().toIso8601String()});    AppEventBus.instance.fire(StreamStateChangedEvent(true));
  }

  void stopStream() {
    if (!isStreaming) return;
    isStreaming = false;
    _statusController.add({'status': 'stopped', 'timestamp': DateTime.now().toIso8601String()});
    AppEventBus.instance.fire(StreamStateChangedEvent(false));
  }

  void toggleStream() {
    if (isStreaming) {
      stopStream();
    } else {
      startStream();
    }
  }

  String get streamState => isStreaming ? 'LIVE' : 'IDLE';

  void dispose() {
    _statusController.close();
  }
}

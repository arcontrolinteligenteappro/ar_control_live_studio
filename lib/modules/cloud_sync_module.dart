import 'dart:async';
import 'package:ar_control_live_studio/core/event_bus.dart';

class CloudSyncEngine {
  bool isSyncActive = false;
  final StreamController<bool> _syncController = StreamController.broadcast();
  Stream<bool> get syncStream => _syncController.stream;

  Future<void> startSync() async {
    if (isSyncActive) return;
    isSyncActive = true;
    _syncController.add(true);
    AppEventBus.instance.fire(CloudSyncStatusEvent(true));
    await Future.delayed(const Duration(milliseconds: 250));
  }

  Future<void> stopSync() async {
    if (!isSyncActive) return;
    isSyncActive = false;
    _syncController.add(false);
    AppEventBus.instance.fire(CloudSyncStatusEvent(false));
    await Future.delayed(const Duration(milliseconds: 150));
  }

  Future<List<String>> discoverPeers() async {
    await Future.delayed(const Duration(milliseconds: 200));
    return ['studio-01', 'studio-02', 'engine-03'];
  }

  void dispose() {
    _syncController.close();
  }
}

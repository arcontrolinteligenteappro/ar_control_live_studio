import 'dart:async';

import 'package:ar_control_live_studio/core/event_bus.dart';

class VideoEngine {
  bool isPreviewActive = false;
  String activeSource = 'CAM1';
  final List<String> availableSources = ['CAM1', 'CAM2', 'NDI', 'REMOTE', 'GFX'];

  final StreamController<String> _sourceController = StreamController.broadcast();
  Stream<String> get sourceStream => _sourceController.stream;

  void switchSource(String source) {
    if (!availableSources.contains(source)) return;

    activeSource = source;
    isPreviewActive = true;
    _sourceController.add(activeSource);
    AppEventBus.instance.fire(CameraSourceChangedEvent(activeSource));
  }

  void stopPreview() {
    isPreviewActive = false;
  }

  bool get hasActiveSource => isPreviewActive && activeSource.isNotEmpty;

  void dispose() {
    _sourceController.close();
  }
}

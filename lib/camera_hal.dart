import 'package:camera/camera.dart';
import 'package:ar_control_live_studio/core/hal.dart';

class CameraHAL extends VideoSourceHAL {
  @override
  final String id;
  @override
  final String label;
  final CameraController? controller;

  CameraHAL({required this.id, required this.label, this.controller});

  @override
  Future<void> initialize() async {}
  
  @override
  Future<void> dispose() async {
    await controller?.dispose();
  }

  int? get textureId => controller?.cameraId; 
}
import 'dart:io';
import '../node_base.dart';
import '../../core/hal.dart';

/// CameraNode: Nodo CAMERA/CLIENT.
/// Gestiona ingestión de video desde cámaras.
class CameraNode extends NodeBase {
  final HAL _hal;

  CameraNode(String nodeId, this._hal) : super('CAMERA', nodeId);

  @override
  Future<void> initialize() async {
    await _hal.initialize();
    debugPrint('Camera Node initialized');
  }

  /// Accede a cámara específica.
  Future<void> accessCamera(int cameraId) async {
    await _hal.accessCamera(cameraId);
    // Enviar stream a ENGINE
    sendMessage('ENGINE', 'CAMERA_STREAM_START:$cameraId');
  }

  @override
  void processMessage(String message, Socket socket) {
    super.processMessage(message, socket);
    // Lógica: recibir comandos PTZ, etc.
    if (message.startsWith('PTZ:')) {
      // Parse and control
    }
  }
}
import 'dart:io';
import '../node_base.dart';

/// RemoteNode: Nodo REMOTE.
/// Control distribuido desde dispositivos remotos.
class RemoteNode extends NodeBase {
  RemoteNode(String nodeId) : super('REMOTE', nodeId);

  @override
  Future<void> initialize() async {
    debugPrint('Remote Node initialized');
  }

  /// Envía comando de control a ENGINE.
  void sendControlCommand(String command) {
    sendMessage('ENGINE', 'CONTROL:$command');
  }

  @override
  void processMessage(String message, Socket socket) {
    super.processMessage(message, socket);
    // Recibir feedback del sistema
  }
}
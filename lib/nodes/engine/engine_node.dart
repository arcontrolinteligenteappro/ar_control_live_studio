import 'dart:io';
import '../node_base.dart';
import '../../core/broadcast_master_engine.dart';

/// EngineNode: Nodo ENGINE.
/// Gestiona el BroadcastMasterEngine y coordina otros nodos.
class EngineNode extends NodeBase {
  final BroadcastMasterEngine _engine = BroadcastMasterEngine();

  EngineNode(String nodeId) : super('ENGINE', nodeId);

  @override
  Future<void> initialize() async {
    await _engine.initialize();
    debugPrint('Engine Node initialized');
  }

  /// Envía comandos a isolates via engine.
  void sendEngineCommand(String isolateType, dynamic command) {
    _engine.sendCommand(isolateType, command);
  }

  @override
  void processMessage(String message, Socket socket) {
    super.processMessage(message, socket);
    // Lógica específica: ej: route commands to isolates
    if (message.startsWith('VIDEO:')) {
      sendEngineCommand('video', message.substring(6));
    }
    // etc.
  }
}
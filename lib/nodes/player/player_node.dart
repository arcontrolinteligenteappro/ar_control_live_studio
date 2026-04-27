import 'dart:io';
import '../node_base.dart';

/// PlayerNode: Nodo PLAYER.
/// Gestiona salida de video/audio y display.
class PlayerNode extends NodeBase {
  PlayerNode(String nodeId) : super('PLAYER', nodeId);

  @override
  Future<void> initialize() async {
    debugPrint('Player Node initialized');
  }

  /// Reproduce stream.
  void playStream(String streamId) {
    debugPrint('Playing stream $streamId');
    // Lógica de reproducción
  }

  @override
  void processMessage(String message, Socket socket) {
    super.processMessage(message, socket);
    // Recibir streams del ENGINE
    if (message.startsWith('STREAM:')) {
      playStream(message.substring(7));
    }
  }
}
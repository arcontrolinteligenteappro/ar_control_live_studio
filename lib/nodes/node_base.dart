import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';

/// NodeBase: Clase base para todos los nodos.
/// Proporciona comunicación interoperable via red.
abstract class NodeBase {
  final String nodeType;
  final String nodeId;
  ServerSocket? _server;
  Map<String, Socket> _connectedNodes = {};

  NodeBase(this.nodeType, this.nodeId);

  /// Inicia el nodo y servidor de comunicación.
  Future<void> start(int port) async {
    _server = await ServerSocket.bind(InternetAddress.anyIPv4, port);
    _server!.listen(_handleConnection);
    debugPrint('$nodeType Node $nodeId started on port $port');
    await initialize();
  }

  /// Inicializa lógica específica del nodo.
  Future<void> initialize();

  /// Maneja conexiones entrantes.
  void _handleConnection(Socket socket) {
    socket.listen((data) {
      String message = utf8.decode(data);
      processMessage(message, socket);
    });
  }

  /// Procesa mensajes de otros nodos.
  void processMessage(String message, Socket socket) {
    // Placeholder: parsear y manejar comandos
    debugPrint('$nodeType received: $message');
    // Ej: if message == 'ping' send 'pong'
  }

  /// Envía mensaje a otro nodo.
  Future<void> sendMessage(String targetNodeId, String message) async {
    Socket? socket = _connectedNodes[targetNodeId];
    if (socket != null) {
      socket.write(message);
    } else {
      // Conectar si no conectado
      // Placeholder: asumir IP conocida
    }
  }

  /// Conecta a otro nodo.
  Future<void> connectToNode(String host, int port, String targetNodeId) async {
    Socket socket = await Socket.connect(host, port);
    _connectedNodes[targetNodeId] = socket;
    socket.listen((data) {
      String message = utf8.decode(data);
      processMessage(message, socket);
    });
  }

  /// Detiene el nodo.
  void stop() {
    _server?.close();
    _connectedNodes.values.forEach((s) => s.close());
    debugPrint('$nodeType Node $nodeId stopped');
  }
}
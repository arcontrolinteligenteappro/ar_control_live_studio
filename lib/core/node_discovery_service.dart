import 'dart:convert';
import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

const int _discoveryPort = 8888;

/// Información de un nodo descubierto en la red.
class NodeInfo {
  final String nodeType;
  final String ipAddress;
  final String status;
  final DateTime lastSeen;

  NodeInfo({
    required this.nodeType,
    required this.ipAddress,
    required this.status,
    required this.lastSeen,
  });

  factory NodeInfo.fromJson(Map<String, dynamic> json, String sourceIp) {
    return NodeInfo(
      // La IP se toma del datagrama, no del JSON, por seguridad y precisión.
      ipAddress: sourceIp,
      nodeType: json['node_type'] ?? 'unknown',
      status: json['status'] ?? 'offline',
      lastSeen: DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'node_type': nodeType,
        // La IP en el JSON es informativa, pero no se debe confiar en ella al recibir.
        'ip_address': ipAddress,
        'status': status,
      };
}

/// Servicio para descubrir otros nodos de AR Control en la red local.
/// Usa broadcast UDP para enviar y recibir anuncios.
class NodeDiscoveryService {
  RawDatagramSocket? _socket;
  final StreamController<NodeInfo> _discoveredNodesController = StreamController.broadcast();

  /// Stream de nodos descubiertos.
  Stream<NodeInfo> get discoveredNodes => _discoveredNodesController.stream;

  /// Inicia el servicio, escuchando en el puerto de descubrimiento.
  Future<void> start() async {
    if (_socket != null) return;

    try {
      _socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, _discoveryPort);
      _socket?.broadcastEnabled = true;
      _socket?.listen((RawSocketEvent event) {
        if (event == RawSocketEvent.read) {
          final datagram = _socket?.receive();
          if (datagram == null) return;

          try {
            final message = utf8.decode(datagram.data);
            final json = jsonDecode(message);
            final nodeInfo = NodeInfo.fromJson(json, datagram.address.address);
            _discoveredNodesController.add(nodeInfo);
          } catch (e) {
            debugPrint('Error decodificando el paquete de descubrimiento: $e');
          }
        }
      });
      debugPrint('NodeDiscoveryService iniciado en el puerto $_discoveryPort');
    } catch (e) {
      debugPrint('Error al iniciar NodeDiscoveryService: $e');
    }
  }

  /// Envía un paquete de broadcast para anunciar este nodo.
  void broadcastPresence(String nodeType, String status) {
    if (_socket == null) return;

    final payload = jsonEncode({'node_type': nodeType, 'status': status});
    _socket?.send(utf8.encode(payload), InternetAddress('255.255.255.255'), _discoveryPort);
  }

  /// Envía un mensaje directo a una lista específica de nodos.
  void sendDirectMessage(List<NodeInfo> nodes, String message) {
    if (_socket == null) return;

    final payload = utf8.encode(message);
    for (final node in nodes) {
      try {
        _socket?.send(payload, InternetAddress(node.ipAddress), _discoveryPort);
      } catch (e) {
        debugPrint('Error enviando mensaje directo a ${node.ipAddress}: $e');
      }
    }
  }

  /// Detiene el servicio y cierra el socket.
  void stop() {
    _socket?.close();
    _socket = null;
    _discoveredNodesController.close();
    debugPrint('NodeDiscoveryService detenido.');
  }
}

/// Provider global para el NodeDiscoveryService.
final nodeDiscoveryProvider = Provider<NodeDiscoveryService>((ref) {
  final service = NodeDiscoveryService();
  ref.onDispose(() => service.stop());
  return service;
});
import 'dart:async';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart'; // FIX: Import vital para que debugPrint funcione

class RemoteNode {
  final String id;
  final String ip;
  final String name;
  final String type; // 'camera', 'drone', 'audio_source'

  RemoteNode({required this.id, required this.ip, required this.name, required this.type});
}

class NodeDiscoveryService extends StateNotifier<List<RemoteNode>> {
  NodeDiscoveryService() : super([]) {
    // Simulación de escaneo de red local (UDP/mDNS)
    startDiscovery();
  }

  // Tarea 3: Rellenar los Métodos de Nodos Faltantes
  List<RemoteNode> get discoveredNodes => state;

  void start() {
    startDiscovery();
  }

  void broadcastPresence() {
    debugPrint("Broadcasting presence...");
  }

  void sendDirectMessage(String ipAddress, String msg) {
    debugPrint("Sending direct message: $msg to ip: $ipAddress");
  }

  // Simulación de escaneo de red local (UDP/mDNS)
  void startDiscovery() {
    // Aquí iría tu lógica de búsqueda de IPs en la red de AR Control
    state = [
      RemoteNode(id: 'cam_wifi_01', ip: '192.168.1.50', name: 'CAM ACAPONETA', type: 'camera'),
      RemoteNode(id: 'drone_01', ip: '192.168.1.60', name: 'DRONE 4K', type: 'drone'),
    ];
  }
  
  void addNode(RemoteNode node) {
    if (!state.any((n) => n.id == node.id)) {
      state = [...state, node];
    }
  }
}

final nodeDiscoveryProvider = StateNotifierProvider<NodeDiscoveryService, List<RemoteNode>>((ref) {
  return NodeDiscoveryService();
});
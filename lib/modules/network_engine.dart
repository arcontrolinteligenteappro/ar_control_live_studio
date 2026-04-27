import 'dart:io';
import 'dart:convert';

class NetworkEngine {
  String localIp = "127.0.0.1";
  bool isCloudSyncActive = false;
  RawDatagramSocket? _socket;

  Future<void> startDiscovery() async {
    try {
      _socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 8888);
      _socket?.broadcastEnabled = true;
      String msg = jsonEncode({'cmd': 'DISCOVER', 'role': 'engine'});
      _socket?.send(utf8.encode(msg), InternetAddress('255.255.255.255'), 8888);
    } catch (e) {
      // Fallback a modo local
    }
  }
  void connectClient(String ip) {}
  void dispose() { _socket?.close(); }
}
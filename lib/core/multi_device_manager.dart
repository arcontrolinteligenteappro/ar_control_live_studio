import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';

/// MultiDeviceManager: Gestiona soporte multi-dispositivo.
/// Permite conectar y controlar múltiples dispositivos remotos.
/// Extiende interoperabilidad de nodos.
class MultiDeviceManager {
  static final MultiDeviceManager _instance = MultiDeviceManager._internal();

  factory MultiDeviceManager() => _instance;

  MultiDeviceManager._internal();

  ServerSocket? _server;
  Map<String, Socket> _connectedDevices = {};

  /// Inicia servidor para dispositivos remotos.
  Future<void> startServer(int port) async {
    _server = await ServerSocket.bind(InternetAddress.anyIPv4, port);
    _server!.listen(_handleDeviceConnection);
    debugPrint('Multi-device server started on port $port');
  }

  /// Maneja conexión de dispositivo.
  void _handleDeviceConnection(Socket socket) {
    String deviceId = 'device_${_connectedDevices.length}';
    _connectedDevices[deviceId] = socket;
    socket.listen((data) {
      String message = utf8.decode(data);
      _processDeviceMessage(deviceId, message);
    });
    debugPrint('Device $deviceId connected');
  }

  /// Procesa mensaje de dispositivo.
  void _processDeviceMessage(String deviceId, String message) {
    debugPrint('Message from $deviceId: $message');
    // Ej: route to engines
  }

  /// Envía comando a dispositivo específico.
  void sendCommandToDevice(String deviceId, String command) {
    Socket? socket = _connectedDevices[deviceId];
    if (socket != null) {
      socket.write(command);
    }
  }

  /// Envía comando a todos los dispositivos.
  void broadcastCommand(String command) {
    _connectedDevices.values.forEach((socket) {
      socket.write(command);
    });
  }

  /// Lista dispositivos conectados.
  List<String> getConnectedDevices() {
    return _connectedDevices.keys.toList();
  }

  /// Desconecta dispositivo.
  void disconnectDevice(String deviceId) {
    _connectedDevices[deviceId]?.close();
    _connectedDevices.remove(deviceId);
  }

  /// Detiene servidor.
  void stopServer() {
    _server?.close();
    _connectedDevices.values.forEach((s) => s.close());
    _connectedDevices.clear();
  }
}
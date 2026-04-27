import 'dart:async';
import 'package:flutter/foundation.dart';

class DroneEngine {
  bool connected = false;
  String model = 'NONE';
  String ip = '0.0.0.0';
  double altitude = 0.0;
  double speed = 0.0;
  double battery = 100.0;
  String status = 'idle';

  final StreamController<Map<String, dynamic>> _telemetryController = StreamController.broadcast();
  Stream<Map<String, dynamic>> get telemetryStream => _telemetryController.stream;

  void connectDrone(String ipAddress) {
    ip = ipAddress;
    connected = true;
    model = 'DJI_LINK_ACTIVE';
    status = 'connected';
    _notifyTelemetry();
    if (kDebugMode) {
      debugPrint('Drone connected at $ipAddress');
    }
  }

  void disconnectDrone() {
    connected = false;
    model = 'NONE';
    status = 'disconnected';
    _notifyTelemetry();
  }

  void sendMovementCommand(double pitch, double roll, double yaw, double throttle) {
    if (!connected) return;
    altitude += throttle * 0.1;
    speed = (pitch.abs() + roll.abs() + yaw.abs()) * 0.5;
    status = 'flying';
    _sendDroneCommand('MOVE', {'pitch': pitch, 'roll': roll, 'yaw': yaw, 'throttle': throttle});
    _notifyTelemetry();
  }

  void tiltCamera(double angle) {
    if (!connected) return;
    _sendDroneCommand('TILT_CAMERA', {'angle': angle});
  }

  void returnHome() {
    if (!connected) return;
    status = 'returning';
    _sendDroneCommand('RETURN_HOME', {});
    _notifyTelemetry();
  }

  void emergencyLand() {
    if (!connected) return;
    status = 'emergency_land';
    _sendDroneCommand('EMERGENCY_LAND', {});
    _notifyTelemetry();
  }

  void _sendDroneCommand(String command, Map<String, dynamic> params) {
    if (kDebugMode) {
      debugPrint('DRONE CMD -> $command $params');
    }
  }

  void _notifyTelemetry() {
    _telemetryController.add({
      'connected': connected,
      'model': model,
      'ip': ip,
      'altitude': altitude,
      'speed': speed,
      'battery': battery,
      'status': status,
    });
  }

  void dispose() {
    _telemetryController.close();
  }
}
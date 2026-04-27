import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:ar_control_live_studio/config/app_config.dart';
import 'package:ar_control_live_studio/core/event_bus.dart';
import 'package:ar_control_live_studio/services/platform_service.dart';

class HardwareEngine {
  bool ptzConnected = false;
  bool midiConnected = false;
  bool gamepadConnected = false;
  bool nativeBridgeAvailable = false;
  String ptzAddress = AppConfig.ptzAddress;
  double panPosition = 0.0;
  double tiltPosition = 0.0;
  double zoomLevel = 1.0;
  final Map<String, bool> deviceStatus = {};

  final StreamController<Map<String, dynamic>> _statusController = StreamController.broadcast();
  Stream<Map<String, dynamic>> get statusStream => _statusController.stream;

  Future<void> scanControllers() async {
    nativeBridgeAvailable = await PlatformService.isPlatformAvailable();
    ptzConnected = nativeBridgeAvailable;
    midiConnected = true;
    gamepadConnected = true;
    deviceStatus['PTZ'] = ptzConnected;
    deviceStatus['MIDI'] = midiConnected;
    deviceStatus['Gamepad'] = gamepadConnected;
    deviceStatus['NativeBridge'] = nativeBridgeAvailable;
    _notifyStatus();

    if (ptzConnected) {
      await connectToPTZ();
    }
  }

  Future<bool> connectToPTZ({String? address, int? port}) async {
    try {
      final result = await PlatformService.connectPTZ(
        address ?? ptzAddress,
        port ?? 5678
      );
      ptzConnected = result['connected'] as bool? ?? false;
      if (ptzConnected) {
        ptzAddress = result['address'] as String? ?? ptzAddress;
        await refreshPTZStatus();
      }
      deviceStatus['PTZ'] = ptzConnected;
      _notifyStatus();
      return ptzConnected;
    } catch (e) {
      ptzConnected = false;
      deviceStatus['PTZ'] = false;
      _notifyStatus();
      return false;
    }
  }

  void connectPTZ(String address) {
    ptzAddress = address;
    connectToPTZ(address: address);
  }

  Future<void> disconnectFromPTZ() async {
    try {
      await PlatformService.disconnectPTZ();
    } catch (e) {
      // Ignore errors during disconnect
    }
    ptzConnected = false;
    deviceStatus['PTZ'] = false;
    _notifyStatus();
  }

  void disconnectPTZ() {
    disconnectFromPTZ();
  }

  void panPTZ(double x) {
    if (!ptzConnected) return;
    panPosition = x.clamp(-180.0, 180.0);
    final command = x > 0 ? 'PAN_RIGHT' : 'PAN_LEFT';
    final speed = (x.abs() * 10).toInt().clamp(1, 24); // VISCA speed 1-24
    _sendPTZCommand(command, speed.toDouble());
    _notifyStatus();
  }

  void tiltPTZ(double y) {
    if (!ptzConnected) return;
    tiltPosition = y.clamp(-90.0, 90.0);
    final command = y > 0 ? 'TILT_UP' : 'TILT_DOWN';
    final speed = (y.abs() * 10).toInt().clamp(1, 20); // VISCA speed 1-20
    _sendPTZCommand(command, speed.toDouble());
    _notifyStatus();
  }

  void zoomPTZ(double z) {
    if (!ptzConnected) return;
    zoomLevel = z.clamp(1.0, 20.0);
    final command = z > zoomLevel ? 'ZOOM_IN' : 'ZOOM_OUT';
    final speed = ((z - zoomLevel).abs() * 7).toInt().clamp(0, 7); // VISCA zoom speed 0-7
    _sendPTZCommand(command, speed.toDouble());
    _notifyStatus();
  }

  void stopPTZ() {
    if (!ptzConnected) return;
    _sendPTZCommand('STOP', 0.0);
  }

  void recallPreset(int preset) {
    if (!ptzConnected) return;
    _sendPTZCommand('RECALL_PRESET', preset);
  }

  void savePreset(int preset) {
    if (!ptzConnected) return;
    _sendPTZCommand('SAVE_PRESET', preset);
  }

  void sendMidiNote(int note, int velocity) {
    if (!midiConnected) return;
    if (kDebugMode) {
      debugPrint('MIDI NOTE: $note velocity=$velocity');
    }
  }

  void sendGamepadCommand(String command) {
    if (!gamepadConnected) return;
    if (kDebugMode) {
      debugPrint('GAMEPAD CMD: $command');
    }
  }

  Future<void> _sendPTZCommand(String command, dynamic value) async {
    if (kDebugMode) {
      debugPrint('PTZ CMD -> $command: $value @ $ptzAddress');
    }

    try {
      await PlatformService.sendPTZCommand(command, value);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('PlatformService PTZ command failed: $e');
      }
    }
  }

  Future<Map<String, dynamic>> fetchPTZStatus() async {
    try {
      return await PlatformService.getPTZStatus();
    } catch (_) {
      return {
        'ptzConnected': ptzConnected,
        'pan': panPosition,
        'tilt': tiltPosition,
        'zoom': zoomLevel,
        'address': ptzAddress,
      };
    }
  }

  Future<void> refreshPTZStatus() async {
    final status = await fetchPTZStatus();
    ptzConnected = status['ptzConnected'] as bool? ?? ptzConnected;
    panPosition = (status['pan'] as num?)?.toDouble() ?? panPosition;
    tiltPosition = (status['tilt'] as num?)?.toDouble() ?? tiltPosition;
    zoomLevel = (status['zoom'] as num?)?.toDouble() ?? zoomLevel;
    ptzAddress = status['address'] as String? ?? ptzAddress;
    deviceStatus['PTZ'] = ptzConnected;
    _notifyStatus();
  }

  void _notifyStatus() {
    final status = {
      'ptzConnected': ptzConnected,
      'midiConnected': midiConnected,
      'gamepadConnected': gamepadConnected,
      'pan': panPosition,
      'tilt': tiltPosition,
      'zoom': zoomLevel,
      'address': ptzAddress,
    };
    
    _statusController.add(status);
    
    AppEventBus.instance.fire(PTZStatusChangedEvent(
      connected: ptzConnected,
      pan: panPosition,
      tilt: tiltPosition,
      zoom: zoomLevel,
      address: ptzAddress,
    ));
  }

  void dispose() {
    _statusController.close();
  }
}
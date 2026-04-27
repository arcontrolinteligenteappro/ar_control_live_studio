import 'package:flutter/foundation.dart';
import '../hal.dart'; 

/// PTZController: Controlador para cámaras PTZ.
/// Utiliza HAL para abstracción de hardware.
class PTZController {
  final HAL _hal;

  PTZController(this._hal);

  double _pan = 0.0;
  double _tilt = 0.0;
  double _zoom = 1.0;

  /// Mueve la cámara a posición específica.
  Future<void> moveTo({required double pan, required double tilt, required double zoom}) async {
    _pan = pan.clamp(-180.0, 180.0);
    _tilt = tilt.clamp(-90.0, 90.0);
    _zoom = zoom.clamp(1.0, 30.0);
    await _hal.controlPTZ(pan: _pan, tilt: _tilt, zoom: _zoom);
  }

  /// Pan relativo.
  Future<void> pan(double delta) async {
    _pan = (_pan + delta).clamp(-180.0, 180.0);
    await _hal.controlPTZ(pan: _pan, tilt: _tilt, zoom: _zoom);
  }

  /// Tilt relativo.
  Future<void> tilt(double delta) async {
    _tilt = (_tilt + delta).clamp(-90.0, 90.0);
    await _hal.controlPTZ(pan: _pan, tilt: _tilt, zoom: _zoom);
  }

  /// Zoom relativo.
  Future<void> zoom(double factor) async {
    _zoom = (_zoom * factor).clamp(1.0, 30.0);
    await _hal.controlPTZ(pan: _pan, tilt: _tilt, zoom: _zoom);
  }

  /// Preset positions.
  Future<void> goToPreset(int preset) async {
    // Placeholder: definir presets
    debugPrint('Going to preset $preset');
  }

  /// Estado actual.
  Map<String, double> getPosition() {
    return {'pan': _pan, 'tilt': _tilt, 'zoom': _zoom};
  }
}
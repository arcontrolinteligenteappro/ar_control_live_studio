import 'package:flutter/material.dart';
import 'package:ar_control_live_studio/core/ptz_controller.dart';
import 'package:ar_control_live_studio/core/hal.dart';
import 'package:ar_control_live_studio/core/theme/cyberpunk_theme.dart';

/// PTZControl: Control de PTZ.
/// Sliders para pan, tilt, zoom.
class PTZControl extends StatefulWidget {
  const PTZControl({super.key});

  @override
  _PTZControlState createState() => _PTZControlState();
}

class _PTZControlState extends State<PTZControl> {
  // Nota: Si PTZController o HALFactory marcan error, es porque falta conectarlos
  // a la arquitectura de Riverpod. Por ahora lo dejamos como lo tenías.
  late PTZController _ptz;
  double _pan = 0.0;
  double _tilt = 0.0;
  double _zoom = 1.0;

  @override
  void initState() {
    super.initState();
    // Asumiendo que HALFactory existe en tu core
    _ptz = PTZController(HALFactory.create());
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: CyberpunkTheme.cyanNeon.withOpacity(0.5)),
        color: CyberpunkTheme.panel,
      ),
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('>> PTZ_HARDWARE_LINK', style: CyberpunkTheme.terminalStyle.copyWith(color: CyberpunkTheme.cyanNeon, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          _buildSlider('PAN', _pan, -180.0, 180.0, (val) {
            setState(() => _pan = val);
            _ptz.moveTo(pan: _pan, tilt: _tilt, zoom: _zoom);
          }),
          _buildSlider('TILT', _tilt, -90.0, 90.0, (val) {
            setState(() => _tilt = val);
            _ptz.moveTo(pan: _pan, tilt: _tilt, zoom: _zoom);
          }),
          _buildSlider('ZOOM', _zoom, 1.0, 30.0, (val) {
            setState(() => _zoom = val);
            _ptz.moveTo(pan: _pan, tilt: _tilt, zoom: _zoom);
          }),
        ],
      ),
    );
  }

  Widget _buildSlider(String label, double value, double min, double max, ValueChanged<double> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$label: ${value.toStringAsFixed(1)}', style: CyberpunkTheme.terminalStyle),
        const SizedBox(height: 4),
        SizedBox(
          height: 20,
          child: _HorizontalFader(
            value: (value - min) / (max - min),
            onChanged: (percentage) {
              onChanged(min + percentage * (max - min));
            },
            color: CyberpunkTheme.cyanNeon,
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

class _HorizontalFader extends StatelessWidget {
  final double value;
  final Function(double) onChanged;
  final Color color;

  const _HorizontalFader({required this.value, required this.onChanged, required this.color});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onHorizontalDragUpdate: (details) {
        final RenderBox renderBox = context.findRenderObject() as RenderBox;
        final localPosition = details.localPosition;
        final double newValue = (localPosition.dx / renderBox.size.width).clamp(0.0, 1.0);
        onChanged(newValue);
      },
      child: Container(
        decoration: BoxDecoration(
          color: CyberpunkTheme.panel,
          border: Border.all(color: color.withOpacity(0.5)),
        ),
        child: FractionallySizedBox(
          alignment: Alignment.centerLeft,
          widthFactor: value,
          child: Container(
            color: color,
          ),
        ),
      ),
    );
  }
}
import 'package:flutter/material.dart';
import '../../core/thermal_manager.dart';
import '../../core/theme/cyberpunk_theme.dart';

/// ThermalControl: Monitoreo térmico.
/// Muestra temperatura actual.
class ThermalControl extends StatefulWidget {
  const ThermalControl({super.key});

  @override
  _ThermalControlState createState() => _ThermalControlState();
}

class _ThermalControlState extends State<ThermalControl> {
  final ThermalManager _thermal = ThermalManager();
  double _temp = 0.0;

  @override
  void initState() {
    super.initState();
    _updateTemp();
  }

  void _updateTemp() {
    setState(() => _temp = _thermal.getCurrentTemp());
    Future.delayed(const Duration(seconds: 1), _updateTemp);
  }

  @override
  Widget build(BuildContext context) {
    final tempColor = _temp < 60 ? CyberpunkTheme.cyanNeon : (_temp < 80 ? Colors.orangeAccent : const Color(0xFFFF0000));

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: tempColor.withOpacity(0.5)),
        color: CyberpunkTheme.panel,
      ),
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('THERMAL_CORE', style: CyberpunkTheme.terminalStyle.copyWith(color: tempColor)),
          const SizedBox(height: 8),
          Text('${_temp.toStringAsFixed(1)}°C', style: CyberpunkTheme.terminalStyle.copyWith(color: tempColor, fontSize: 28, fontWeight: FontWeight.bold, shadows: [Shadow(color: tempColor, blurRadius: 10)])),
        ],
      ),
    );
  }
}
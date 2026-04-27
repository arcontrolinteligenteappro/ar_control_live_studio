import 'package:flutter/material.dart';
import '../../core/dj_engine.dart';
import '../../core/theme/cyberpunk_theme.dart';

/// DJControl: Control de DJ.
/// Controles para crossfader, volumen, efectos.
class DJControl extends StatefulWidget {
  const DJControl({super.key});

  @override
  _DJControlState createState() => _DJControlState();
}

class _DJControlState extends State<DJControl> {
  final DJEngine _dj = DJEngine();
  double _crossfader = 0.5;
  double _masterVolume = 1.0;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: CyberpunkTheme.magentaNeon.withOpacity(0.5)),
        color: CyberpunkTheme.panel,
      ),
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('>> DJ_AUDIO_ENGINE', style: CyberpunkTheme.terminalStyle.copyWith(color: CyberpunkTheme.magentaNeon, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          _buildSlider('X-FADER', _crossfader, 0.0, 1.0, (val) {
            setState(() => _crossfader = val);
            _dj.setCrossfader(_crossfader);
          }),
          _buildSlider('MASTER', _masterVolume, 0.0, 1.0, (val) {
            setState(() => _masterVolume = val);
            _dj.setMasterVolume(_masterVolume);
          }),
          const Spacer(),
          Row(
            children: [
              Expanded(child: _actionButton('PLAY_A', () => _dj.play('deck1'), color: CyberpunkTheme.cyanNeon)),
              const SizedBox(width: 12),
              Expanded(child: _actionButton('PAUSE_A', () => _dj.pause('deck1'), color: CyberpunkTheme.textMain)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSlider(String label, double value, double min, double max, ValueChanged<double> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$label: ${(value * 100).toStringAsFixed(0)}%', style: CyberpunkTheme.terminalStyle),
        const SizedBox(height: 4),
        SizedBox(
          height: 20,
          child: _HorizontalFader(
            value: (value - min) / (max - min),
            onChanged: (percentage) {
              onChanged(min + percentage * (max - min));
            },
            color: CyberpunkTheme.magentaNeon,
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _actionButton(String label, VoidCallback onTap, {required Color color}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(border: Border.all(color: color), color: color.withOpacity(0.1)),
        alignment: Alignment.center,
        child: Text(label, style: CyberpunkTheme.terminalStyle.copyWith(color: color, fontWeight: FontWeight.bold)),
      ),
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
        decoration: BoxDecoration(color: CyberpunkTheme.panel, border: Border.all(color: color.withOpacity(0.5))),
        child: FractionallySizedBox(alignment: Alignment.centerLeft, widthFactor: value, child: Container(color: color)),
      ),
    );
  }
}
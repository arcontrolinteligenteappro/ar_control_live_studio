import 'package:flutter/material.dart';
import 'package:ar_control_live_studio/core/theme/cyberpunk_theme.dart';

class DJProModule extends StatefulWidget {
  const DJProModule({super.key});

  @override
  State<DJProModule> createState() => _DJProModuleState();
}

class _DJProModuleState extends State<DJProModule> {
  double _crossfaderPosition = 0.5;
  double _deck1Volume = 0.7;
  double _deck2Volume = 0.7;
  double _eqBass = 0.0;
  double _eqMid = 0.0;
  double _eqTreble = 0.0;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: CyberpunkTheme.background,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Text(
            'DJ PRO - VIRTUAL MIXER',
            style: CyberpunkTheme.terminalStyle.copyWith(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const Divider(color: CyberpunkTheme.cyanNeon, height: 30),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildDeck('DECK 1', _deck1Volume, (val) {
                setState(() => _deck1Volume = val);
              }),
              _buildCrossfader(),
              _buildDeck('DECK 2', _deck2Volume, (val) {
                setState(() => _deck2Volume = val);
              }),
            ],
          ),
          const SizedBox(height: 30),
          Text(
            'EQ CONTROLS',
            style: CyberpunkTheme.terminalStyle.copyWith(color: CyberpunkTheme.magentaNeon),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildEQSlider('BASS', _eqBass, (val) {
                setState(() => _eqBass = val);
              }),
              _buildEQSlider('MID', _eqMid, (val) {
                setState(() => _eqMid = val);
              }),
              _buildEQSlider('TREBLE', _eqTreble, (val) {
                setState(() => _eqTreble = val);
              }),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDeck(String label, double volume, Function(double) onChanged) {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: CyberpunkTheme.panel,
            border: Border.all(
              color: CyberpunkTheme.cyanNeon,
              width: 2,
            ),
            borderRadius: BorderRadius.zero, // Bordes angulares requeridos
            boxShadow: const [BoxShadow(color: CyberpunkTheme.cyanNeon, blurRadius: 8, spreadRadius: 1)],
          ),
          child: Center(
            child: Text(
              label,
              style: CyberpunkTheme.terminalStyle.copyWith(color: CyberpunkTheme.background, backgroundColor: CyberpunkTheme.cyanNeon),
            ),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: 100,
          height: 30,
          child: _HorizontalFader(value: volume, onChanged: onChanged, color: CyberpunkTheme.cyanNeon),
        ),
        Text(
          '${(volume * 100).toStringAsFixed(0)}%',
          style: CyberpunkTheme.terminalStyle,
        ),
      ],
    );
  }

  Widget _buildCrossfader() {
    return Column(
      children: [
        Text(
          'CROSS',
          style: CyberpunkTheme.terminalStyle,
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 100,
          width: 40,
          child: VerticalSlider(
            value: _crossfaderPosition,
            color: CyberpunkTheme.magentaNeon,
            onChanged: (val) {
              setState(() => _crossfaderPosition = val);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildEQSlider(String label, double value, Function(double) onChanged) {
    return Column(
      children: [
        Text(
          label,
          style: CyberpunkTheme.terminalStyle.copyWith(fontSize: 10),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 80,
          child: VerticalSlider(
            value: (value + 1) / 2,
            color: CyberpunkTheme.cyanNeon,
            onChanged: (val) {
              onChanged(val * 2 - 1);
            },
          ),
        ),
      ],
    );
  }
}

/// Custom Horizontal Fader (Reemplazo estricto del Slider de Material)
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

class VerticalSlider extends StatelessWidget {
  final double value;
  final Function(double) onChanged;
  final Color color;

  const VerticalSlider({
    required this.value,
    required this.onChanged,
    required this.color,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onVerticalDragUpdate: (details) {
        final RenderBox renderBox = context.findRenderObject() as RenderBox;
        final localPosition = details.localPosition;
        final double newValue =
            1 - (localPosition.dy / renderBox.size.height).clamp(0.0, 1.0);
        onChanged(newValue);
      },
      child: Container(
        width: 40,
        decoration: BoxDecoration(
          color: CyberpunkTheme.panel,
          border: Border.all(color: color.withOpacity(0.5)),
          borderRadius: BorderRadius.zero, // Estilo terminal, nada redondeado
        ),
        child: Stack(
          children: [
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              height: (value * 100).toInt().toDouble(),
              child: Container(
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
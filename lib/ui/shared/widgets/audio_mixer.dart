import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ar_control_live_studio/core/audio_engine.dart';
import 'package:ar_control_live_studio/core/switcher_engine.dart';
import 'package:ar_control_live_studio/core/theme/cyberpunk_theme.dart';

class AudioMixer extends ConsumerWidget { 
  const AudioMixer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final audioSources = ref.watch(audioEngineProvider);
    final audioNotifier = ref.read(audioEngineProvider.notifier);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: CyberpunkTheme.panel.withOpacity(0.8),
        border: Border.all(color: CyberpunkTheme.neonPurple, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '>> AUDIO_MIXER',
            style: CyberpunkTheme.terminalStyle.copyWith(color: CyberpunkTheme.magentaNeon),
          ),
          const Divider(color: CyberpunkTheme.neonPurple),
          if (audioSources.isEmpty)
            Expanded(
              child: Center(
                child: Text(
                  'NO AUDIO SOURCES DETECTED',
                  style: CyberpunkTheme.terminalStyle.copyWith(color: Colors.grey),
                ),
              ),
            )
          else
            Expanded(
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: audioSources.length,
                itemBuilder: (context, index) {
                  final source = audioSources[index];
                  return _AudioFader(
                    source: source,
                    onVolumeChanged: (volume) {
                      audioNotifier.setVolume(source.id, volume);
                    },
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _AudioFader extends ConsumerStatefulWidget {
  final AudioSource source;
  final ValueChanged<double> onVolumeChanged;

  const _AudioFader({required this.source, required this.onVolumeChanged});

  @override
  ConsumerState<_AudioFader> createState() => _AudioFaderState();
}

class _AudioFaderState extends ConsumerState<_AudioFader> {
  Timer? _vuMeterSimulator;
  final _vuLevel = ValueNotifier<double>(0.0);

  @override
  void initState() {
    super.initState();
    // Simula la actividad del medidor VU. En una implementación real,
    // esto se conectaría a un AnalyserNode de Web Audio o un procesador de audio nativo.
    _vuMeterSimulator = Timer.periodic(const Duration(milliseconds: 150), (timer) {
      if (mounted) {
        final isProgram = ref.read(switcherEngineProvider).programSourceId == widget.source.id;
        // Si es la fuente en programa, simula nivel de audio. Si no, es 0.0.
        _vuLevel.value = isProgram ? 0.5 + (DateTime.now().millisecond % 400) / 800.0 : 0.0;
      }
    });
  }

  @override
  void dispose() {
    _vuMeterSimulator?.cancel();
    _vuLevel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 80,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(widget.source.id.toUpperCase(), style: CyberpunkTheme.terminalStyle.copyWith(fontSize: 10, color: CyberpunkTheme.cyanNeon), overflow: TextOverflow.ellipsis),
          const SizedBox(height: 8),
          Expanded(
            child: ValueListenableBuilder<double>(
              valueListenable: _vuLevel,
              builder: (context, level, child) {
                return CustomPaint(
                  painter: _VuMeterPainter(level: level),
                  child: const SizedBox.expand(),
                );
              },
            ),
          ),
          SizedBox(
            height: 120,
            child: RotatedBox(quarterTurns: -1, child: SliderTheme(data: SliderTheme.of(context).copyWith(trackHeight: 4.0, thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8.0), overlayShape: const RoundSliderOverlayShape(overlayRadius: 16.0), activeTrackColor: CyberpunkTheme.neonCyan, inactiveTrackColor: CyberpunkTheme.darkGrey, thumbColor: CyberpunkTheme.neonPurple), child: Slider(value: widget.source.volume, min: 0.0, max: 1.0, onChanged: widget.onVolumeChanged))),
          ),
          const SizedBox(height: 8),
          Text('${(widget.source.volume * 100).toStringAsFixed(0)}%', style: CyberpunkTheme.terminalStyle.copyWith(fontSize: 12, color: Colors.white)),
        ],
      ),
    );
  }
}

class _VuMeterPainter extends CustomPainter {
  final double level; // 0.0 a 1.0
  _VuMeterPainter({required this.level});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    const barCount = 12;
    final barHeight = size.height / barCount;
    final activeBars = (level * barCount).ceil();

    for (int i = 0; i < barCount; i++) {
      final isLit = i < activeBars;
      final color = i < 8 ? CyberpunkTheme.terminalGreen : (i < 10 ? Colors.yellowAccent : CyberpunkTheme.errorRed);
      paint.color = isLit ? color : color.withOpacity(0.2);
      canvas.drawRect(Rect.fromLTWH(0, size.height - (i + 1) * barHeight, size.width, barHeight - 2), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _VuMeterPainter oldDelegate) => level != oldDelegate.level;
}
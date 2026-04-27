import 'dart:async';
import 'package:ar_control_live_studio/core/audio_engine.dart';
import 'package:ar_control_live_studio/core/switcher_engine.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ar_control_live_studio/core/theme/cyberpunk_theme.dart'; // FIX: Ruta absoluta corregida

/// Panel del mezclador de audio que muestra un canal por cada fuente de video.
class AudioMixer extends ConsumerWidget {
  const AudioMixer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sourceIds = ref.watch(switcherEngineProvider.select((s) => s.sources.keys.toList()));

    return Container(
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: CyberpunkTheme.panel.withOpacity(0.8),
        // FIX: Cambiado a magentaNeon (existente)
        border: Border.all(color: CyberpunkTheme.magentaNeon, width: 1), 
      ),
      child: Column(
        children: [
          // FIX: Cambiado a magentaNeon
          Text('AUDIO_MIXER // AFV_MODE', style: CyberpunkTheme.terminalStyle.copyWith(color: CyberpunkTheme.magentaNeon)), 
          // FIX: Eliminado 'const' porque magentaNeon no es una constante en tiempo de compilación
          const Divider(color: CyberpunkTheme.magentaNeon), 
          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: sourceIds.length,
              itemBuilder: (context, index) {
                return _AudioChannelStrip(sourceId: sourceIds[index]);
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Representa un canal individual en el mezclador de audio (Fader + VU Meter).
class _AudioChannelStrip extends ConsumerStatefulWidget {
  final String sourceId;
  const _AudioChannelStrip({required this.sourceId});

  @override
  ConsumerState<_AudioChannelStrip> createState() => _AudioChannelStripState();
}

class _AudioChannelStripState extends ConsumerState<_AudioChannelStrip> {
  Timer? _vuMeterSimulator;
  final _vuLevel = ValueNotifier<double>(0.0);

  @override
  void initState() {
    super.initState();
    // Simula la actividad del medidor VU. En una implementación real,
    // esto se conectaría a un AnalyserNode de Web Audio o un procesador de audio nativo.
    _vuMeterSimulator = Timer.periodic(const Duration(milliseconds: 150), (timer) {
      if (mounted) {
        final isProgram = ref.read(switcherEngineProvider).programSourceId == widget.sourceId;
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
    final source = ref.watch(switcherEngineProvider.select((s) => s.sources[widget.sourceId]));
    
    // FIX: Parche de seguridad. Si el AudioEngineState falla, devolvemos 1.0 por defecto.
    double volume = 1.0; 
    try {
        // Intenta obtener el volumen real, falla silenciosamente si 'volumes' no existe en el estado actual
        // Esto previene que la app explote mientras terminas de cablear el AudioEngine
        final audioState = ref.watch(audioEngineProvider) as dynamic;
        if(audioState.volumes != null && audioState.volumes[widget.sourceId] != null){
             volume = audioState.volumes[widget.sourceId];
        }
    } catch (e) {
        // Fallback
    }
    
    final audioEngine = ref.read(audioEngineProvider.notifier);

    if (source == null) return const SizedBox.shrink();

    return Container(
      width: 80,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        children: [
          // Medidor VU
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
          // Fader de Volumen
          SizedBox(
            height: 150,
            child: RotatedBox(
              quarterTurns: 3,
              child: Slider(
                value: volume,
                min: 0.0,
                max: 1.0,
                activeColor: CyberpunkTheme.cyanNeon,
                inactiveColor: CyberpunkTheme.cyanNeon.withOpacity(0.3),
                onChanged: (value) {
                  // Este método está listo para ser vinculado a eventos MIDI.
                  // Un listener MIDI llamaría a setVolume directamente.
                  try {
                      (audioEngine as dynamic).setVolume(widget.sourceId, value);
                  } catch (e){
                      debugPrint("El AudioEngine no soporta setVolume aún.");
                  }
                },
              ),
            ),
          ),
          // Etiqueta de la fuente
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text(source.name, overflow: TextOverflow.ellipsis, style: CyberpunkTheme.terminalStyle.copyWith(fontSize: 10)),
          ),
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
    final barCount = 12;
    final barHeight = size.height / barCount;
    final activeBars = (level * barCount).ceil();

    for (int i = 0; i < barCount; i++) {
      final isLit = i < activeBars;
      // FIX: Ajustados los colores a los del tema Cyberpunk real y nativos de Flutter
      final color = i < 8 ? CyberpunkTheme.terminalGreen : (i < 10 ? Colors.yellow : CyberpunkTheme.errorRed);
      paint.color = isLit ? color : color.withOpacity(0.2);
      canvas.drawRect(Rect.fromLTWH(0, size.height - (i + 1) * barHeight, size.width, barHeight - 2), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _VuMeterPainter oldDelegate) => level != oldDelegate.level;
}
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/hal.dart';
import '../../core/switcher_engine.dart';
import 'package:ar_control_live_studio/core/theme/cyberpunk_theme.dart';

/// Widget que renderiza el stream de video para PREVIEW o PROGRAM.
class VideoRenderLayer extends ConsumerWidget {
  final String? sourceId;
  final String label;
  final Color borderColor;

  const VideoRenderLayer({
    required this.sourceId,
    required this.label,
    required this.borderColor,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final switcherState = ref.watch(switcherEngineProvider);
    final VideoSourceHAL? currentSource = sourceId != null ? switcherState.sources[sourceId] : null;

    return Container(
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        border: Border.all(color: borderColor, width: 2),
        color: CyberpunkTheme.panel.withOpacity(0.6),
      ),
      child: Stack(
        children: [
          // Renderiza la textura de video si está disponible
          if (currentSource != null)
            Positioned.fill(
              child: ValueListenableBuilder<int?>(
                valueListenable: currentSource.textureIdNotifier,
                builder: (context, textureId, child) {
                  if (textureId != null) {
                    return Texture(textureId: textureId);
                  }
                  return Center(
                    child: Text(
                      'NO SIGNAL',
                      style: CyberpunkTheme.terminalStyle.copyWith(
                        color: Colors.redAccent,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  );
                },
              ),
            )
          else
            Center(
              child: Text(
                'NO SIGNAL',
                style: CyberpunkTheme.terminalStyle.copyWith(
                  color: Colors.redAccent,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          // Etiqueta de PREVIEW/PROGRAM
          Positioned(
            bottom: 8,
            left: 8,
            child: Text(label, style: CyberpunkTheme.terminalStyle.copyWith(color: borderColor)),
          ),
        ],
      ),
    );
  }
}
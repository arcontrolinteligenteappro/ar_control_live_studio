import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ar_control_live_studio/core/hal.dart';
import 'package:ar_control_live_studio/core/switcher_engine.dart';
import 'package:ar_control_live_studio/core/theme/cyberpunk_theme.dart';

/// Un widget que muestra una lista de todas las fuentes de video disponibles
/// en el SwitcherEngine y permite al usuario seleccionarlas para Preview.
class SourceSelector extends ConsumerWidget {
  const SourceSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final switcherState = ref.watch(switcherEngineProvider);
    // FIX 1: Removido switcherNotifier porque no se usa aquí.

    final List<VideoSourceHAL> availableSources = switcherState.sources.values.toList();

    return Container(
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: CyberpunkTheme.panel.withOpacity(0.8),
        border: Border.all(color: CyberpunkTheme.cyanNeon, width: 1),
        borderRadius: BorderRadius.circular(4.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Text(
              'VIDEO SOURCES',
              style: CyberpunkTheme.terminalStyle.copyWith(
                color: CyberpunkTheme.magentaNeon,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: availableSources.length,
              itemBuilder: (context, index) {
                return _SourceListItem(source: availableSources[index]);
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Widget de item de lista que gestiona su propio estado de Tally y animación.
class _SourceListItem extends ConsumerStatefulWidget {
  final VideoSourceHAL source;
  const _SourceListItem({required this.source});

  @override
  ConsumerState<_SourceListItem> createState() => _SourceListItemState();
}

class _SourceListItemState extends ConsumerState<_SourceListItem> {
  @override
  Widget build(BuildContext context) {
    final switcherState = ref.watch(switcherEngineProvider);
    final switcherNotifier = ref.read(switcherEngineProvider.notifier);

    final isProgram = switcherState.programSourceId == widget.source.id;
    final isPreview = switcherState.previewSourceId == widget.source.id;
    
    Color tallyColor;

    // FIX 3: Ajustados los colores para usar los correctos definidos en CyberpunkTheme
    if (isProgram) {
      tallyColor = CyberpunkTheme.errorRed; // Usar errorRed en lugar de tallyRed
    } else if (isPreview) {
      tallyColor = CyberpunkTheme.terminalGreen; // Usar terminalGreen en lugar de tallyGreen
    } else {
      tallyColor = CyberpunkTheme.cyanNeon; // Usar el texto default en lugar de foregroundColor
    }

    return GestureDetector(
      onTap: () => switcherNotifier.selectForPreview(widget.source.id),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4.0),
        padding: const EdgeInsets.all(8.0),
        decoration: BoxDecoration(
          color: tallyColor.withOpacity(isProgram || isPreview ? 0.2 : 0.05),
          border: Border.all(color: tallyColor, width: isProgram ? 2 : 1),
          borderRadius: BorderRadius.circular(2.0),
        ),
        child: Text(
          '${widget.source.name} (${widget.source.id})',
          style: CyberpunkTheme.terminalStyle.copyWith(color: tallyColor, fontSize: 14),
        ),
      ),
    );
  }
}
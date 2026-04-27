import 'package:ar_control_live_studio/core/macro_engine.dart';
import 'package:ar_control_live_studio/core/midi_mapping_service.dart';
import 'package:ar_control_live_studio/core/switcher_engine.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ar_control_live_studio/core/theme/cyberpunk_theme.dart';

class MidiMappingView extends ConsumerWidget {
  const MidiMappingView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLearning = ref.watch(isMidiLearningProvider);
    final learningEvent = ref.watch(learningMidiEventProvider);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CyberpunkTheme.panel.withOpacity(0.95),
        border: Border.all(color: isLearning ? CyberpunkTheme.errorRed : CyberpunkTheme.magentaNeon, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeader(ref, isLearning, learningEvent),
          const Divider(color: CyberpunkTheme.magentaNeon),
          if (learningEvent != null)
            Expanded(child: _ActionSelector())
          else
            Expanded(child: _MappingList()),
        ],
      ),
    );
  }

  Widget _buildHeader(WidgetRef ref, bool isLearning, ({int id, bool isNote})? learningEvent) {
    String title = 'MIDI_MAPPER // STANDBY';
    if (isLearning) {
      title = learningEvent == null
          ? 'LEARN_MODE // MOVE_A_MIDI_CONTROL...'
          : 'LEARN_MODE // SELECT_TARGET_ACTION...';
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: CyberpunkTheme.terminalStyle.copyWith(color: CyberpunkTheme.magentaNeon)),
        Row(
          children: [
            if (!isLearning)
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: CyberpunkTheme.panel,
                  foregroundColor: CyberpunkTheme.cyanNeon,
                ),
                onPressed: () {
                  ref.read(midiMappingProvider.notifier).saveMappings();
                },
                child: const Text('SAVE'),
              ),
            const SizedBox(width: 8),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: isLearning ? CyberpunkTheme.errorRed : CyberpunkTheme.panel,
                foregroundColor: isLearning ? Colors.white : CyberpunkTheme.magentaNeon,
              ),
              onPressed: () {
                final currentlyLearning = ref.read(isMidiLearningProvider);
                ref.read(isMidiLearningProvider.notifier).state = !currentlyLearning;
                ref.read(learningMidiEventProvider.notifier).state = null; // Reset on toggle
              },
              child: Text(isLearning ? 'CANCEL' : 'LEARN'),
            ),
          ],
        ),
      ],
    );
  }
}

class _MappingList extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mappings = ref.watch(midiMappingProvider);
    final allMappings = [...mappings.ccMappings.entries, ...mappings.noteMappings.entries];

    if (allMappings.isEmpty) {
      return Center(child: Text('NO_MIDI_MAPPINGS_DEFINED', style: CyberpunkTheme.terminalStyle));
    }

    return ListView.builder(
      itemCount: allMappings.length,
      itemBuilder: (context, index) {
        final entry = allMappings[index];
        final isNote = entry.value is MacroTriggerAction;
        final prefix = isNote ? 'NOTE' : 'CC';
        return Text('>> $prefix ${entry.key} -> ${entry.value.description}', style: CyberpunkTheme.terminalStyle);
      },
    );
  }
}

class _ActionSelector extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sources = ref.watch(switcherEngineProvider.select((s) => s.sources.values.toList()));
    final macros = ref.watch(macroEngineProvider.select((s) => s.macros));

    final List<MappableAction> actions = [
      ...sources.map((s) => VolumeAction(sourceId: s.id)),
      ...macros.map((m) => MacroTriggerAction(macroName: m.name)),
    ];

    return ListView.builder(
      itemCount: actions.length,
      itemBuilder: (context, index) {
        final action = actions[index];
        return ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: CyberpunkTheme.panel,
            foregroundColor: CyberpunkTheme.cyanNeon,
          ),
          onPressed: () {
            final learningEvent = ref.read(learningMidiEventProvider)!;
            final mappingNotifier = ref.read(midiMappingProvider.notifier);

            if (learningEvent.isNote) {
              mappingNotifier.mapNoteToAction(learningEvent.id, action);
            } else {
              mappingNotifier.mapCcToAction(learningEvent.id, action);
            }

            // End learning session
            ref.read(isMidiLearningProvider.notifier).state = false;
            ref.read(learningMidiEventProvider.notifier).state = null;
          },
          child: Text(action.description),
        );
      },
    );
  }
}
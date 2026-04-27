import 'package:ar_control_live_studio/core/midi_mapping_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'cyberpunk_theme.dart';
import 'master_scaffold.dart';

class HelpView extends ConsumerWidget {
  const HelpView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final midiMappings = ref.watch(midiMappingProvider);
    final noteMappings = midiMappings.noteMappings.entries.toList();
    final ccMappings = midiMappings.ccMappings.entries.toList();

    return MasterScaffold(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: ListView(
          children: [
            Text('>> HELP_SYSTEM // OPERATOR_REFERENCE', style: CyberpunkTheme.terminalStyle.copyWith(fontSize: 16, color: CyberpunkTheme.magentaNeon)),
            const Divider(color: CyberpunkTheme.magentaNeon),
            const SizedBox(height: 24),

            // --- MIDI Mappings ---
            Text('// Active MIDI Mappings', style: CyberpunkTheme.terminalStyle.copyWith(color: Colors.grey)),
            const SizedBox(height: 8),
            if (noteMappings.isEmpty && ccMappings.isEmpty)
              Text('NO_MIDI_MAPPINGS_DEFINED', style: CyberpunkTheme.terminalStyle.copyWith(color: CyberpunkTheme.tallyWarning))
            else ...[
              ...noteMappings.map((entry) => _buildMappingRow('NOTE ${entry.key}', entry.value.description)),
              ...ccMappings.map((entry) => _buildMappingRow('CC ${entry.key}', entry.value.description)),
            ],
            const SizedBox(height: 24),

            // --- Keyboard Shortcuts ---
            Text('// Keyboard Shortcuts', style: CyberpunkTheme.terminalStyle.copyWith(color: Colors.grey)),
            const SizedBox(height: 8),
            _buildShortcutRow('[1-9]', 'Select Source 1-9 for PREVIEW'),
            _buildShortcutRow('[ENTER]', 'Execute CUT transition'),
            _buildShortcutRow('[SPACE]', 'Execute AUTO transition'),
            _buildShortcutRow('[M]', 'Toggle MIDI Learn Mode'),
            _buildShortcutRow('[R]', 'Trigger Instant Replay Save'),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildMappingRow(String control, String action) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        children: [
          Text('>> $control'.padRight(12), style: CyberpunkTheme.terminalStyle.copyWith(color: CyberpunkTheme.cyanNeon)),
          const Text('-> ', style: CyberpunkTheme.terminalStyle),
          Expanded(child: Text(action, style: CyberpunkTheme.terminalStyle.copyWith(color: Colors.white))),
        ],
      ),
    );
  }

  Widget _buildShortcutRow(String key, String description) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        children: [
          Text(key.padRight(12), style: CyberpunkTheme.terminalStyle.copyWith(color: CyberpunkTheme.cyanNeon)),
          const Text('-> ', style: CyberpunkTheme.terminalStyle),
          Expanded(child: Text(description, style: CyberpunkTheme.terminalStyle.copyWith(color: Colors.white))),
        ],
      ),
    );
  }
}
import 'package:ar_control_live_studio/core/midi_mapping_service.dart';
import 'package:ar_control_live_studio/core/settings_provider.dart';
import 'package:ar_control_live_studio/ui/player/common_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'cyberpunk_theme.dart';
import 'master_scaffold.dart';

class SettingsView extends ConsumerWidget {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentBitrate = ref.watch(settingsProvider.select((s) => s.webrtcBitrate));

    return MasterScaffold(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: ListView(
          children: [
            Text('>> SYSTEM_SETTINGS // CONFIGURATION', style: CyberpunkTheme.terminalStyle.copyWith(fontSize: 16, color: CyberpunkTheme.magentaNeon)),
            const Divider(color: CyberpunkTheme.magentaNeon),
            const SizedBox(height: 24),

            // --- WebRTC Settings ---
            Text('// WebRTC Stream Quality', style: CyberpunkTheme.terminalStyle.copyWith(color: Colors.grey)),
            const SizedBox(height: 8),
            _buildDropdownSetting<int>(
              context: context,
              title: 'Bitrate',
              currentValue: currentBitrate,
              items: {
                'Low (1 Mbps)': 1000,
                'Medium (2.5 Mbps)': 2500,
                'High (5 Mbps)': 5000,
                'Ultra (8 Mbps)': 8000,
              },
              onChanged: (value) {
                if (value != null) {
                  ref.read(settingsProvider.notifier).setWebrtcBitrate(value);
                  showCyberpunkToast(context, 'WebRTC Bitrate set to ${value / 1000} Mbps');
                }
              },
            ),
            const SizedBox(height: 24),

            // --- MIDI Settings ---
            Text('// MIDI Controller', style: CyberpunkTheme.terminalStyle.copyWith(color: Colors.grey)),
            const SizedBox(height: 8),
            SelectionButton(
              label: 'RESET MIDI MAPPINGS',
              onTap: () {
                ref.read(midiMappingProvider.notifier).resetToDefaults();
                showCyberpunkToast(context, 'MIDI MAPPINGS RESET TO DEFAULT', color: CyberpunkTheme.tallyWarning);
              },
              color: CyberpunkTheme.tallyWarning,
            ),
            const SizedBox(height: 24),
            
            // --- Other settings can be added here ---
          ],
        ),
      ),
    );
  }

  Widget _buildDropdownSetting<T>({
    required BuildContext context,
    required String title,
    required T currentValue,
    required Map<String, T> items,
    required ValueChanged<T?> onChanged,
  }) {
    return Card(
      color: CyberpunkTheme.panel,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: CyberpunkTheme.terminalStyle),
            DropdownButton<T>(
              value: currentValue,
              dropdownColor: CyberpunkTheme.panel,
              style: CyberpunkTheme.terminalStyle.copyWith(color: CyberpunkTheme.cyanNeon),
              underline: Container(),
              onChanged: onChanged,
              items: items.entries.map((entry) {
                return DropdownMenuItem<T>(
                  value: entry.value,
                  child: Text(entry.key),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
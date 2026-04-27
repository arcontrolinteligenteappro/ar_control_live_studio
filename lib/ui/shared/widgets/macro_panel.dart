import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ar_control_live_studio/core/macro_engine.dart';
import 'package:ar_control_live_studio/core/macro_editor_view.dart';
import 'package:ar_control_live_studio/core/theme/cyberpunk_theme.dart';
import 'package:ar_control_live_studio/ui/shared/widgets/control_button.dart';

class MacroPanel extends ConsumerWidget { 
  const MacroPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final macroState = ref.watch(macroEngineProvider);
    final macroNotifier = ref.read(macroEngineProvider.notifier);

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: CyberpunkTheme.panel.withOpacity(0.8),
        border: Border.all(color: CyberpunkTheme.neonPurple, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '>> MACRO_ENGINE',
                style: CyberpunkTheme.terminalStyle.copyWith(color: CyberpunkTheme.magentaNeon),
              ),
              ControlButton(label: "NEW MACRO", onPressed: () {
                showDialog(context: context, builder: (_) => const MacroEditorView());
              }),
            ],
          ),
          const Divider(color: CyberpunkTheme.neonPurple),
          if (macroState.runningMacroName != null)
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'RUNNING: ${macroState.runningMacroName}',
                    style: CyberpunkTheme.terminalStyle.copyWith(color: CyberpunkTheme.cyanNeon),
                  ),
                  Text(
                    'ACTION: ${macroState.currentActionDescription ?? 'IDLE'}',
                    style: CyberpunkTheme.terminalStyle.copyWith(color: Colors.white70, fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  LinearProgressIndicator(
                    value: macroState.executionProgress,
                    backgroundColor: CyberpunkTheme.darkGrey,
                    valueColor: const AlwaysStoppedAnimation<Color>(CyberpunkTheme.neonCyan),
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: ControlButton(
                      label: 'CANCEL MACRO',
                      onPressed: macroNotifier.cancelMacro,
                      isActive: true, // Siempre activo cuando una macro está corriendo
                    ),
                  ),
                ],
              ),
            )
          else
            Expanded(
              child: macroState.macros.isEmpty
                  ? Center(child: Text('NO MACROS DEFINED', style: CyberpunkTheme.terminalStyle.copyWith(color: Colors.grey, shadows: [])))
                  : ReorderableListView.builder(
                      itemCount: macroState.macros.length,
                      onReorder: (oldIndex, newIndex) {
                        macroNotifier.reorderMacro(oldIndex, newIndex);
                      },
                      itemBuilder: (context, index) {
                        final macro = macroState.macros[index];
                        return Card(
                          key: ValueKey(macro.name),
                          color: CyberpunkTheme.panel.withOpacity(0.5),
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          child: ListTile(
                            dense: true,
                            title: Text(macro.name, style: CyberpunkTheme.terminalStyle.copyWith(color: CyberpunkTheme.cyanNeon)),
                            trailing: Wrap(
                              spacing: -8,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.play_arrow, color: CyberpunkTheme.terminalGreen),
                                  onPressed: () => macroNotifier.executeMacro(macro.name),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.edit, color: CyberpunkTheme.neonCyan),
                                  onPressed: () => showDialog(context: context, builder: (_) => MacroEditorView(macro: macro)),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete, color: CyberpunkTheme.errorRed),
                                  onPressed: () => macroNotifier.deleteMacro(macro.name),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
            )
        ],
      ),
    );
  }
}
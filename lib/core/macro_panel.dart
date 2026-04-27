import 'package:ar_control_live_studio/core/macro_engine.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ar_control_live_studio/core/macro_editor_view.dart';
import 'package:ar_control_live_studio/core/theme/cyberpunk_theme.dart';

class MacroPanel extends ConsumerWidget {
  const MacroPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final macroState = ref.watch(macroEngineProvider);
    final macroEngine = ref.read(macroEngineProvider.notifier);

    return Container(
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: CyberpunkTheme.panel.withOpacity(0.8),
        border: Border.all(color: CyberpunkTheme.cyanNeon, width: 1),
      ),
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('MACRO_SEQUENCER // STANDBY', style: CyberpunkTheme.terminalStyle.copyWith(color: CyberpunkTheme.cyanNeon)),
              const Divider(color: CyberpunkTheme.cyanNeon),
              Expanded(
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 200,
                    childAspectRatio: 3 / 1,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: macroState.macros.length,
                  itemBuilder: (context, index) {
                    final macro = macroState.macros[index];
                    final isRunningThisMacro = macroState.runningMacroName == macro.name;
                    final isAnyMacroRunning = macroState.runningMacroName != null;

                    return GestureDetector(
                      onLongPress: () {
                        showDialog(
                          context: context,
                          builder: (_) => MacroEditorView(macro: macro),
                        );
                      },
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isRunningThisMacro ? CyberpunkTheme.tallyRed : (isAnyMacroRunning ? Colors.grey[800] : CyberpunkTheme.panel),
                          foregroundColor: isAnyMacroRunning && !isRunningThisMacro ? Colors.grey : CyberpunkTheme.cyanNeon,
                          shadowColor: CyberpunkTheme.cyanNeon,
                          elevation: 4,
                          shape: const BeveledRectangleBorder(side: BorderSide(color: CyberpunkTheme.cyanNeon, width: 1)),
                          padding: const EdgeInsets.all(8),
                        ),
                        onPressed: isAnyMacroRunning ? null : () => macroEngine.executeMacro(macro.name),
                        child: Text(macro.name, textAlign: TextAlign.center, style: CyberpunkTheme.terminalStyle.copyWith(fontSize: 12)),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
          Positioned(
            bottom: 16,
            right: 16,
            child: FloatingActionButton(
              onPressed: () {
                showDialog(context: context, builder: (_) => const MacroEditorView());
              },
              backgroundColor: CyberpunkTheme.cyanNeon,
              foregroundColor: CyberpunkTheme.background,
              child: const Icon(Icons.add),
            ),
          ),
        ],
      ),
    );
  }
}
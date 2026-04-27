import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ar_control_live_studio/ui/shared/widgets/control_button.dart';
import 'package:ar_control_live_studio/core/switcher_engine.dart';
import 'package:ar_control_live_studio/core/theme/cyberpunk_theme.dart';

class ProModeView extends ConsumerWidget { 
  const ProModeView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final switcher = ref.watch(switcherEngineProvider);
    final engine = ref.read(switcherEngineProvider.notifier);

    return Scaffold(
      backgroundColor: CyberpunkTheme.black,
      body: Column(
        children: [
          // Monitores Preview/Program
          Expanded(
            child: Row(
              children: [
                _MonitorBox(label: "PREVIEW", source: switcher.previewSourceId, color: Colors.green),
                _MonitorBox(label: "PROGRAM", source: switcher.programSourceId, color: Colors.red), 
              ],
            ),
          ),
          // Botonera
          Container(
            padding: const EdgeInsets.all(20),
            color: CyberpunkTheme.darkGrey,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [ 
                ControlButton(label: "CUT", onPressed: () => engine.executeCut()),
                const SizedBox(width: 20),
                ControlButton(label: "AUTO", onPressed: () {}, isActive: switcher.inTransition),
              ],
            ),
          )
        ],
      ),
    );
  }
}

class _MonitorBox extends StatelessWidget {
  final String label;
  final String? source;
  final Color color;

  _MonitorBox({required this.label, this.source, required this.color}); 

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(border: Border.all(color: color, width: 2)),
        child: Center(
          child: Text("$label: ${source ?? 'NONE'}", 
          style: TextStyle(color: color, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }
}
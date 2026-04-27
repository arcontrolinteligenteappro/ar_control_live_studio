import 'package:ar_control_live_studio/core/theme/cyberpunk_theme.dart';
import 'package:flutter/material.dart';

/// Tarea 2: Restaurar Widgets de UI Perdidos
class SelectionButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final Color? color;

  const SelectionButton({super.key, required this.label, this.onTap, this.color});

  @override
  Widget build(BuildContext context) {
    return TextButton(onPressed: onTap, child: Text(label, style: TextStyle(color: color ?? CyberpunkTheme.cyanNeon)));
  }
}

/// Tarea 2: Restaurar Widgets de UI Perdidos
class InfoPanel extends StatelessWidget {
  final String title;
  final String subtitle;

  const InfoPanel({super.key, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Container(padding: const EdgeInsets.all(8), color: CyberpunkTheme.panel, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title), Text(subtitle)]));
  }
}

/// Tarea 2: Restaurar Widgets de UI Perdidos
class ActionChipWidget extends StatelessWidget {
  final String label;
  final bool active;

  const ActionChipWidget({super.key, required this.label, this.active = false});

  @override
  Widget build(BuildContext context) => ActionChip(label: Text(label), backgroundColor: active ? CyberpunkTheme.magentaNeon : CyberpunkTheme.panel, onPressed: () {});
}
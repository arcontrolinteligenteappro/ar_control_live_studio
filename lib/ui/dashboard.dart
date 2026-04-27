import 'package:flutter/material.dart';
import 'layout.dart';
import 'controls/stream_control.dart';
import 'controls/record_control.dart';
import 'controls/overlay_control.dart';
import 'controls/ptz_control.dart';
import 'controls/dj_control.dart';
import 'controls/ai_control.dart';
import 'controls/thermal_control.dart';

/// Dashboard: Panel principal de control.
/// Combina controles de streaming, grabación, overlays.
/// Adaptativo y con footer.
class Dashboard extends StatelessWidget {
  final String? selectedNode;

  const Dashboard({super.key, this.selectedNode});

  @override
  Widget build(BuildContext context) {
    List<Widget> controls = [
      const StreamControl(),
      const RecordControl(),
      const OverlayControl(),
      const PTZControl(),
      const DJControl(),
      const AIControl(),
      const ThermalControl(),
    ];

    // Filtrar controles por nodo
    if (selectedNode == 'ENGINE') {
      // Mostrar todos
    } else if (selectedNode == 'CAMERA') {
      controls = [const StreamControl(), const PTZControl(), const OverlayControl()];
    } else if (selectedNode == 'REMOTE') {
      controls = [const PTZControl(), const DJControl(), const AIControl()];
    } else if (selectedNode == 'PLAYER') {
      controls = [const StreamControl(), const OverlayControl(), const ThermalControl()];
    }

    return ARLayout(
      mode: 'Pro', // Modo profesional
      child: Scaffold(
        appBar: AppBar(
          title: Text('AR CONTROL LIVE STUDIO - ${selectedNode ?? 'PRO'} MODE'),
          backgroundColor: Colors.black,
          foregroundColor: Colors.cyanAccent,
        ),
        body: AdaptiveGrid(
          children: controls,
        ),
      ),
    );
  }
}
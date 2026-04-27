import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ar_control_live_studio/providers/app_session.dart';
import 'package:ar_control_live_studio/ui/master_scaffold.dart';
import 'package:ar_control_live_studio/core/theme/cyberpunk_theme.dart';
import 'package:ar_control_live_studio/core/event_bus.dart'; // Import corregido
import 'package:ar_control_live_studio/core/replay_engine.dart';

class RemoteControlView extends ConsumerStatefulWidget {
  const RemoteControlView({super.key});

  @override
  ConsumerState<RemoteControlView> createState() => _RemoteControlViewState();
}

class _RemoteControlViewState extends ConsumerState<RemoteControlView> {
  String? _connectionMode;
  String? _controlType;
  bool _remoteConnected = false;

  void _toggleRemoteConnection() {
    setState(() => _remoteConnected = !_remoteConnected);
  }

  void _selectControlType(String type) {
    setState(() => _controlType = type);
  }

  Widget _selectionButton(String label, VoidCallback onTap, {Color? color}) {
    final neon = color ?? CyberpunkTheme.cyanNeon;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          decoration: BoxDecoration(border: Border.all(color: neon), color: neon.withOpacity(0.1)),
          child: Text(label, style: CyberpunkTheme.terminalStyle.copyWith(color: neon, shadows: [Shadow(color: neon, blurRadius: 4)])),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sessionNotifier = ref.read(appSessionProvider.notifier);

    if (_connectionMode == null) {
      return MasterScaffold(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('>> REMOTE_NODE // CONNECTION_MODE', style: CyberpunkTheme.terminalStyle.copyWith(fontSize: 16, color: CyberpunkTheme.magentaNeon)),
              const Divider(color: CyberpunkTheme.magentaNeon),
              const SizedBox(height: 24),
              _selectionButton('1 / LOCAL STANDALONE (INTERNAL LOGIC)', () {
                sessionNotifier.setOperationMode('Local Standalone');
                setState(() => _connectionMode = 'Local Standalone');
              }),
              _selectionButton('2 / REMOTE ENGINE (STREAM DECK)', () {
                sessionNotifier.setOperationMode('Remote Engine');
                setState(() => _connectionMode = 'Remote Engine');
              }),
            ],
          ),
          ),
        );
    }

    return MasterScaffold(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 720;
          return Padding(
            padding: const EdgeInsets.all(16),
            child: SingleChildScrollView(
              child: _connectionMode == 'Local Standalone'
                  ? _buildLocalStandalone(isNarrow)
                  : _buildRemoteEngine(isNarrow),
            ),
          );
        },
      ),
    );
  }

  Widget _buildLocalStandalone(bool isNarrow) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildInfoPanel('NODE: STANDALONE', 'Controlador táctico aislado sin dependencia de ENGINE.'),
        const SizedBox(height: 16),
        Text('>> SELECT_MODULE', style: CyberpunkTheme.terminalStyle.copyWith(color: CyberpunkTheme.magentaNeon)),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _actionChip('SPORTS_CG'),
            _actionChip('SALES_ENGINE'),
            _actionChip('DIGITAL_PANEL'),
          ],
        ),
        const SizedBox(height: 16),
        if (_controlType == 'SPORTS_CG') _buildSportsPanel(),
        if (_controlType == 'SALES_ENGINE') _buildSimplePanel('SALES_ENGINE', 'Motor de reglas para ventas, QR y promociones en vivo.'),
        if (_controlType == 'DIGITAL_PANEL') _buildSimplePanel('DIGITAL_PANEL', 'Generador de mini-overlays y marcadores de estado.'),
      ],
    );
  }

  Widget _buildRemoteEngine(bool isNarrow) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildInfoPanel('NODE: REMOTE_ENGINE', 'Plataforma táctil (StreamDeck) enlazada al ENGINE central.'),
        const SizedBox(height: 16),
        _statusChip('ENGINE_LINK', _remoteConnected),
        const SizedBox(height: 12),
        _selectionButton(_remoteConnected ? '>> SEVER_LINK' : '>> ESTABLISH_LINK', _toggleRemoteConnection, color: _remoteConnected ? const Color(0xFFFF0000) : CyberpunkTheme.cyanNeon),
        const SizedBox(height: 24),
        Text('>> DECK_CONTROL_SURFACE', style: CyberpunkTheme.terminalStyle.copyWith(color: CyberpunkTheme.magentaNeon)),
        const SizedBox(height: 12),
        _buildControlDeck(isNarrow),
      ],
    );
  }

  Widget _buildSportsPanel() {
    return Container(
      decoration: BoxDecoration(border: Border.all(color: CyberpunkTheme.magentaNeon), color: CyberpunkTheme.panel),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('>> SPORTS_CORE_INITIALIZED', style: CyberpunkTheme.terminalStyle.copyWith(color: CyberpunkTheme.magentaNeon, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Text('Configura equipos, tiempos y cronómetros de posesión.', style: CyberpunkTheme.terminalStyle.copyWith(color: CyberpunkTheme.textMain)),
          const SizedBox(height: 24),
          _selectionButton('>> CONFIG_TEAMS', () {}, color: CyberpunkTheme.cyanNeon),
          _selectionButton('>> PUSH_SCOREBOARD_GFX', () {}, color: CyberpunkTheme.magentaNeon),
        ],
      ),
    );
  }

  Widget _buildSimplePanel(String title, String description) {
    return Container(
      decoration: BoxDecoration(border: Border.all(color: CyberpunkTheme.cyanNeon.withOpacity(0.5)), color: CyberpunkTheme.panel),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('>> $title', style: CyberpunkTheme.terminalStyle.copyWith(color: CyberpunkTheme.cyanNeon, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Text(description, style: CyberpunkTheme.terminalStyle.copyWith(color: CyberpunkTheme.textMain)),
          ],
        ),
      ),
    );
  }

  Widget _buildControlDeck(bool isNarrow) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: isNarrow ? 2 : 4,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.0, // Botones 100% cuadrados
      children: [
        _deckButton('CAM 1', color: const Color(0xFFFF0000), onTap: () => AppEventBus.instance.fire(HardCutEvent('CAM_1'))),
        _deckButton('CAM 2', color: CyberpunkTheme.cyanNeon, onTap: () => AppEventBus.instance.fire(HardCutEvent('CAM_2'))),
        _deckButton('REPLAY -5S', color: CyberpunkTheme.magentaNeon, onTap: () {
          ReplayEngine().triggerSave('instant_replay.mp4');
        }),
        _deckButton('CUT (TAKE)', color: CyberpunkTheme.textMain, onTap: () {
          // Aquí es donde el EventBus síncrono brilla. El evento se dispara y procesa instantáneamente.
          AppEventBus.instance.fire(HardCutEvent('TAKE'));
        }),
        _deckButton('GFX IN', color: CyberpunkTheme.cyanNeon, onTap: () { /* Lógica de Overlay Engine */ }),
        _deckButton('GFX OUT', color: CyberpunkTheme.textMain, onTap: () { /* Lógica de Overlay Engine */ }),
        _deckButton('MUTE MIC', color: const Color(0xFFFF0000), onTap: () { /* Lógica de Audio Engine */ }),
        _deckButton('BLACK', color: CyberpunkTheme.textMain, onTap: () => AppEventBus.instance.fire(HardCutEvent('BLACK'))),
      ],
    );
  }

  Widget _buildInfoPanel(String title, String subtitle) {
    return Container(
      decoration: const BoxDecoration(border: Border(left: BorderSide(color: CyberpunkTheme.cyanNeon, width: 4)), color: CyberpunkTheme.panel),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: CyberpunkTheme.terminalStyle),
          const SizedBox(height: 8),
          Text(subtitle, style: CyberpunkTheme.terminalStyle.copyWith(color: CyberpunkTheme.textMain, fontSize: 10)),
        ],
      ),
    );
  }

  Widget _actionChip(String label) {
    final selected = _controlType == label;
    final color = selected ? CyberpunkTheme.magentaNeon : CyberpunkTheme.cyanNeon;
    final bgColor = selected ? CyberpunkTheme.magentaNeon : CyberpunkTheme.panel;
    final textColor = selected ? CyberpunkTheme.background : color;
    
    return GestureDetector(
      onTap: () => _selectControlType(label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(border: Border.all(color: color), color: bgColor),
        child: Text(label, style: CyberpunkTheme.terminalStyle.copyWith(color: textColor, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _deckButton(String label, {VoidCallback? onTap, Color color = CyberpunkTheme.cyanNeon}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          border: Border.all(color: color, width: 2),
          boxShadow: [BoxShadow(color: color.withOpacity(0.2), blurRadius: 8)],
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: CyberpunkTheme.terminalStyle.copyWith(color: color, fontWeight: FontWeight.bold, fontSize: 14),
        ),
      ),
    );
  }

  Widget _statusChip(String label, bool active) {
    final color = active ? CyberpunkTheme.cyanNeon : CyberpunkTheme.panel;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(border: Border.all(color: color), color: color.withOpacity(0.2)),
      child: Text(label, style: CyberpunkTheme.terminalStyle.copyWith(color: active ? CyberpunkTheme.cyanNeon : CyberpunkTheme.textMain)),
    );
  }
}

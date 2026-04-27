import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ar_control_live_studio/core/app_session.dart'; // Corrected import
import 'package:ar_control_live_studio/master_scaffold.dart';
// Los siguientes archivos no se encontraron en el contexto y se han comentado.
// import 'player_view_provider.dart';
import 'package:ar_control_live_studio/core/theme/cyberpunk_theme.dart';
import 'package:ar_control_live_studio/ui/shared/widgets/common_widgets.dart';

class PlayerState {
  final String? selectedCastingDevice;
  final bool isCastingBuffering;
  final bool teleprompter;
  final double teleprompterSpeed;
  final bool syncConnected;

  const PlayerState({
    this.selectedCastingDevice,
    this.isCastingBuffering = false,
    this.teleprompter = false,
    this.teleprompterSpeed = 1.0,
    this.syncConnected = false,
  });

  PlayerState copyWith({
    String? selectedCastingDevice,
    bool? isCastingBuffering,
    bool? teleprompter,
    double? teleprompterSpeed,
    bool? syncConnected,
  }) {
    return PlayerState(
      selectedCastingDevice: selectedCastingDevice ?? this.selectedCastingDevice,
      isCastingBuffering: isCastingBuffering ?? this.isCastingBuffering,
      teleprompter: teleprompter ?? this.teleprompter,
      teleprompterSpeed: teleprompterSpeed ?? this.teleprompterSpeed,
      syncConnected: syncConnected ?? this.syncConnected,
    );
  }
}

class PlayerNotifier extends StateNotifier<PlayerState> {
  PlayerNotifier() : super(const PlayerState());

  void selectCastingDevice(String? device) {
    state = state.copyWith(selectedCastingDevice: device, isCastingBuffering: device != null);
    if (device != null) {
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted && state.selectedCastingDevice == device) {
          state = state.copyWith(isCastingBuffering: false);
        }
      });
    }
  }

  void setTeleprompterSpeed(double speed) {
    state = state.copyWith(teleprompterSpeed: speed);
  }

  void toggleTeleprompter() {
    state = state.copyWith(teleprompter: !state.teleprompter);
  }

  void toggleSync() {
    state = state.copyWith(syncConnected: !state.syncConnected);
  }
}

final playerProvider = StateNotifierProvider<PlayerNotifier, PlayerState>((ref) => PlayerNotifier());

class PlayerView extends ConsumerStatefulWidget {
  const PlayerView({super.key}); 

  @override
  ConsumerState<PlayerView> createState() => _PlayerViewState();
}
class _PlayerViewState extends ConsumerState<PlayerView> {
  @override
  Widget build(BuildContext context) {
    // Observa el modo de operación desde el provider.
    // El UI se reconstruirá automáticamente cuando cambie.
    final operationMode = ref.watch(appSessionProvider.select((session) => session.operationMode));

    if (operationMode == null) {
      return MasterScaffold(
        child: Padding( 
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('>> SYSTEM_PLAYER // OPERATION_MODE', style: CyberpunkTheme.terminalStyle.copyWith(fontSize: 16, color: CyberpunkTheme.magentaNeon)),
              const Divider(color: CyberpunkTheme.magentaNeon),
              const SizedBox(height: 24),
              SelectionButton(label: '1 / LOCAL (LARIX / TELEPROMPTER)', onTap: () => ref.read(appSessionProvider.notifier).setOperationMode('Local')), // Corrected call
              SelectionButton(label: '2 / SYNC CON ENGINE (MULTIVIEWER)', onTap: () => ref.read(appSessionProvider.notifier).setOperationMode('Sync con Engine')), // Corrected call
            ],
          ),
        ),
      );
    }

    return MasterScaffold(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 720;
          return Stack(
            children: [
              // CAPA BASE (Render del reproductor de video / multiview)
              RepaintBoundary( 
                child: Container(color: Colors.black),
              ),
              // CAPA HUD / UI
              Positioned.fill(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: operationMode == 'Local'
                      ? _LocalPlayerControls(isNarrow: isNarrow)
                      : _SyncPlayerControls(isNarrow: isNarrow),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Controles para el modo de operación "Local".
class _LocalPlayerControls extends ConsumerWidget {
  final bool isNarrow;
  _LocalPlayerControls({required this.isNarrow});

  final audioPlayerProvider = Provider((ref) => Object());
  
  String get _teleprompterText => '>> ALERTA: HACKING INICIADO.\n\nEL FLUJO DE DATOS ES CORRECTO.\n\nSISTEMA EN LINEA.';
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playerState = ref.watch(playerProvider);
    final playerNotifier = ref.read(playerProvider.notifier);

    /* Listener para efectos secundarios como toasts (comentado por dependencias faltantes).
    ref.listen<PlayerState>(playerProvider, (previous, next) {
      // Toast para teleprompter
      if (previous?.teleprompter != next.teleprompter) {
        showCyberpunkToast(context, 'TELEPROMPTER ${next.teleprompter ? "ENABLED" : "DISABLED"}', color: CyberpunkTheme.magentaNeon);
      }
      // Toast para casting
      if (previous?.selectedCastingDevice != next.selectedCastingDevice) {
        if (next.selectedCastingDevice != null) {
          showCyberpunkToast(context, 'CAST INITIATED: ${next.selectedCastingDevice}');
        } else if (previous?.selectedCastingDevice != null) {
          showCyberpunkToast(context, 'CAST TERMINATED', color: const Color(0xFFFF0000));
        }
      }
    });*/
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const InfoPanel(title: 'NODE: LOCAL_PLAYER', subtitle: 'Reproductor avanzado y proyección inalámbrica.'),
        const SizedBox(height: 16), 
        Wrap(spacing: 12, runSpacing: 12, alignment: WrapAlignment.start, children: [
          for (var device in ['FireTV', 'Google Cast', 'Roku'])
            Stack(
              alignment: Alignment.center,
              children: [
                GestureDetector(
                  onTap: () {
                    playerNotifier.selectCastingDevice(device);
                  },
                  child: ActionChipWidget(
                    label: device,
                    active: playerState.selectedCastingDevice == device,
                  ),
                ),
                if (playerState.isCastingBuffering && playerState.selectedCastingDevice == device)
                  const SizedBox( 
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: CyberpunkTheme.cyanNeon),
                  ),
              ],
            ),
        ]),
        const SizedBox(height: 16),
        SelectionButton( 
          label: playerState.selectedCastingDevice != null ? '>> STOP_CAST' : '>> INITIATE_CAST',
          onTap: playerState.selectedCastingDevice != null
              ? () => playerNotifier.selectCastingDevice(null) // Deselect to stop casting
              : null, // Disable button if no device is selected
          color: playerState.selectedCastingDevice != null ? const Color(0xFFFF0000) : CyberpunkTheme.cyanNeon,
        ),
        const SizedBox(height: 24),
         
        const InfoPanel(title: 'MODULE: TELEPROMPTER', subtitle: 'Activa inversión de espejo en Y-axis (Glass Mode)'),
        const SizedBox(height: 12),
        // Teleprompter Speed Controls
        Wrap(spacing: 8, runSpacing: 8, alignment: WrapAlignment.center, children: [
          Text('SPEED:', style: CyberpunkTheme.terminalStyle.copyWith(color: CyberpunkTheme.textMain, fontSize: 12)),
          SelectionButton(
            label: '0.5x',
            onTap: () => playerNotifier.setTeleprompterSpeed(0.5),
            color: playerState.teleprompterSpeed == 0.5 ? CyberpunkTheme.magentaNeon : CyberpunkTheme.textMain,
          ),
          SelectionButton(
            label: '1.0x',
            onTap: () => playerNotifier.setTeleprompterSpeed(1.0),
            color: playerState.teleprompterSpeed == 1.0 ? CyberpunkTheme.magentaNeon : CyberpunkTheme.textMain,
          ),
          SelectionButton(
            label: '1.5x',
            onTap: () => playerNotifier.setTeleprompterSpeed(1.5),
            color: playerState.teleprompterSpeed == 1.5 ? CyberpunkTheme.magentaNeon : CyberpunkTheme.textMain,
          ),
        ]),
        const SizedBox(height: 12),
        SelectionButton(
            label: playerState.teleprompter ? '>> DISABLE_PROMPTER' : '>> ENABLE_PROMPTER',
            onTap: () {
              playerNotifier.toggleTeleprompter();
            },
            color: CyberpunkTheme.magentaNeon),
        
        Expanded(child: _TeleprompterView(isNarrow: isNarrow, text: _teleprompterText)),
      ],
    );
  }
}

/// Vista del teleprompter con desplazamiento automático.
class _TeleprompterView extends ConsumerStatefulWidget {
  final bool isNarrow;
  final String text;
 
  const _TeleprompterView({required this.isNarrow, required this.text});

  @override
  ConsumerState<_TeleprompterView> createState() => _TeleprompterViewState();
}

class _TeleprompterViewState extends ConsumerState<_TeleprompterView> {
  // Placeholder para provider no encontrado
  final playerProvider = StateNotifierProvider<PlayerNotifier, PlayerState>((ref) => PlayerNotifier());
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isTeleprompterActive = ref.watch(playerProvider.select((s) => s.teleprompter));

    final teleprompterSpeed = ref.watch(playerProvider.select((s) => s.teleprompterSpeed));
    ref.listen<bool>(playerProvider.select((s) => s.teleprompter), (previous, next) {
      if (next) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_scrollController.hasClients && widget.text.isNotEmpty) {
            final maxScroll = _scrollController.position.maxScrollExtent;
            // Ajusta la duración del scroll en base a teleprompterSpeed
            final scrollDuration = Duration(milliseconds: (maxScroll / (25 * teleprompterSpeed) * 1000).toInt());
            _scrollController.animateTo(maxScroll, duration: scrollDuration, curve: Curves.linear);
          }
        });
      } else {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(0, duration: const Duration(milliseconds: 500), curve: Curves.easeOut);
        }
      }
    });

    return Container(
      margin: const EdgeInsets.only(top: 16),
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        border: Border.all(color: CyberpunkTheme.magentaNeon.withOpacity(0.5)),
        color: CyberpunkTheme.background.withOpacity(0.8),
      ),
      child: Transform(
        alignment: Alignment.center,
        transform: isTeleprompterActive ? Matrix4.rotationY(math.pi) : Matrix4.identity(),
        child: isTeleprompterActive
            ? SingleChildScrollView(
                controller: _scrollController,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Text(widget.text, style: CyberpunkTheme.terminalStyle.copyWith(color: CyberpunkTheme.magentaNeon, fontSize: widget.isNarrow ? 24 : 32, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
              )
            : Center(child: Text('>> PROMPTER_IDLE', style: CyberpunkTheme.terminalStyle.copyWith(color: CyberpunkTheme.magentaNeon, fontSize: widget.isNarrow ? 24 : 32, fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
      ),
    );
  }
}

/// Controles para el modo de operación "Sync con Engine".
class _SyncPlayerControls extends ConsumerWidget {
  final bool isNarrow;
  _SyncPlayerControls({required this.isNarrow});

  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playerState = ref.watch(playerProvider);
    final playerNotifier = ref.read(playerProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [ 
        const InfoPanel(title: 'NODE: SYNC_PLAYER', subtitle: 'Monitor multiview táctico vinculado al ENGINE principal.'),
        const SizedBox(height: 16),
        ActionChipWidget(label: 'ENGINE_LINK', active: playerState.syncConnected),
        const SizedBox(height: 16),
        SelectionButton(label: playerState.syncConnected ? '>> TERMINATE_SYNC' : '>> INITIATE_SYNC', onTap: playerNotifier.toggleSync, color: playerState.syncConnected ? const Color(0xFFFF0000) : CyberpunkTheme.cyanNeon),
        const SizedBox(height: 24),
        _MultiviewPanel(isNarrow: isNarrow),
      ],
    );
  }
}

/// Panel que muestra un grid de vistas de cámara (Multiviewer).
class _MultiviewPanel extends StatelessWidget {
  final bool isNarrow;
  _MultiviewPanel({required this.isNarrow}); 

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        decoration: BoxDecoration(border: Border.all(color: CyberpunkTheme.cyanNeon.withOpacity(0.5)), color: CyberpunkTheme.panel.withOpacity(0.4)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('>> REMOTE_MULTIVIEWER', style: CyberpunkTheme.terminalStyle.copyWith(color: CyberpunkTheme.magentaNeon)),
              const SizedBox(height: 12),
              Expanded(
                child: GridView.count(
                  crossAxisCount: isNarrow ? 1 : 2,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  childAspectRatio: isNarrow ? 2.2 : 1.4,
                  children: List.generate(4, (index) {
                    return Container(
                      // Simula cristal transparente donde se vería el video real
                      decoration: BoxDecoration(border: Border.all(color: CyberpunkTheme.cyanNeon), color: Colors.transparent),
                      alignment: Alignment.bottomLeft,
                      padding: const EdgeInsets.all(4),
                      child: Text('CAM_0${index + 1}', style: CyberpunkTheme.terminalStyle),
                    );
                  }),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
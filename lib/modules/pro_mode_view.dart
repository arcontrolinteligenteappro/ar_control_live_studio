import 'package:flutter/material.dart';
import 'package:ar_control_live_studio/core/theme/cyberpunk_theme.dart';

/// Pro Mode: Multiview Profesional, Preview/Program, Macros y Tally Lights.
/// Esta vista actúa como un HUD transparente sobre el Render Engine.
class ProModeView extends StatelessWidget {
  const ProModeView({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          // ==========================================
          // FILA SUPERIOR: PREVIEW & PROGRAM + MACROS
          // ==========================================
          Expanded(
            flex: 3,
            child: Row(
              children: [
                // PVW Monitor (Tally Verde/Cyan)
                const Expanded(child: _Monitor(label: 'PREVIEW (PVW)', tally: CyberpunkTheme.cyanNeon)),
                const SizedBox(width: 8),
                // PGM Monitor (Tally Rojo Live)
                const Expanded(child: _Monitor(label: 'PROGRAM (PGM)', tally: Color(0xFFFF0000))),
                const SizedBox(width: 8),
                // Panel de Control Lateral
                _buildSidePanel(),
              ],
            ),
          ),
          const SizedBox(height: 8),
          
          // ==========================================
          // FILA INFERIOR: MULTIVIEW (CÁMARAS Y RED)
          // ==========================================
          Expanded(
            flex: 2,
            child: Row(
              children: List.generate(6, (index) {
                // Simulamos Tally: Cam 1 en Vivo (Rojo), Cam 2 en Preview (Cyan), resto inactivo (Panel)
                final isPGM = index == 0;
                final isPVW = index == 1;
                final tallyColor = isPGM ? const Color(0xFFFF0000) : (isPVW ? CyberpunkTheme.cyanNeon : CyberpunkTheme.panel);
                
                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(right: index < 5 ? 8.0 : 0),
                    child: _Monitor(
                      label: 'CAM ${index + 1}', 
                      tally: tallyColor,
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidePanel() {
    return Container(
      width: 200,
      decoration: BoxDecoration(
        border: Border.all(color: CyberpunkTheme.cyanNeon, width: 1),
        color: CyberpunkTheme.background.withOpacity(0.8),
      ),
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('MACROS CG', style: CyberpunkTheme.terminalStyle.copyWith(fontWeight: FontWeight.bold, color: CyberpunkTheme.magentaNeon)),
          const Divider(color: CyberpunkTheme.cyanNeon),
          _buildHudButton('LOWER THIRD'),
          _buildHudButton('SCOREBOARD'),
          _buildHudButton('PIP MODE'),
          const Spacer(),
          Text('INSTANT REPLAY', style: CyberpunkTheme.terminalStyle.copyWith(fontWeight: FontWeight.bold, color: const Color(0xFFFF0000))),
          const Divider(color: CyberpunkTheme.cyanNeon),
          _buildHudButton('REC BUFFER', color: const Color(0xFFFF0000)),
          _buildHudButton('PLAY LAST 5s', color: CyberpunkTheme.cyanNeon),
        ],
      ),
    );
  }

  Widget _buildHudButton(String text, {Color? color}) {
    final neon = color ?? CyberpunkTheme.cyanNeon;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: GestureDetector(
        onTap: () { /* Acción del Macro */ },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            border: Border.all(color: neon),
            color: neon.withOpacity(0.1),
          ),
          alignment: Alignment.center,
          child: Text(text, style: CyberpunkTheme.terminalStyle.copyWith(color: neon, shadows: [Shadow(color: neon, blurRadius: 4)])),
        ),
      ),
    );
  }
}

/// Pantalla "de cristal" que recorta visualmente el render del motor base
class _Monitor extends StatelessWidget {
  final String label;
  final Color tally;

  const _Monitor({required this.label, required this.tally});

  @override
  Widget build(BuildContext context) {
    final isInactive = tally == CyberpunkTheme.panel;
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: tally, width: isInactive ? 1 : 2),
        // Fondo totalmente transparente para que se vea el Texture de video detrás
        color: Colors.transparent, 
      ),
      child: Stack(
        children: [
          // Guías de Safe Area simuladas (Cruceta central fotográfica)
          Center(child: Icon(Icons.add, color: Colors.white.withOpacity(0.1), size: 24)),
          
          // Tally Bar Inferior
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: Container(
              color: isInactive ? CyberpunkTheme.panel.withOpacity(0.8) : tally.withOpacity(0.8),
              padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 8),
              child: Text(
                label,
                style: CyberpunkTheme.terminalStyle.copyWith(
                  color: isInactive ? CyberpunkTheme.textMain : CyberpunkTheme.background,
                  fontWeight: FontWeight.bold,
                  shadows: [],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
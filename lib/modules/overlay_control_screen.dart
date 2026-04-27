import 'package:flutter/material.dart';
import 'package:ar_control_live_studio/modules/overlay_module.dart';
import 'package:ar_control_live_studio/services/service_locator.dart';

class OverlayControlScreen extends StatefulWidget {
  const OverlayControlScreen({super.key});

  @override
  State<OverlayControlScreen> createState() => _OverlayControlScreenState();
}

class _OverlayControlScreenState extends State<OverlayControlScreen> {
  final OverlayEngine _overlayEngine = ServiceLocator.overlayEngine;
  final TextEditingController _announcementController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _overlayEngine.addListener(_refresh);
  }

  @override
  void dispose() {
    _overlayEngine.removeListener(_refresh);
    _announcementController.dispose();
    super.dispose();
  }

  void _refresh() {
    if (!mounted) return;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('OVERLAY CONTROL', style: TextStyle(color: Colors.cyanAccent, fontFamily: 'Courier New')),
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.cyanAccent),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('OVERVIEW', style: TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold)),
            const SizedBox(height: 14),
            _buildSwitch('Scoreboard visible', _overlayEngine.showScoreboard, _overlayEngine.toggleScoreboard),
            _buildSwitch('Lower third', _overlayEngine.showLowerThird, _overlayEngine.toggleLowerThird),
            _buildSwitch('Brand bug', _overlayEngine.showBrandBug, _overlayEngine.toggleBrandBug),
            _buildSwitch('Ticker', _overlayEngine.showTicker, _overlayEngine.toggleTicker),
            const SizedBox(height: 20),
            const Text('ANNOUNCEMENT', style: TextStyle(color: Colors.white70, fontFamily: 'Courier New')),
            const SizedBox(height: 8),
            TextField(
              controller: _announcementController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                filled: true,
                fillColor: const Color(0xFF121212),
                hintText: 'Texto para lower third',
                hintStyle: const TextStyle(color: Colors.white38),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () {
                final text = _announcementController.text.trim();
                if (text.isEmpty) return;
                _overlayEngine.showAnnouncement(text);
                _announcementController.clear();
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('ANUNCIO ENVIADO'), backgroundColor: Colors.cyanAccent));
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.cyanAccent),
              child: const Text('ENVIAR ANUNCIO', style: TextStyle(color: Colors.black)),
            ),
            const SizedBox(height: 24),
            const Text('ACTIVE OVERLAY STATE', style: TextStyle(color: Colors.white70, fontFamily: 'Courier New')),
            const SizedBox(height: 12),
            _buildStateTile('Scoreboard', _overlayEngine.showScoreboard),
            _buildStateTile('Lower third', _overlayEngine.showLowerThird),
            _buildStateTile('Brand bug', _overlayEngine.showBrandBug),
            _buildStateTile('Ticker', _overlayEngine.showTicker),
            const SizedBox(height: 20),
            const Text('PREVIEW', style: TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: const Color(0xFF0A0A0A), borderRadius: BorderRadius.circular(12)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_overlayEngine.showBrandBug) const Text('BRAND BUG ACTIVE', style: TextStyle(color: Colors.orangeAccent)),
                  if (_overlayEngine.showScoreboard) const Text('SCOREBOARD ENABLED', style: TextStyle(color: Colors.cyanAccent)),
                  if (_overlayEngine.showTicker) const Text('TICKER ENABLED', style: TextStyle(color: Colors.greenAccent)),
                  if (_overlayEngine.showLowerThird) Text('LOWER THIRD: ${_overlayEngine.announcementText}', style: const TextStyle(color: Colors.white70)),
                  if (!_overlayEngine.showBrandBug && !_overlayEngine.showScoreboard && !_overlayEngine.showTicker && !_overlayEngine.showLowerThird)
                    const Text('NO OVERLAYS ACTIVE', style: TextStyle(color: Colors.white38)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSwitch(String title, bool value, VoidCallback onChanged) {
    return SwitchListTile(
      title: Text(title, style: const TextStyle(color: Colors.white)),
      value: value,
      onChanged: (_) => onChanged(),
      activeColor: Colors.cyanAccent,
      tileColor: const Color(0xFF101010),
      contentPadding: const EdgeInsets.symmetric(horizontal: 0),
    );
  }

  Widget _buildStateTile(String label, bool active) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(active ? Icons.check_circle : Icons.cancel, color: active ? Colors.greenAccent : Colors.white24, size: 18),
          const SizedBox(width: 8),
          Text(label, style: TextStyle(color: active ? Colors.white : Colors.white38)),
        ],
      ),
    );
  }
}

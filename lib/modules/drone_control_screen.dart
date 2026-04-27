import 'dart:async';
import 'package:flutter/material.dart';
import 'package:ar_control_live_studio/services/service_locator.dart';

class DroneControlScreen extends StatefulWidget {
  const DroneControlScreen({super.key});

  @override
  State<DroneControlScreen> createState() => _DroneControlScreenState();
}

class _DroneControlScreenState extends State<DroneControlScreen> {
  final drone = ServiceLocator.droneEngine;
  final TextEditingController _ipController = TextEditingController();
  late final StreamSubscription<Map<String, dynamic>> _telemetrySubscription;
  Map<String, dynamic> _telemetry = {};

  @override
  void initState() {
    super.initState();
    _telemetrySubscription = drone.telemetryStream.listen((data) {
      if (!mounted) return;
      setState(() => _telemetry = data);
    });
    _telemetry = {
      'connected': drone.connected,
      'model': drone.model,
      'ip': drone.ip,
      'altitude': drone.altitude,
      'speed': drone.speed,
      'battery': drone.battery,
      'status': drone.status,
    };
  }

  @override
  void dispose() {
    _telemetrySubscription.cancel();
    _ipController.dispose();
    super.dispose();
  }

  void _connectDrone() {
    final ip = _ipController.text.trim();
    if (ip.isEmpty) return;
    drone.connectDrone(ip);
    _ipController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final connected = _telemetry['connected'] as bool? ?? false;
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('DRONE CONTROL', style: TextStyle(color: Colors.cyanAccent, fontFamily: 'Courier New')),
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.cyanAccent),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatusCard(),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _ipController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'DRONE IP',
                      labelStyle: TextStyle(color: Colors.white54),
                      filled: true,
                      fillColor: Color(0xFF101010),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: connected ? null : _connectDrone,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.cyanAccent),
                  child: const Text('CONNECT', style: TextStyle(color: Colors.black)),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Text('COMMANDS', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _buildCommandButton('TAKE OFF', connected ? () => drone.sendMovementCommand(0, 0, 0, 1) : null),
                _buildCommandButton('RETURN HOME', connected ? drone.returnHome : null),
                _buildCommandButton('EMERGENCY', connected ? drone.emergencyLand : null),
                _buildCommandButton('PITCH +', connected ? () => drone.sendMovementCommand(0.5, 0, 0, 0) : null),
                _buildCommandButton('ROLL +', connected ? () => drone.sendMovementCommand(0, 0.5, 0, 0) : null),
                _buildCommandButton('YAW +', connected ? () => drone.sendMovementCommand(0, 0, 0.5, 0) : null),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: const Color(0xFF0D0D0D), borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('STATUS: ${_telemetry['status'] ?? 'idle'}', style: const TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('MODEL: ${_telemetry['model'] ?? 'NONE'}', style: const TextStyle(color: Colors.white70)),
          const SizedBox(height: 4),
          Text('IP: ${_telemetry['ip'] ?? '0.0.0.0'}', style: const TextStyle(color: Colors.white70)),
          const SizedBox(height: 4),
          Text('ALTITUDE: ${(_telemetry['altitude'] as double?)?.toStringAsFixed(1) ?? '0.0'} m', style: const TextStyle(color: Colors.white70)),
          const SizedBox(height: 4),
          Text('SPEED: ${(_telemetry['speed'] as double?)?.toStringAsFixed(1) ?? '0.0'} m/s', style: const TextStyle(color: Colors.white70)),
          const SizedBox(height: 4),
          Text('BATTERY: ${_telemetry['battery'] ?? 0}%', style: const TextStyle(color: Colors.white70)),
        ],
      ),
    );
  }

  Widget _buildCommandButton(String label, VoidCallback? onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: onPressed != null ? Colors.blueAccent : Colors.white10,
      ),
      child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 12)),
    );
  }
}

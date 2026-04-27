import 'package:flutter/material.dart';
import 'package:ar_control_live_studio/services/service_locator.dart';
import 'package:ar_control_live_studio/modules/ndi_stream_engine.dart';

class NDIControlScreen extends StatefulWidget {
  const NDIControlScreen({super.key});

  @override
  State<NDIControlScreen> createState() => _NDIControlScreenState();
}

class _NDIControlScreenState extends State<NDIControlScreen> {
  final NDIStreamEngine _ndiEngine = ServiceLocator.ndiStreamEngine;
  late Stream<Map<String, dynamic>> _statusStream;
  late Stream<List<String>> _sourcesStream;

  Map<String, dynamic> _currentStatus = {};
  List<String> _availableSources = [];

  @override
  void initState() {
    super.initState();
    _statusStream = _ndiEngine.streamStatus;
    _sourcesStream = _ndiEngine.sourcesStream;

    _statusStream.listen((status) {
      if (mounted) {
        setState(() {
          _currentStatus = status;
        });
      }
    });

    _sourcesStream.listen((sources) {
      if (mounted) {
        setState(() {
          _availableSources = sources;
        });
      }
    });

    // Initialize NDI
    _ndiEngine.initialize();
  }

  @override
  Widget build(BuildContext context) {
    final isInitialized = _currentStatus['initialized'] as bool? ?? false;
    final isStreaming = _currentStatus['streaming'] as bool? ?? false;
    final currentSource = _currentStatus['source'] as String? ?? '';

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('NDI STREAM CONTROL', style: TextStyle(color: Colors.cyanAccent)),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade900,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        isInitialized ? Icons.wifi : Icons.wifi_off,
                        color: isInitialized ? Colors.greenAccent : Colors.redAccent,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'NDI ${isInitialized ? 'CONNECTED' : 'DISCONNECTED'}',
                        style: TextStyle(
                          color: isInitialized ? Colors.greenAccent : Colors.redAccent,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  if (isStreaming) ...[
                    const SizedBox(height: 8),
                    Text(
                      'STREAMING: $currentSource',
                      style: const TextStyle(color: Colors.cyanAccent, fontSize: 12),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Available Sources
            const Text(
              'AVAILABLE NDI SOURCES',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            Expanded(
              child: ListView.builder(
                itemCount: _availableSources.length,
                itemBuilder: (context, index) {
                  final source = _availableSources[index];
                  final isActive = source == currentSource;

                  return Card(
                    color: isActive ? Colors.cyan.shade900 : Colors.grey.shade800,
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      title: Text(
                        source,
                        style: TextStyle(
                          color: isActive ? Colors.cyanAccent : Colors.white,
                          fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      trailing: isActive
                          ? const Icon(Icons.stop, color: Colors.redAccent)
                          : const Icon(Icons.play_arrow, color: Colors.greenAccent),
                      onTap: () {
                        if (isActive) {
                          _ndiEngine.stopStream();
                        } else {
                          _ndiEngine.startStream(source);
                        }
                      },
                    ),
                  );
                },
              ),
            ),

            // Stream Controls
            if (isInitialized) ...[
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade900,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'STREAM SETTINGS',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: isStreaming ? null : () => _showSettingsDialog(context),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue.shade900,
                            ),
                            child: const Text('CONFIG'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: isStreaming ? _ndiEngine.stopStream : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isStreaming ? Colors.red.shade900 : Colors.grey.shade700,
                            ),
                            child: Text(isStreaming ? 'STOP' : 'STOPPED'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showSettingsDialog(BuildContext context) {
    final settings = _currentStatus['settings'] as Map<String, dynamic>? ?? {};

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey.shade900,
        title: const Text('NDI Stream Settings', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildSettingDropdown('Resolution', ['720x480', '1280x720', '1920x1080'], settings['resolution']?.toString()),
            _buildSettingDropdown('Frame Rate', ['24', '25', '30', '60'], settings['frameRate']?.toString()),
            _buildSettingDropdown('Codec', ['H.264', 'H.265'], settings['codec']?.toString()),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('CANCEL', style: TextStyle(color: Colors.white)),
          ),
          TextButton(
            onPressed: () {
              // Apply settings would be implemented here
              Navigator.of(context).pop();
            },
            child: const Text('APPLY', style: TextStyle(color: Colors.cyanAccent)),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingDropdown(String label, List<String> options, String? currentValue) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(label, style: const TextStyle(color: Colors.white)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: DropdownButton<String>(
              value: currentValue,
              dropdownColor: Colors.grey.shade800,
              style: const TextStyle(color: Colors.white),
              items: options.map((option) {
                return DropdownMenuItem(
                  value: option,
                  child: Text(option),
                );
              }).toList(),
              onChanged: (value) {
                // Update setting would be implemented here
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    // Don't dispose the engine here as it's a singleton
    super.dispose();
  }
}
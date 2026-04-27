import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ar_control_live_studio/core/network/node_discovery_service.dart';
import 'package:ar_control_live_studio/core/switcher_engine.dart';
import 'package:ar_control_live_studio/core/hal.dart';
import 'package:ar_control_live_studio/core/theme/cyberpunk_theme.dart';

class RemoteCameraNodeView extends ConsumerWidget { 
  const RemoteCameraNodeView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nodes = ref.watch(nodeDiscoveryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text("RED DE NODOS AR", style: TextStyle(color: CyberpunkTheme.neonCyan)),
        backgroundColor: CyberpunkTheme.black,
      ),
      body: ListView.builder(
        itemCount: nodes.length,
        itemBuilder: (context, index) {
          final node = nodes[index];
          return ListTile(
            title: Text(node.name, style: const TextStyle(color: Colors.white)),
            subtitle: Text(node.ip, style: const TextStyle(color: CyberpunkTheme.neonPurple)),
            trailing: IconButton(
              icon: const Icon(Icons.add_circle, color: CyberpunkTheme.neonCyan),
              onPressed: () {
                // Crear, inicializar y agregar la fuente remota
                final remoteSource = RemoteVideoSourceHAL(id: node.id, label: node.name, ip: node.ip);
                ref.read(switcherEngineProvider.notifier).addSource(remoteSource);
                remoteSource.initialize();
                Navigator.pop(context);
              },
            ),
          );
        },
      ),
    );
  }
}
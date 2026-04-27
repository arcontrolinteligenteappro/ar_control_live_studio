import 'package:ar_control_live_studio/core/active_nodes_provider.dart';
import 'package:ar_control_live_studio/core/performance_monitor_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'cyberpunk_theme.dart';

class StatusView extends ConsumerWidget {
  const StatusView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeNodes = ref.watch(activeNodesProvider).values.toList();
    final performanceStats = ref.watch(performanceMonitorProvider);

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: CyberpunkTheme.panel.withOpacity(0.8),
        border: Border.all(color: CyberpunkTheme.magentaNeon, width: 1),
      ),
      child: Column(
        children: [
          Text('SYSTEM_STATUS // REAL-TIME', style: CyberpunkTheme.terminalStyle.copyWith(color: CyberpunkTheme.magentaNeon)),
          const Divider(color: CyberpunkTheme.magentaNeon),
          const SizedBox(height: 8),
          // Performance Section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _PerformanceIndicator(label: 'CPU', value: performanceStats.cpuLoad),
              _PerformanceIndicator(label: 'GPU', value: performanceStats.gpuLoad),
              _PerformanceIndicator(label: 'NET', value: performanceStats.networkThroughput / 1000, unit: 'Gbps'),
            ],
          ),
          const Divider(color: CyberpunkTheme.magentaNeon, height: 24),
          // Network Nodes Section
          Align(
            alignment: Alignment.centerLeft,
            child: Text('// CONNECTED_NODES (${activeNodes.length})', style: CyberpunkTheme.terminalStyle.copyWith(color: Colors.grey)),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              itemCount: activeNodes.length,
              itemBuilder: (context, index) {
                final node = activeNodes[index];
                return Text(
                  '>> [${node.nodeType}] ${node.ipAddress} - STATUS: ${node.status.toUpperCase()}',
                  style: CyberpunkTheme.terminalStyle.copyWith(color: CyberpunkTheme.cyanNeon),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _PerformanceIndicator extends StatelessWidget {
  final String label;
  final double value;
  final String? unit;

  const _PerformanceIndicator({required this.label, required this.value, this.unit});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: CyberpunkTheme.terminalStyle.copyWith(color: Colors.grey)),
        const SizedBox(height: 4),
        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 60,
              height: 60,
              child: CircularProgressIndicator(
                value: unit != null ? null : value,
                strokeWidth: 4,
                backgroundColor: CyberpunkTheme.cyanNeon.withOpacity(0.2),
                valueColor: const AlwaysStoppedAnimation<Color>(CyberpunkTheme.cyanNeon),
              ),
            ),
            Text(
              unit != null ? value.toStringAsFixed(1) : '${(value * 100).toStringAsFixed(0)}%',
              style: CyberpunkTheme.terminalStyle.copyWith(fontSize: 14, color: Colors.white),
            ),
          ],
        ),
        if (unit != null)
          Padding(
            padding: const EdgeInsets.only(top: 4.0),
            child: Text(unit!, style: CyberpunkTheme.terminalStyle.copyWith(color: Colors.grey, fontSize: 10)),
          ),
      ],
    );
  }
}
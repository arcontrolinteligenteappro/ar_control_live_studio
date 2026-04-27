import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

@immutable
class PerformanceStats {
  final double cpuLoad; // 0.0 to 1.0
  final double gpuLoad; // 0.0 to 1.0
  final double networkThroughput; // in Mbps

  const PerformanceStats({
    this.cpuLoad = 0.0,
    this.gpuLoad = 0.0,
    this.networkThroughput = 0.0,
  });
}

class PerformanceMonitorService extends StateNotifier<PerformanceStats> {
  Timer? _timer;
  final _random = Random();

  PerformanceMonitorService() : super(const PerformanceStats()) {
    _startMonitoring();
  }

  void _startMonitoring() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      // En una app real, aquí se llamarían a APIs nativas para obtener datos reales.
      // Por ahora, simulamos los datos.
      state = PerformanceStats(
        cpuLoad: 0.2 + _random.nextDouble() * 0.3, // Simula carga entre 20% y 50%
        gpuLoad: 0.4 + _random.nextDouble() * 0.4, // Simula carga entre 40% y 80%
        networkThroughput: 50 + _random.nextDouble() * 150, // Simula entre 50 y 200 Mbps
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

final performanceMonitorProvider = StateNotifierProvider<PerformanceMonitorService, PerformanceStats>((ref) {
  return PerformanceMonitorService();
});
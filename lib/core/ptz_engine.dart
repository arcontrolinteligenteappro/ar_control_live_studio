import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

@immutable
class PtzPosition {
  final double pan;
  final double tilt;
  final double zoom;
  const PtzPosition({this.pan = 0.0, this.tilt = 0.0, this.zoom = 0.0});
}

@immutable
class PtzPreset {
  final String name;
  final PtzPosition position;
  const PtzPreset({required this.name, required this.position});
}

@immutable
class PtzEngineState {
  final List<PtzPreset> presets;
  // Simulamos la posición actual, ya que las cámaras no suelen reportarla.
  final PtzPosition currentPosition;

  const PtzEngineState({
    this.presets = const [],
    this.currentPosition = const PtzPosition(),
  });

  PtzEngineState copyWith({
    List<PtzPreset>? presets,
    PtzPosition? currentPosition,
  }) {
    return PtzEngineState(
      presets: presets ?? this.presets,
      currentPosition: currentPosition ?? this.currentPosition,
    );
  }
}

class PtzEngine extends StateNotifier<PtzEngineState> {
  PtzEngine() : super(const PtzEngineState()) {
    // En una app real, se cargarían los presets desde el almacenamiento.
    state = state.copyWith(presets: [
      const PtzPreset(name: 'Wide', position: PtzPosition(zoom: -1.0)),
      const PtzPreset(name: 'Tight', position: PtzPosition(zoom: 1.0)),
    ]);
  }

  // Simula el cambio de posición de la cámara basado en comandos de velocidad.
  void move(double panSpeed, double tiltSpeed, double zoomSpeed) {
    final current = state.currentPosition;
    state = state.copyWith(
      currentPosition: PtzPosition(
        pan: (current.pan + panSpeed * 0.01).clamp(-1.0, 1.0),
        tilt: (current.tilt + tiltSpeed * 0.01).clamp(-1.0, 1.0),
        zoom: (current.zoom + zoomSpeed * 0.01).clamp(-1.0, 1.0),
      ),
    );
  }

  void savePreset(String name) {
    final newPreset = PtzPreset(name: name, position: state.currentPosition);
    final newPresets = state.presets.where((p) => p.name != name).toList()..add(newPreset);
    state = state.copyWith(presets: newPresets);
  }
}

final ptzEngineProvider = StateNotifierProvider<PtzEngine, PtzEngineState>((ref) {
  return PtzEngine();
});
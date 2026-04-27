import 'dart:async';

abstract class HAL {
  bool get isInitialized;
  Future<void> initialize();
  Future<void> dispose();

  // Control de Cámaras (PTZ)
  Future<void> controlPTZ(String command, double speed);
  
  // MIDI y Eventos
  Stream<dynamic> get midiEvents;
  Future<void> sendMIDICommand(List<int> bytes);

  // Acceso a Texturas Nativas (CCTV/Drones)
  int? get textureId;
}

class HALFactory {
  static HAL createForPlatform() {
    // Aquí puedes retornar implementaciones para Android/Windows
    // Por ahora lanzamos error para identificar si falta la implementación
    throw UnimplementedError("Implementación HAL no encontrada");
  }
}
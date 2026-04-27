import 'package:flutter/foundation.dart';

// Clase base para todo el hardware
abstract class HAL {
  void dispose();
  
  // Firma del método PTZ para que la capa de hardware lo reconozca
  Future<void> controlPTZ({required double pan, required double tilt, required double zoom});
}

// Clase base para las fuentes de video
abstract class VideoSourceHAL extends HAL {
  // Obliga a los hijos a implementar el notificador del ID de textura
  ValueNotifier<int?> get textureIdNotifier;
}
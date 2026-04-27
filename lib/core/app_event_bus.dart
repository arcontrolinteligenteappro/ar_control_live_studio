import 'dart:async';

class AppEventBus {
  // Singleton Pattern Corregido
  AppEventBus._internal();
  static final AppEventBus instance = AppEventBus._internal();

  final _controller = StreamController<dynamic>.broadcast();

  // Escuchar eventos
  Stream<T> on<T>() => _controller.stream.where((e) => e is T).cast<T>();
  
  // Disparar eventos
  void fire(dynamic event) => _controller.add(event);
}

// --- CLASES DE EVENTOS DE SISTEMA ---
class StreamStateChangedEvent { 
  final bool isLive; 
  StreamStateChangedEvent(this.isLive); 
}

class CameraSourceChangedEvent { 
  final String sourceId; 
  CameraSourceChangedEvent(this.sourceId); 
}

class PTZStatusChangedEvent { 
  final String status; 
  PTZStatusChangedEvent(this.status); 
}

class CloudSyncStatusEvent {
  final bool isSynced;
  CloudSyncStatusEvent(this.isSynced);
}
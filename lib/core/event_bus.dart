import 'dart:async';

/// Bus de eventos global para AR CONTROL LIVE STUDIO
class AppEventBus {
  static final AppEventBus _instance = AppEventBus._internal();
  static AppEventBus get instance => _instance;
  AppEventBus._internal();

  final _streamController = StreamController<dynamic>.broadcast();

  void fire(dynamic event) {
    _streamController.add(event);
  }

  Stream<T> on<T>() {
    return _streamController.stream.where((event) => event is T).cast<T>();
  }
}

/// Evento de cambio de estado de PTZ
class PTZStatusChangedEvent {
  final bool connected;
  final double pan;
  final double tilt;
  final double zoom;
  final String address;

  PTZStatusChangedEvent({
    required this.connected,
    required this.pan,
    required this.tilt,
    required this.zoom,
    required this.address,
  });
}
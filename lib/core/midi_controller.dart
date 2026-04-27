import 'dart:async';
import 'package:flutter/foundation.dart';

/// Definición del evento MIDI (Faltante en tu arquitectura original)
class MIDIEvent {
  final int channel;
  final int note;
  final int velocity;

  MIDIEvent({required this.channel, required this.note, required this.velocity});
}

/// Interfaz abstracta del HAL para MIDI (Requerido por el controlador)
abstract class HAL {
  Stream<MIDIEvent> get midiEvents;
  Future<void> sendMIDICommand(int channel, int note, int velocity);
}

/// MIDIController: Controlador para dispositivos MIDI.
/// Gestiona entrada/salida MIDI via HAL.
class MIDIController {
  final HAL _hal;

  MIDIController(this._hal);

  // FIX: Usamos StreamSubscription en lugar de Stream para poder cancelarlo correctamente
  StreamSubscription<MIDIEvent>? _midiSubscription;

  /// Inicia escucha de eventos MIDI.
  void startListening() {
    _midiSubscription = _hal.midiEvents.listen((event) {
      _handleMIDIEvent(event);
    });
  }

  /// Maneja evento MIDI.
  void _handleMIDIEvent(MIDIEvent event) {
    debugPrint('MIDI Event: ch=${event.channel}, note=${event.note}, vel=${event.velocity}');
    // Lógica: mapear a controles (ej: note 60 = play)
  }

  /// Envía nota MIDI.
  Future<void> sendNote(int channel, int note, int velocity) async {
    await _hal.sendMIDICommand(channel, note, velocity);
  }

  /// Envía control change.
  Future<void> sendControlChange(int channel, int controller, int value) async {
    // Placeholder: si HAL soporta
    debugPrint('CC: ch=$channel, ctrl=$controller, val=$value');
  }

  /// Detiene escucha.
  void stopListening() {
    // FIX: Ahora sí podemos cancelar la escucha para evitar fugas de memoria
    _midiSubscription?.cancel();
    _midiSubscription = null;
    debugPrint('Escucha MIDI detenida.');
  }
}
import 'dart:async';
import 'package:flutter/foundation.dart'; // Import crítico para kDebugMode y debugPrint

/// DJEngine: Motor para control de DJ y mezcla de audio.
/// Gestiona decks, mezcladores, efectos y transiciones.
/// Independiente del Isolate de Audio principal.
class DJEngine {
  static final DJEngine _instance = DJEngine._internal();

  factory DJEngine() => _instance;

  DJEngine._internal();

  bool _isActive = false;
  double _crossfader = 0.5; // 0.0 left, 1.0 right
  double _masterVolume = 1.0;
  final Map<String, double> _deckVolumes = {'deck1': 1.0, 'deck2': 1.0};

  /// Inicia el motor DJ.
  void start() {
    _isActive = true;
    debugPrint('DJ Engine started');
  }

  /// Detiene el motor DJ.
  void stop() {
    _isActive = false;
    debugPrint('DJ Engine stopped');
  }

  /// Carga pista en deck.
  Future<void> loadTrack(String deck, String trackPath) async {
    // Placeholder: cargar audio
    debugPrint('Loading $trackPath on $deck');
  }

  /// Reproduce deck.
  void play(String deck) {
    if (_isActive) {
      debugPrint('Playing $deck');
    }
  }

  /// Pausa deck.
  void pause(String deck) {
    debugPrint('Pausing $deck');
  }

  /// Ajusta crossfader.
  void setCrossfader(double value) {
    _crossfader = value.clamp(0.0, 1.0);
    debugPrint('Crossfader: $_crossfader');
  }

  /// Ajusta volumen master.
  void setMasterVolume(double volume) {
    _masterVolume = volume.clamp(0.0, 1.0);
    debugPrint('Master volume: $_masterVolume');
  }

  /// Ajusta volumen de deck.
  void setDeckVolume(String deck, double volume) {
    _deckVolumes[deck] = volume.clamp(0.0, 1.0);
    debugPrint('$deck volume: ${_deckVolumes[deck]}');
  }

  /// Aplica efecto (ej: echo, reverb).
  void applyEffect(String effect, double intensity) {
    debugPrint('Applying $effect with intensity $intensity');
  }

  /// Transición automática.
  void autoTransition(String fromDeck, String toDeck, Duration duration) {
    if (kDebugMode) {
      debugPrint('Auto transition from $fromDeck to $toDeck in $duration');
    }
  }

  /// Estado actual.
  Map<String, dynamic> getStatus() {
    return {
      'active': _isActive,
      'crossfader': _crossfader,
      'masterVolume': _masterVolume,
      'deckVolumes': _deckVolumes,
    };
  }
}
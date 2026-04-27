import 'package:flutter/foundation.dart';

class DJTrack {
  final String id;
  final String title;
  final String artist;
  final String filePath;
  final Duration duration;
  int bpm = 120;
  bool isLoaded = false;
  double tempo = 1.0;

  DJTrack({
    required this.id,
    required this.title,
    required this.artist,
    required this.filePath,
    required this.duration,
  });
}

class DJDeck {
  final int id;
  DJTrack? currentTrack;
  double volume = 0.8;
  double pitch = 0.0; // -6 to +6
  bool isCued = false;
  bool isLoaded = false;
  Duration currentPosition = Duration.zero;
  bool isPlaying = false;
  bool cueCue = false; // Headphones
  List<bool> hotCues = List.filled(8, false); // Hot cue markers

  DJDeck({required this.id});
}

class DJMix {
  String id;
  String name;
  double crossfaderPosition = 0.5; // 0 = deck1, 1 = deck2
  double masterVolume = 1.0;
  final List<DJTrack> playlist = [];
  double bassLevel = 0.0;
  double midLevel = 0.0;
  double trebleLevel = 0.0;

  DJMix({
    required this.id,
    required this.name,
  });
}

class MIDIController {
  final String deviceName;
  final String deviceId;
  bool isConnected = false;
  final Map<int, dynamic> controlValues = {};

  MIDIController({
    required this.deviceName,
    required this.deviceId,
  });
}

class DJProEngineAdvanced extends ChangeNotifier {
  // Decks
  late DJDeck _deck1;
  late DJDeck _deck2;
  
  // Mix control
  late DJMix _currentMix;
  
  // MIDI
  final List<MIDIController> _midiControllers = [];
  MIDIController? _activeMIDI;
  
  // Visualization
  final List<double> _spectrum = List.filled(32, 0.0);
  double _waveformPeak = 0.0;
  
  // Performance
  bool _syncEnabled = true;
  bool _beatGridVisible = true;
  double _masterBPM = 120.0;
  
  // Library
  final List<DJTrack> _trackLibrary = [];
  
  // Getters
  DJDeck get deck1 => _deck1;
  DJDeck get deck2 => _deck2;
  DJMix get currentMix => _currentMix;
  List<MIDIController> get midiControllers => _midiControllers;
  MIDIController? get activeMIDI => _activeMIDI;
  List<double> get spectrum => _spectrum;
  double get waveformPeak => _waveformPeak;
  bool get syncEnabled => _syncEnabled;
  double get masterBPM => _masterBPM;
  List<DJTrack> get trackLibrary => _trackLibrary;

  DJProEngineAdvanced() {
    _initializeDecks();
    _initializeMix();
  }

  void _initializeDecks() {
    _deck1 = DJDeck(id: 1);
    _deck2 = DJDeck(id: 2);
  }

  void _initializeMix() {
    _currentMix = DJMix(id: 'mix_1', name: 'Default Mix');
  }

  // ==================== DECK CONTROL ====================

  void loadTrackOnDeck(int deckId, DJTrack track) {
    final deck = deckId == 1 ? _deck1 : _deck2;
    deck.currentTrack = track;
    deck.isLoaded = true;
    notifyListeners();
  }

  void playDeck(int deckId) {
    final deck = deckId == 1 ? _deck1 : _deck2;
    if (deck.isLoaded) {
      deck.isPlaying = true;
      notifyListeners();
    }
  }

  void pauseDeck(int deckId) {
    final deck = deckId == 1 ? _deck1 : _deck2;
    deck.isPlaying = false;
    notifyListeners();
  }

  void setDeckVolume(int deckId, double volume) {
    final deck = deckId == 1 ? _deck1 : _deck2;
    deck.volume = volume.clamp(0.0, 1.0);
    notifyListeners();
  }

  void setPitch(int deckId, double pitch) {
    final deck = deckId == 1 ? _deck1 : _deck2;
    deck.pitch = pitch.clamp(-6.0, 6.0);
    if (deck.currentTrack != null) {
      final baseTempo = deck.currentTrack!.tempo;
      deck.currentTrack!.tempo = baseTempo * (1.0 + (pitch / 12.0));
    }
    notifyListeners();
  }

  void setCue(int deckId) {
    final deck = deckId == 1 ? _deck1 : _deck2;
    deck.isCued = true;
    notifyListeners();
  }

  void setCueCue(int deckId, bool enabled) {
    final deck = deckId == 1 ? _deck1 : _deck2;
    deck.cueCue = enabled;
    notifyListeners();
  }

  void setHotCue(int deckId, int cueIndex) {
    final deck = deckId == 1 ? _deck1 : _deck2;
    if (cueIndex >= 0 && cueIndex < 8) {
      deck.hotCues[cueIndex] = !deck.hotCues[cueIndex];
      notifyListeners();
    }
  }

  // ==================== MIX CONTROL ====================

  void setCrossfader(double position) {
    _currentMix.crossfaderPosition = position.clamp(0.0, 1.0);
    notifyListeners();
  }

  void setMasterVolume(double volume) {
    _currentMix.masterVolume = volume.clamp(0.0, 1.0);
    notifyListeners();
  }

  void setEQ(double bass, double mid, double treble) {
    _currentMix.bassLevel = bass.clamp(-12.0, 12.0);
    _currentMix.midLevel = mid.clamp(-12.0, 12.0);
    _currentMix.trebleLevel = treble.clamp(-12.0, 12.0);
    notifyListeners();
  }

  // ==================== SYNC & BPM ====================

  void enableSync() {
    _syncEnabled = true;
    notifyListeners();
  }

  void disableSync() {
    _syncEnabled = false;
    notifyListeners();
  }

  void setMasterBPM(double bpm) {
    _masterBPM = bpm.clamp(80.0, 200.0);
    if (_syncEnabled) {
      if (_deck1.currentTrack != null) _deck1.currentTrack!.bpm = _masterBPM.toInt();
      if (_deck2.currentTrack != null) _deck2.currentTrack!.bpm = _masterBPM.toInt();
    }
    notifyListeners();
  }

  void syncDeck(int deckId) {
    final deck = deckId == 1 ? _deck1 : _deck2;
    if (deck.currentTrack != null) {
      deck.currentTrack!.bpm = _masterBPM.toInt();
      notifyListeners();
    }
  }

  // ==================== MIDI CONTROL ====================

  void connectMIDIController(MIDIController controller) {
    _midiControllers.add(controller);
    controller.isConnected = true;
    _activeMIDI = controller;
    notifyListeners();
  }

  void disconnectMIDIController(String deviceId) {
    _midiControllers.removeWhere((c) => c.deviceId == deviceId && (c.isConnected = false));
    if (_activeMIDI?.deviceId == deviceId) {
      _activeMIDI = _midiControllers.isNotEmpty ? _midiControllers.first : null;
    }
    notifyListeners();
  }

  void handleMIDIInput(String deviceId, int control, double value) {
    final controller = _midiControllers.firstWhere(
      (c) => c.deviceId == deviceId,
      orElse: () => throw Exception('MIDI device not found'),
    );

    controller.controlValues[control] = value;

    // Map MIDI controls to DJ functions
    _mapMIDIToDJFunction(control, value);
    notifyListeners();
  }

  void _mapMIDIToDJFunction(int control, double value) {
    // Example MIDI mapping (customizable)
    // Control 1-8: Hot cues deck 1
    // Control 9-16: Hot cues deck 2
    // Control 17: Crossfader
    // Control 18: Master volume
    
    if (control >= 1 && control <= 8) {
      setHotCue(1, control - 1);
    } else if (control >= 9 && control <= 16) {
      setHotCue(2, control - 9);
    } else if (control == 17) {
      setCrossfader(value);
    } else if (control == 18) {
      setMasterVolume(value);
    }
  }

  // ==================== VISUALIZATION ====================

  void updateSpectrum(List<double> spectrumData) {
    if (spectrumData.length == _spectrum.length) {
      for (int i = 0; i < _spectrum.length; i++) {
        _spectrum[i] = spectrumData[i].clamp(0.0, 1.0);
      }
      _waveformPeak = _spectrum.reduce((a, b) => a > b ? a : b);
      notifyListeners();
    }
  }

  // ==================== LIBRARY ====================

  void addTrackToLibrary(DJTrack track) {
    _trackLibrary.add(track);
    notifyListeners();
  }

  void removeTrackFromLibrary(String trackId) {
    _trackLibrary.removeWhere((t) => t.id == trackId);
    notifyListeners();
  }

  List<DJTrack> searchTracks(String query) {
    final q = query.toLowerCase();
    return _trackLibrary
        .where((t) => t.title.toLowerCase().contains(q) || t.artist.toLowerCase().contains(q))
        .toList();
  }

  void addToPlaylist(DJTrack track) {
    _currentMix.playlist.add(track);
    notifyListeners();
  }

  // ==================== PERFORMANCE ====================

  Map<String, dynamic> getPerformanceStats() {
    return {
      'masterBPM': _masterBPM,
      'syncEnabled': _syncEnabled,
      'deck1': {
        'track': _deck1.currentTrack?.title ?? 'EMPTY',
        'volume': _deck1.volume,
        'pitch': _deck1.pitch,
        'isPlaying': _deck1.isPlaying,
      },
      'deck2': {
        'track': _deck2.currentTrack?.title ?? 'EMPTY',
        'volume': _deck2.volume,
        'pitch': _deck2.pitch,
        'isPlaying': _deck2.isPlaying,
      },
      'crossfader': _currentMix.crossfaderPosition,
      'midiDevices': _midiControllers.length,
    };
  }

  void toggleBeatGrid() {
    _beatGridVisible = !_beatGridVisible;
    notifyListeners();
  }

  @override
  void dispose() {
    for (final controller in _midiControllers) {
      controller.isConnected = false;
    }
    super.dispose();
  }
}

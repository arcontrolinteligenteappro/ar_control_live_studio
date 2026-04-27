import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

// --- Definición de Acciones Mapeables ---

@immutable
abstract class MappableAction {
  final String id;
  final String description;
  const MappableAction({required this.id, required this.description});

  Map<String, dynamic> toJson();

  static MappableAction fromJson(Map<String, dynamic> json) {
    switch (json['type']) {
      case 'VolumeAction':
        return VolumeAction.fromJson(json);
      case 'MacroTriggerAction':
        return MacroTriggerAction.fromJson(json);
      default:
        throw Exception('Unknown MappableAction type: ${json['type']}');
    }
  }
}

class VolumeAction extends MappableAction {
  const VolumeAction({required String sourceId}) : super(id: sourceId, description: 'Volume: $sourceId');

  @override
  Map<String, dynamic> toJson() => {
        'type': 'VolumeAction',
        'id': id,
      };

  factory VolumeAction.fromJson(Map<String, dynamic> json) {
    return VolumeAction(sourceId: json['id']);
  }
}

class MacroTriggerAction extends MappableAction {
  const MacroTriggerAction({required String macroName}) : super(id: macroName, description: 'Macro: $macroName');

  @override
  Map<String, dynamic> toJson() => {
        'type': 'MacroTriggerAction',
        'id': id,
      };

  factory MacroTriggerAction.fromJson(Map<String, dynamic> json) {
    return MacroTriggerAction(macroName: json['id']);
  }
}

// --- Estado y Notificador del Mapeo ---

@immutable
class MidiMappingState {
  final Map<int, MappableAction> noteMappings; // Note Number -> Action
  final Map<int, MappableAction> ccMappings;   // CC Number -> Action

  const MidiMappingState({
    this.noteMappings = const {},
    this.ccMappings = const {},
  });

  MidiMappingState copyWith({
    Map<int, MappableAction>? noteMappings,
    Map<int, MappableAction>? ccMappings,
  }) {
    return MidiMappingState(
      noteMappings: noteMappings ?? this.noteMappings,
      ccMappings: ccMappings ?? this.ccMappings,
    );
  }

  Map<String, dynamic> toJson() => {
        'noteMappings': noteMappings.map((key, value) => MapEntry(key.toString(), value.toJson())),
        'ccMappings': ccMappings.map((key, value) => MapEntry(key.toString(), value.toJson())),
      };

  factory MidiMappingState.fromJson(Map<String, dynamic> json) {
    return MidiMappingState(
      noteMappings: (json['noteMappings'] as Map<String, dynamic>).map(
        (key, value) => MapEntry(int.parse(key), MappableAction.fromJson(value)),
      ),
      ccMappings: (json['ccMappings'] as Map<String, dynamic>).map(
        (key, value) => MapEntry(int.parse(key), MappableAction.fromJson(value)),
      ),
    );
  }
}

class MidiMappingNotifier extends StateNotifier<MidiMappingState> {
  MidiMappingNotifier() : super(const MidiMappingState()) {
    loadMappings();
  }

  void _loadDefaultMappings() {
    // Carga los mapeos por defecto que teníamos antes.
    state = state.copyWith(
      ccMappings: {
        7: const VolumeAction(sourceId: 'source_at_index_0'), // Placeholder, se resolverá en MidiService
        8: const VolumeAction(sourceId: 'source_at_index_1'),
        9: const VolumeAction(sourceId: 'source_at_index_2'),
      },
      noteMappings: {
        36: const MacroTriggerAction(macroName: 'CAM 1 -> CAM 2 (CUT)'),
      },
    );
  }

  void mapNoteToAction(int note, MappableAction action) {
    state = state.copyWith(noteMappings: {...state.noteMappings, note: action});
    debugPrint("MIDI Mapping: Nota $note mapeada a '${action.description}'");
  }

  void mapCcToAction(int cc, MappableAction action) {
    state = state.copyWith(ccMappings: {...state.ccMappings, cc: action});
     debugPrint("MIDI Mapping: CC $cc mapeado a '${action.description}'");
  }

  void resetToDefaults() {
    _loadDefaultMappings();
    saveMappings();
    debugPrint('MIDI Mappings reset to defaults.');
  }

  Future<String> get _localPath async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  Future<File> get _localFile async {
    final path = await _localPath;
    return File('$path/midi_mappings.json');
  }

  Future<void> saveMappings() async {
    try {
      final file = await _localFile;
      final jsonString = jsonEncode(state.toJson());
      await file.writeAsString(jsonString);
      debugPrint('MIDI Mappings saved to ${file.path}');
    } catch (e) {
      debugPrint('Failed to save MIDI mappings: $e');
    }
  }

  Future<void> loadMappings() async {
    try {
      final file = await _localFile;
      if (await file.exists()) {
        final jsonString = await file.readAsString();
        state = MidiMappingState.fromJson(jsonDecode(jsonString));
        debugPrint('MIDI Mappings loaded from ${file.path}');
      } else {
        _loadDefaultMappings();
      }
    } catch (e) {
      debugPrint('Failed to load MIDI mappings, loading defaults: $e');
      _loadDefaultMappings();
    }
  }
}

final midiMappingProvider = StateNotifierProvider<MidiMappingNotifier, MidiMappingState>((ref) => MidiMappingNotifier());

// --- Estado del Modo de Aprendizaje ---

final isMidiLearningProvider = StateProvider<bool>((ref) => false);

// Almacena el último evento MIDI recibido mientras se está en modo de aprendizaje.
final learningMidiEventProvider = StateProvider<({int id, bool isNote})?>((ref) => null);
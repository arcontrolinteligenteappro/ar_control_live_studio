import 'dart:async';
import 'package:ar_control_live_studio/core/audio_engine.dart';
import 'package:ar_control_live_studio/core/macro_engine.dart';
import 'package:ar_control_live_studio/core/midi_mapping_service.dart';
import 'package:ar_control_live_studio/core/switcher_engine.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_midi_command/flutter_midi_command.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Servicio para manejar la entrada MIDI y controlar la aplicación.
class MidiService {
  final Ref _ref;
  StreamSubscription<MidiPacket>? _midiSubscription;
  final MidiCommand _midiCommand = MidiCommand();
  MidiDevice? _connectedDevice;

  MidiService(this._ref) {
    _initialize();
  }

  void _initialize() {
    // Escanea dispositivos MIDI por cable y Bluetooth.
    _midiCommand.startScanningForBluetoothDevices();

    _ref.listen<MacroEngineState>(macroEngineProvider, (previous, next) {
      _handleMacroStateChange(previous, next);
    });

    _ref.listen<dynamic>(audioEngineProvider, (previous, next) {
      _handleAudioStateChange(previous, next);
    });

    _midiSubscription = _midiCommand.onMidiDataReceived?.listen((packet) {
      final isLearning = _ref.read(isMidiLearningProvider);
      final status = packet.data[0];

      // Nos interesan los mensajes de Control Change (CC).
      // El byte de estado para CC en el canal 1 es 0xB0 (176). 0xB0 a 0xBF para todos los canales.
      if (status >= 176 && status <= 191) {
        final controller = packet.data[1]; // Número del controlador (ej. 7 para volumen)
        final value = packet.data[2];      // Valor (0-127)
        if (isLearning) {
          _ref.read(learningMidiEventProvider.notifier).state = (id: controller, isNote: false);
        } else {
          _handleControlChange(controller, value);
        }
      }
      // Y los mensajes de Note On.
      else if (status >= 144 && status <= 159) {
        final note = packet.data[1];
        final velocity = packet.data[2];
        if (velocity > 0) { // Solo actuar al presionar la nota
          if (isLearning) {
            _ref.read(learningMidiEventProvider.notifier).state = (id: note, isNote: true);
          } else {
            _handleNoteOn(note);
          }
        }
      }
    });

    // Se conecta automáticamente al primer dispositivo MIDI que encuentre.
    // En una app de producción, se mostraría una lista para que el usuario elija.
    _midiCommand.devices.then((devices) {
      if (devices != null && devices.isNotEmpty) {
        debugPrint("Dispositivos MIDI encontrados: ${devices.map((d) => d.name).join(', ')}");
        _connectedDevice = devices.first;
        _midiCommand.connectToDevice(_connectedDevice!);
        debugPrint("Servicio MIDI: Conectado a ${_connectedDevice!.name}");
      } else {
        debugPrint("Servicio MIDI: No se encontraron dispositivos MIDI.");
      }
    });
  }

  void _handleControlChange(int controller, int value) {
    final mappings = _ref.read(midiMappingProvider).ccMappings;
    final action = mappings[controller];

    if (action is VolumeAction) {
      // El mapeo por defecto usa placeholders. Los resolvemos aquí.
      if (action.id.startsWith('source_at_index_')) {
        final index = int.tryParse(action.id.split('_').last) ?? -1;
        final sources = _ref.read(switcherEngineProvider).sources.keys.toList();
        if (index != -1 && index < sources.length) {
          final sourceId = sources[index];
          final normalizedVolume = value / 127.0;
          _ref.read(audioEngineProvider.notifier).setVolume(sourceId, normalizedVolume);
        }
      } else {
        // Mapeo directo a un sourceId
        final sourceId = action.id;
        final normalizedVolume = value / 127.0; // Normaliza el valor de 0-127 a 0.0-1.0
        _ref.read(audioEngineProvider.notifier).setVolume(sourceId, normalizedVolume);
      }
    }
  }

  void _handleNoteOn(int note) {
    final mappings = _ref.read(midiMappingProvider).noteMappings;
    final action = mappings[note];

    if (action is MacroTriggerAction) {
      _ref.read(macroEngineProvider.notifier).executeMacro(action.id);
    }
  }

  void _handleMacroStateChange(MacroEngineState? previous, MacroEngineState next) {
    final mappings = _ref.read(midiMappingProvider).noteMappings;

    // Macro finalizada
    if (previous?.runningMacroName != null && next.runningMacroName == null) {
      final finishedMacroName = previous!.runningMacroName!;
      mappings.forEach((note, action) {
        if (action is MacroTriggerAction && action.id == finishedMacroName) {
          _sendNoteOff(note);
        }
      });
    }

    // Macro iniciada
    if (previous?.runningMacroName == null && next.runningMacroName != null) {
      final startedMacroName = next.runningMacroName!;
      mappings.forEach((note, action) {
        if (action is MacroTriggerAction && action.id == startedMacroName) {
          _sendNoteOn(note, 127); // Velocidad máxima para encender el LED
        }
      });
    }
  }

  void _handleAudioStateChange(dynamic previous, dynamic next) {
    if (_connectedDevice == null) return;

    final mappings = _ref.read(midiMappingProvider).ccMappings;
    if (mappings.isEmpty) return;

    // Compara los volúmenes nuevos con los anteriores para encontrar cambios.
    next.volumes.forEach((sourceId, newVolume) {
      final oldVolume = previous?.volumes[sourceId] ?? -1.0; // -1 para forzar la actualización la primera vez.

      // Solo envía el mensaje si el cambio es significativo.
      if ((newVolume - oldVolume).abs() > 0.001) {
        // Busca el CC mapeado a esta acción de volumen.
        mappings.forEach((cc, action) {
          if (action is VolumeAction) {
            String resolvedSourceId = action.id;
            if (action.id.startsWith('source_at_index_')) {
              final index = int.tryParse(action.id.split('_').last) ?? -1;
              final sources = _ref.read(switcherEngineProvider).sources.keys.toList();
              if (index != -1 && index < sources.length) resolvedSourceId = sources[index];
            }

            if (resolvedSourceId == sourceId) {
              _sendControlChange(cc, (newVolume * 127).round());
            }
          }
        });
      }
    });
  }

  void _sendNoteOn(int note, int velocity) {
    _midiCommand.sendData(Uint8List.fromList([0x90, note, velocity]));
  }

  void _sendNoteOff(int note) {
    _midiCommand.sendData(Uint8List.fromList([0x80, note, 0]));
  }

  void _sendControlChange(int controller, int value) {
    _midiCommand.sendData(Uint8List.fromList([0xB0, controller, value]));
  }

  void dispose() {
    _midiSubscription?.cancel();
    if (_connectedDevice != null) {
      _midiCommand.disconnectDevice(_connectedDevice!);
    }
  }
}

/// Provider para la instancia global del MidiService.
final midiServiceProvider = Provider<MidiService>((ref) {
  final service = MidiService(ref);
  ref.onDispose(() => service.dispose());
  return service;
});
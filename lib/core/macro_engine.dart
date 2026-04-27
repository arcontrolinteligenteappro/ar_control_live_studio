import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:ar_control_live_studio/core/switcher_engine.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

enum MacroActionType { selectForPreview, executeCut, executeAuto, wait }

@immutable
class MacroAction {
  final MacroActionType type;
  final String? sourceId; // For selectForPreview
  final Duration? duration; // For wait and executeAuto

  const MacroAction({required this.type, this.sourceId, this.duration});

  Map<String, dynamic> toJson() => {
        'type': type.name,
        'sourceId': sourceId,
        'durationMs': duration?.inMilliseconds,
      };

  factory MacroAction.fromJson(Map<String, dynamic> json) {
    return MacroAction(
      type: MacroActionType.values.byName(json['type']),
      sourceId: json['sourceId'],
      duration: json['durationMs'] != null
          ? Duration(milliseconds: json['durationMs'])
          : null,
    );
  }
}

@immutable
class Macro {
  final String name;
  final List<MacroAction> actions;

  const Macro({required this.name, required this.actions});

  Map<String, dynamic> toJson() => {
        'name': name,
        'actions': actions.map((a) => a.toJson()).toList(),
      };

  factory Macro.fromJson(Map<String, dynamic> json) {
    return Macro(
      name: json['name'],
      actions: (json['actions'] as List).map((a) => MacroAction.fromJson(a)).toList(),
    );
  }
}

@immutable
class MacroEngineState {
  final List<Macro> macros;
  final String? runningMacroName;
  final double executionProgress;
  final String? currentActionDescription;

  const MacroEngineState({
    this.macros = const [],
    this.runningMacroName,
    this.executionProgress = 0.0,
    this.currentActionDescription,
  });

  MacroEngineState copyWith({
    List<Macro>? macros,
    String? runningMacroName,
    bool clearRunningMacro = false,
    double? executionProgress,
    String? currentActionDescription,
    bool clearAction = false,
  }) {
    return MacroEngineState(
      macros: macros ?? this.macros,
      runningMacroName: clearRunningMacro ? null : runningMacroName ?? this.runningMacroName,
      executionProgress: clearAction ? 0.0 : executionProgress ?? this.executionProgress,
      currentActionDescription: clearAction ? null : currentActionDescription ?? this.currentActionDescription,
    );
  }

  Map<String, dynamic> toJson() => {
        'macros': macros.map((m) => m.toJson()).toList(),
      };

  factory MacroEngineState.fromJson(Map<String, dynamic> json) {
    return MacroEngineState(
      macros: (json['macros'] as List).map((m) => Macro.fromJson(m)).toList(),
    );
  }
}

class MacroEngine extends StateNotifier<MacroEngineState> {
  // FIX: Cambiado de WidgetRef a Ref. Un StateNotifier no debe usar WidgetRef.
  final Ref _ref;

  MacroEngine(this._ref) : super(const MacroEngineState()) {
    loadMacros();
  }

  void _loadDefaultMacros() {
    final defaultMacros = [
      const Macro(name: 'CAM 1 -> CAM 2 (CUT)', actions: [
        MacroAction(type: MacroActionType.selectForPreview, sourceId: 'cam1'),
        MacroAction(type: MacroActionType.wait, duration: Duration(milliseconds: 200)),
        MacroAction(type: MacroActionType.executeCut),
        MacroAction(type: MacroActionType.wait, duration: Duration(seconds: 2)),
        MacroAction(type: MacroActionType.selectForPreview, sourceId: 'cam2'),
        MacroAction(type: MacroActionType.wait, duration: Duration(milliseconds: 200)),
        MacroAction(type: MacroActionType.executeCut),
      ]),
    ];
    state = state.copyWith(macros: defaultMacros);
  }

  Future<void> _executePausableAction(Duration duration, String description) async {
    state = state.copyWith(currentActionDescription: description, executionProgress: 0.0);
    if (duration.inMilliseconds <= 0) {
      state = state.copyWith(executionProgress: 1.0);
      return;
    }

    final steps = 50;
    final stepDuration = Duration(milliseconds: duration.inMilliseconds ~/ steps);

    for (int i = 1; i <= steps; i++) {
      await Future.delayed(stepDuration);
      if (state.runningMacroName == null) break; // Macro was cancelled
      state = state.copyWith(executionProgress: i / steps);
    }
  }

  Future<void> executeMacro(String macroName) async {
    if (state.runningMacroName != null) return;

    final macro = state.macros.firstWhere((m) => m.name == macroName);
    final switcher = _ref.read(switcherEngineProvider.notifier);

    state = state.copyWith(runningMacroName: macroName, clearAction: true);

    for (final action in macro.actions) {
      if (state.runningMacroName == null) break; // Check for cancellation

      switch (action.type) {
        case MacroActionType.selectForPreview:
          state = state.copyWith(currentActionDescription: 'PVW: ${action.sourceId!}', executionProgress: 0.0);
          switcher.selectForPreview(action.sourceId!);
          state = state.copyWith(executionProgress: 1.0);
          break;
        case MacroActionType.executeCut:
          state = state.copyWith(currentActionDescription: 'CUT', executionProgress: 0.0);
          switcher.executeCut();
          state = state.copyWith(executionProgress: 1.0);
          break;
        case MacroActionType.executeAuto:
          final duration = action.duration ?? const Duration(seconds: 1);
          state = state.copyWith(currentActionDescription: 'AUTO: ${duration.inMilliseconds}ms');
          await switcher.executeAuto(duration, onProgress: (progress) {
            if (state.runningMacroName != null) {
              state = state.copyWith(executionProgress: progress);
            }
          });
          break;
        case MacroActionType.wait:
          await _executePausableAction(action.duration!, 'WAIT: ${action.duration!.inMilliseconds}ms');
          break;
      }
    }
    state = state.copyWith(clearRunningMacro: true, clearAction: true);
  }

  void cancelMacro() {
    state = state.copyWith(clearRunningMacro: true, clearAction: true);
  }

  void addMacro(Macro newMacro) {
    state = state.copyWith(macros: [...state.macros, newMacro]);
    saveMacros();
  }

  void updateMacro(String originalName, Macro updatedMacro) {
    final newMacros = state.macros.map((m) => m.name == originalName ? updatedMacro : m).toList();
    state = state.copyWith(macros: newMacros);
    saveMacros();
  }

  void deleteMacro(String macroName) {
    final newMacros = state.macros.where((m) => m.name != macroName).toList();
    state = state.copyWith(macros: newMacros);
    saveMacros();
  }

  void reorderMacro(int oldIndex, int newIndex) {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final macros = List<Macro>.from(state.macros);
    final item = macros.removeAt(oldIndex);
    macros.insert(newIndex, item);
    state = state.copyWith(macros: macros);
    saveMacros();
  }

  Future<String> get _localPath async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  Future<File> get _localFile async {
    final path = await _localPath;
    return File('$path/macros.json');
  }

  Future<void> saveMacros() async {
    try {
      final file = await _localFile;
      final jsonString = jsonEncode(state.toJson());
      await file.writeAsString(jsonString);
      debugPrint('Macros saved to ${file.path}'); // FIX: Cambiado a debugPrint
    } catch (e) {
      debugPrint('Failed to save macros: $e'); // FIX: Cambiado a debugPrint
    }
  }

  Future<void> loadMacros() async {
    try {
      final file = await _localFile;
      if (await file.exists()) {
        final jsonString = await file.readAsString();
        state = MacroEngineState.fromJson(jsonDecode(jsonString));
        debugPrint('Macros loaded from ${file.path}'); // FIX: Cambiado a debugPrint
      } else {
        _loadDefaultMacros();
      }
    } catch (e) {
      debugPrint('Failed to load macros, loading defaults: $e'); // FIX: Cambiado a debugPrint
      _loadDefaultMacros();
    }
  }
}

final macroEngineProvider = StateNotifierProvider<MacroEngine, MacroEngineState>((ref) {
  return MacroEngine(ref);
});
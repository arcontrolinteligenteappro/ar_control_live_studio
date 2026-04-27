import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

@immutable
class AppSessionState {
  final String? operationMode;
  final String? module;
  final String? transmissionType;
  final String? visualMode;

  const AppSessionState({this.operationMode, this.module, this.transmissionType, this.visualMode});

  AppSessionState copyWith({String? operationMode, String? module, String? transmissionType, String? visualMode}) {
    return AppSessionState(
      operationMode: operationMode ?? this.operationMode,
      module: module ?? this.module,
      transmissionType: transmissionType ?? this.transmissionType,
      visualMode: visualMode ?? this.visualMode,
    );
  }
}

class AppSessionNotifier extends StateNotifier<AppSessionState> {
  AppSessionNotifier() : super(const AppSessionState());

  void setOperationMode(String? mode) {
    state = state.copyWith(operationMode: mode);
  }

  void setModule(String module) {
    state = state.copyWith(module: module);
  }

  void setTransmissionType(String type) {
    state = state.copyWith(transmissionType: type);
  }

  void setVisualMode(String mode) {
    state = state.copyWith(visualMode: mode);
  }
}

final appSessionProvider = StateNotifierProvider<AppSessionNotifier, AppSessionState>((ref) {
  return AppSessionNotifier();
});
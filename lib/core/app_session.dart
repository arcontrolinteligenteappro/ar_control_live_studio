import 'package:flutter_riverpod/flutter_riverpod.dart';

class AppSession {
  final String shareType;
  final String lensType;
  final String? operationMode;
  final String connectionMode;

  AppSession({
    this.shareType = 'screen', 
    this.lensType = 'wide', 
    this.operationMode,
    this.connectionMode = 'local',
  });
}

class AppSessionNotifier extends StateNotifier<AppSession> {
  AppSessionNotifier() : super(AppSession());

  void setShareType(String type) {
    state = AppSession(shareType: type, lensType: state.lensType, operationMode: state.operationMode, connectionMode: state.connectionMode);
  }

  void setLensType(String type) {
    state = AppSession(shareType: state.shareType, lensType: type, operationMode: state.operationMode, connectionMode: state.connectionMode);
  }

  void setOperationMode(String mode) {
    state = AppSession(shareType: state.shareType, lensType: state.lensType, operationMode: mode, connectionMode: state.connectionMode);
  }

  void setConnectionMode(String mode) {
    state = AppSession(shareType: state.shareType, lensType: state.lensType, operationMode: state.operationMode, connectionMode: mode);
  }
}

// Provider global para que los botones interactúen
final appSessionProvider = StateNotifierProvider<AppSessionNotifier, AppSession>((ref) {
  return AppSessionNotifier();
});
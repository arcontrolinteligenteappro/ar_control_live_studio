import 'package:ar_control_live_studio/core/hal.dart';
import 'package:ar_control_live_studio/core/native_audio_plugin.dart';
import 'package:ar_control_live_studio/core/native_texture_plugin.dart';
import 'package:ar_control_live_studio/core/replay_bindings.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';

// This file is used to generate mocks for our tests.
// After modifying this file, run `flutter pub run build_runner build`
@GenerateMocks([
  NativeAudioPlugin,
  NativeTexturePlugin,
  ReplayBindings,
  VideoSourceHAL,
])
void main() {}

void setupMockAudioChannel() {
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
    const MethodChannel('ar_control_live_studio/audio'),
    (MethodCall methodCall) async {
      // Simply return success for all calls
      return null;
    },
  );
}

void setupMockTextureChannel() {
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
    const MethodChannel('ar_control_live_studio/texture'),
    (MethodCall methodCall) async {
      if (methodCall.method == 'createTexture') {
        return 1; // Return a mock texture ID
      }
      return null;
    },
  );
}
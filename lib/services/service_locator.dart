import 'package:ar_control_live_studio/modules/audio_module.dart';
import 'package:ar_control_live_studio/modules/cloud_sync_module.dart';
import 'package:ar_control_live_studio/modules/drone_engine.dart';
import 'package:ar_control_live_studio/modules/hardware_engine.dart';
import 'package:ar_control_live_studio/modules/log_engine.dart';
import 'package:ar_control_live_studio/modules/ndi_stream_engine.dart';
import 'package:ar_control_live_studio/modules/overlay_module.dart';
import 'package:ar_control_live_studio/modules/stream_module.dart';
import 'package:ar_control_live_studio/modules/video_module.dart';

class ServiceLocator {
  static late final AudioEngine audioEngine;
  static late final DroneEngine droneEngine;
  static late final HardwareEngine hardwareEngine;
  static late final NDIStreamEngine ndiStreamEngine;
  static late final OverlayEngine overlayEngine;
  static late final LogEngine logEngine;
  static late final StreamEngine streamEngine;
  static late final VideoEngine videoEngine;
  static late final CloudSyncEngine cloudSyncEngine;

  static void setup() {
    audioEngine = AudioEngine();
    droneEngine = DroneEngine();
    hardwareEngine = HardwareEngine();
    ndiStreamEngine = NDIStreamEngine();
    overlayEngine = OverlayEngine();
    logEngine = LogEngine();
    streamEngine = StreamEngine();
    videoEngine = VideoEngine();
    cloudSyncEngine = CloudSyncEngine();
  }
}

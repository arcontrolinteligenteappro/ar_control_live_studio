import 'package:flutter/material.dart';
import 'package:ar_control_live_studio/ui/boot_sequence_view.dart';
import 'package:ar_control_live_studio/ui/main_selector_view.dart';
import 'package:ar_control_live_studio/ui/engine/engine_studio_view.dart';
import 'package:ar_control_live_studio/ui/camera/camera_client_view.dart';
import 'package:ar_control_live_studio/ui/player/player_view.dart';
import 'package:ar_control_live_studio/ui/remote/remote_control_view.dart';
import 'package:ar_control_live_studio/ui/placeholder_view.dart';

class RouteGenerator {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case '/':
        return MaterialPageRoute(builder: (_) => const BootSequenceView());
      case '/main':
        return MaterialPageRoute(builder: (_) => const MainSelectorView());
      case '/engine':
        return MaterialPageRoute(builder: (_) => const EngineStudioView());
      case '/camera':
        return MaterialPageRoute(builder: (_) => const CameraClientView());
      case '/player':
        return MaterialPageRoute(builder: (_) => const PlayerView());
      case '/remote':
        return MaterialPageRoute(builder: (_) => const RemoteControlView());
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            backgroundColor: Colors.black,
            body: Center(
              child: Text('Ruta no encontrada: ${settings.name}', style: const TextStyle(color: Colors.white)),
            ),
          ),
        );
    }
  }
}

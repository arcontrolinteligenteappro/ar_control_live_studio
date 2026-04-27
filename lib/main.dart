import 'package:ar_control_live_studio/ui/pro_mode_view.dart'; // Corregido
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

Future<void> main() async {
  // Asegura que Flutter esté inicializado.
  WidgetsFlutterBinding.ensureInitialized();
  
  final container = ProviderContainer();

  // Solicita permisos de cámara.
  await Permission.camera.request();

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        title: 'AR Control Live Studio',
        theme: ThemeData.dark(),
        home: const ProModeView(cameras: []),
      ),
    ),
  );
}
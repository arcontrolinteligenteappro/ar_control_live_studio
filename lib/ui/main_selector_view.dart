import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ar_control_live_studio/providers/app_session.dart';

class MainSelectorView extends ConsumerWidget {
  const MainSelectorView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final buttonWidth = width > 500 ? 380.0 : width * 0.85;
            return Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Selecciona el módulo', style: TextStyle(color: Colors.cyanAccent, fontSize: width > 500 ? 28 : 22, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 24),
                    _moduleButton(context, ref, 'ENGINE', '/engine', width: buttonWidth),
                    _moduleButton(context, ref, 'CAMERA', '/camera', width: buttonWidth),
                    _moduleButton(context, ref, 'PLAYER', '/player', width: buttonWidth),
                    _moduleButton(context, ref, 'REMOTE', '/remote', width: buttonWidth),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _moduleButton(BuildContext context, WidgetRef ref, String module, String route, {required double width}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: SizedBox(
        width: width,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            side: const BorderSide(color: Colors.cyanAccent),
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
          ),
          onPressed: () {
            ref.read(appSessionProvider.notifier).setModule(module);
            Navigator.pushNamed(context, route);
          },
          child: Text(module, style: const TextStyle(color: Colors.cyanAccent, fontSize: 18)),
        ),
      ),
    );
  }
}

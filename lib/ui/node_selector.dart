import 'package:flutter/material.dart';
import 'layout.dart';
import 'dashboard.dart';

/// NodeSelector: Selector de nodos al iniciar.
/// Pregunta qué módulo trabajar: ENGINE, CAMERA, REMOTE, PLAYER.
class NodeSelector extends StatefulWidget {
  const NodeSelector({super.key});

  @override
  _NodeSelectorState createState() => _NodeSelectorState();
}

class _NodeSelectorState extends State<NodeSelector> {
  String? _selectedNode;

  @override
  Widget build(BuildContext context) {
    return ARLayout(
      mode: 'Single',
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                '¿Qué módulo quieres trabajar?',
                style: TextStyle(color: Colors.cyanAccent, fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 40),
              ...['ENGINE', 'CAMERA', 'REMOTE', 'PLAYER'].map((node) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _selectedNode == node ? Colors.purpleAccent : Colors.grey,
                    padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 20),
                  ),
                  onPressed: () {
                    setState(() => _selectedNode = node);
                    Future.delayed(const Duration(seconds: 1), () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => Dashboard(selectedNode: node)),
                      );
                    });
                  },
                  child: Text(node, style: const TextStyle(color: Colors.white, fontSize: 18)),
                ),
              )),
            ],
          ),
        ),
      ),
    );
  }
}
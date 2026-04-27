import 'package:flutter/material.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class ReplayEngineWidget extends StatefulWidget {
  const ReplayEngineWidget({super.key});
  @override
  State<ReplayEngineWidget> createState() => _ReplayEngineWidgetState();
}

class _ReplayEngineWidgetState extends State<ReplayEngineWidget> {
  List<File> _recordings = [];
  bool _isLoading = true;

  @override
  void initState() { 
    super.initState(); 
    _loadRecordings(); 
  }

  Future<void> _loadRecordings() async {
    setState(() => _isLoading = true);
    try {
      final directory = await getApplicationDocumentsDirectory();
      final List<FileSystemEntity> files = directory.listSync();
      if (mounted) { 
        setState(() { 
          _recordings = files.whereType<File>().where((f) => f.path.endsWith('.mp4')).toList(); 
          _isLoading = false; 
        }); 
      }
    } catch (e) { 
      if (mounted) setState(() => _isLoading = false); 
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('REPLAY ENGINE', style: TextStyle(fontFamily: 'Courier New', fontSize: 16)), 
        backgroundColor: const Color(0xFF0A0A0A), 
        actions: [
          IconButton(icon: const Icon(Icons.refresh, color: Colors.cyanAccent), onPressed: _loadRecordings)
        ]
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: Colors.cyanAccent)) 
        : _recordings.isEmpty 
          ? const Center(child: Text("NO HAY GRABACIONES DETECTADAS", style: TextStyle(color: Colors.white24, fontFamily: 'Courier New'))) 
          : ListView.builder(
              itemCount: _recordings.length, 
              itemBuilder: (context, index) { 
                final file = _recordings[index]; 
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 8), 
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.cyanAccent.withOpacity(0.3)), 
                    color: const Color(0xFF0D0D0D)
                  ), 
                  child: ListTile(
                    leading: const Icon(Icons.play_circle_fill, color: Colors.cyanAccent, size: 40), 
                    title: Text(file.path.split('/').last, style: const TextStyle(color: Colors.white, fontSize: 12, fontFamily: 'Courier New')), 
                    subtitle: const Text("FORMATO: MP4", style: TextStyle(color: Colors.white38, fontSize: 10)), 
                    onTap: () { 
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Reproductor de video no enlazado en este mockup')));
                    }
                  )
                ); 
              }
            ),
    );
  }
}
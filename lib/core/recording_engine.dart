import 'dart:async';
import 'dart:isolate';
import 'dart:io';
import 'package:flutter/foundation.dart';

/// RecordingEngine: Motor de grabación independiente.
/// Gestiona grabación a disco con encoders propios.
/// Nunca comparte encoders con Streaming Engine.
class RecordingEngine {
  static final RecordingEngine _instance = RecordingEngine._internal();

  factory RecordingEngine() => _instance;

  RecordingEngine._internal();

  Isolate? _recordIsolate;
  ReceivePort? _receivePort;
  SendPort? _sendPort;

  bool _isRecording = false;
  // ignore: unused_field
  String _outputPath = '';

  /// Inicia el motor de grabación.
  Future<void> initialize() async {
    _receivePort = ReceivePort();
    _recordIsolate = await Isolate.spawn(_recordingIsolateFunction, _receivePort!.sendPort);
    
    _receivePort!.listen((message) {
      // Capturamos el SendPort del Isolate para poder comunicarnos con él
      if (message is SendPort) {
        _sendPort = message;
      } else {
        _handleIsolateMessage(message);
      }
    });
  }

  /// Función del Isolate de grabación.
  static void _recordingIsolateFunction(SendPort sendPort) {
    ReceivePort isolateReceive = ReceivePort();
    // Enviamos nuestro puerto de recepción al hilo principal
    sendPort.send(isolateReceive.sendPort);

    isolateReceive.listen((message) {
      // Lógica de grabación: procesar frames, escribir a archivo
      if (message is Map && message['type'] == 'START_RECORD') {
        // String path = message['path'];
        // Iniciar grabación a path
        sendPort.send('RECORD_STARTED');
      } else if (message == 'STOP_RECORD') {
        // Detener y guardar
        sendPort.send('RECORD_STOPPED');
      } else if (message is Map && message['type'] == 'FRAME') {
        // Grabar frame
      }
    });
  }

  /// Maneja mensajes del Isolate.
  void _handleIsolateMessage(dynamic message) {
    if (message == 'RECORD_STARTED') {
      _isRecording = true;
      debugPrint('Recording started');
    } else if (message == 'RECORD_STOPPED') {
      _isRecording = false;
      debugPrint('Recording stopped');
    }
  }

  /// Inicia grabación.
  void startRecording(String path) {
    _outputPath = path;
    _sendPort?.send({'type': 'START_RECORD', 'path': path});
  }

  /// Detiene grabación.
  void stopRecording() {
    _sendPort?.send('STOP_RECORD');
  }

  /// Envía frame al Isolate para grabación.
  void sendFrame(dynamic frame) {
    if (_isRecording) {
      _sendPort?.send({'type': 'FRAME', 'data': frame});
    }
  }

  /// Estado de grabación.
  bool get isRecording => _isRecording;

  /// Libera recursos.
  void dispose() {
    _recordIsolate?.kill();
    _receivePort?.close();
  }
}
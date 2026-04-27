import 'dart:async';
import 'dart:isolate';
import 'package:flutter/foundation.dart';

/// StreamingEngine: Motor de streaming independiente.
/// Gestiona transmisión en vivo via RTMP/WebRTC/etc.
/// Nunca comparte encoders con Recording Engine.
class StreamingEngine {
  static final StreamingEngine _instance = StreamingEngine._internal();

  factory StreamingEngine() => _instance;

  StreamingEngine._internal();

  Isolate? _streamIsolate;
  ReceivePort? _receivePort;
  SendPort? _sendPort;

  bool _isStreaming = false;
  // ignore: unused_field
  String _streamUrl = '';
  // ignore: unused_field
  String _streamKey = '';

  /// Inicia el motor de streaming.
  Future<void> initialize() async {
    _receivePort = ReceivePort();
    _streamIsolate = await Isolate.spawn(_streamingIsolateFunction, _receivePort!.sendPort);
    
    _receivePort!.listen((message) {
      // Capturamos el SendPort del Isolate para poder mandarle los frames y comandos
      if (message is SendPort) {
        _sendPort = message;
      } else {
        _handleIsolateMessage(message);
      }
    });
  }

  /// Función del Isolate de streaming.
  static void _streamingIsolateFunction(SendPort sendPort) {
    ReceivePort isolateReceive = ReceivePort();
    // Enviamos nuestro puerto de recepción al hilo principal
    sendPort.send(isolateReceive.sendPort);

    isolateReceive.listen((message) {
      // Lógica de streaming: procesar frames, enviar a servidor
      if (message == 'START_STREAM') {
        // Iniciar transmisión
        sendPort.send('STREAM_STARTED');
      } else if (message == 'STOP_STREAM') {
        // Detener
        sendPort.send('STREAM_STOPPED');
      }
      // Procesar frames entrantes, etc.
    });
  }

  /// Maneja mensajes del Isolate.
  void _handleIsolateMessage(dynamic message) {
    if (message == 'STREAM_STARTED') {
      _isStreaming = true;
      debugPrint('Streaming started');
    } else if (message == 'STREAM_STOPPED') {
      _isStreaming = false;
      debugPrint('Streaming stopped');
    }
  }

  /// Inicia streaming.
  void startStream(String url, String key) {
    _streamUrl = url;
    _streamKey = key;
    _sendPort?.send('START_STREAM');
  }

  /// Detiene streaming.
  void stopStream() {
    _sendPort?.send('STOP_STREAM');
  }

  /// Envía frame al Isolate para streaming.
  void sendFrame(dynamic frame) {
    if (_isStreaming) {
      _sendPort?.send({'type': 'FRAME', 'data': frame});
    }
  }

  /// Estado del streaming.
  bool get isStreaming => _isStreaming;

  /// Libera recursos.
  void dispose() {
    _streamIsolate?.kill();
    _receivePort?.close();
  }
}
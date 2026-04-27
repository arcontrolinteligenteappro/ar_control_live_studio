import 'package:flutter/services.dart';

class PlatformService {
  static const MethodChannel _channel =
      MethodChannel('com.arcontrol.inteligente.studio/hardware');

  static Future<Map<String, dynamic>> Function()? getPTZStatusHandler;
  static Future<void> Function(String, dynamic)? sendPTZCommandHandler;
  static Future<bool> Function()? pingHandler;
  static Future<Map<String, dynamic>> Function(String, int)? connectPTZHandler;
  static Future<void> Function()? disconnectPTZHandler;

  static Future<Map<String, dynamic>> getPTZStatus() async {
    if (getPTZStatusHandler != null) {
      return await getPTZStatusHandler!();
    }

    final result =
        await _channel.invokeMethod<Map<dynamic, dynamic>>('getPTZStatus');
    return result?.map((key, value) => MapEntry(key.toString(), value)) ?? {};
  }

  static Future<void> sendPTZCommand(String command, dynamic value, {String? address, int? port}) async {
    if (sendPTZCommandHandler != null) {
      await sendPTZCommandHandler!(command, value);
      return;
    }

    await _channel.invokeMethod('sendPTZCommand', {
      'command': command,
      'value': value,
      'address': address,
      'port': port,
    });
  }

  static Future<Map<String, dynamic>> connectPTZ(String address, int port) async {
    if (connectPTZHandler != null) {
      return await connectPTZHandler!(address, port);
    }

    final result = await _channel.invokeMethod<Map<dynamic, dynamic>>('connectPTZ', {
      'address': address,
      'port': port,
    });
    return result?.map((key, value) => MapEntry(key.toString(), value)) ?? {};
  }

  static Future<void> disconnectPTZ() async {
    if (disconnectPTZHandler != null) {
      await disconnectPTZHandler!();
      return;
    }

    await _channel.invokeMethod('disconnectPTZ');
  }

  static Future<bool> isPlatformAvailable() async {
    if (pingHandler != null) {
      return await pingHandler!();
    }

    try {
      await _channel.invokeMethod('ping');
      return true;
    } catch (_) {
      return false;
    }
  }
}

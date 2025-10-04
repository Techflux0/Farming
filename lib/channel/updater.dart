import 'package:flutter/services.dart';

class ApkInstaller {
  static const MethodChannel _channel = MethodChannel('app.installer');

  static Future<bool> installApk(String filePath) async {
    try {
      final bool result = await _channel.invokeMethod('installApk', {
        'path': filePath,
      });
      return result;
    } on PlatformException catch (e) {
      print("Failed to install APK: '${e.message}'");
      return false;
    }
  }
}

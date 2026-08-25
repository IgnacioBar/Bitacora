import 'package:flutter/services.dart';

class AndroidGalleryPicker {
  const AndroidGalleryPicker._();

  static const _channel = MethodChannel('pescatronik/gallery_picker');

  static Future<String?> pickImageFromMiuiGallery() async {
    final path = await _channel.invokeMethod<String>('pickMiuiImage');
    return path;
  }

  static Future<String?> pickImageFromAndroidSelector() async {
    final path = await _channel.invokeMethod<String>('pickAndroidImage');
    return path;
  }
}

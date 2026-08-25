import 'dart:io';

import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

class PhotoStorage {
  const PhotoStorage._();

  static Future<String> save(String temporaryPath, String captureId) async {
    final documents = await getApplicationDocumentsDirectory();
    final photoFolder = Directory(join(documents.path, 'capture_photos'));
    await photoFolder.create(recursive: true);
    final extension = extensionOf(temporaryPath);
    final destination = join(photoFolder.path, '$captureId$extension');
    if (temporaryPath == destination) return destination;
    await File(temporaryPath).copy(destination);
    return destination;
  }

  static Future<String> restoreBytes(
    List<int> bytes,
    String captureId,
    String extension,
  ) async {
    final documents = await getApplicationDocumentsDirectory();
    final photoFolder = Directory(join(documents.path, 'capture_photos'));
    await photoFolder.create(recursive: true);
    final safeExtension = extension.startsWith('.') ? extension : '.$extension';
    final destination = join(photoFolder.path, '$captureId$safeExtension');
    await File(destination).writeAsBytes(bytes, flush: true);
    return destination;
  }

  static String extensionOf(String path) {
    final value = extension(path);
    return value.isEmpty ? '.jpg' : value;
  }

  static Future<void> deleteIfExists(String? path) async {
    if (path == null) return;
    final photo = File(path);
    if (await photo.exists()) {
      await photo.delete();
    }
  }
}

import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../models/shared_capture_map.dart';

class SharedMapRepository {
  SharedMapRepository._();

  static final SharedMapRepository instance = SharedMapRepository._();

  Future<File> get _deviceIdFile async {
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/share_device_id.txt');
  }

  Future<File> get _file async {
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/shared_capture_maps.json');
  }

  Future<String> getLocalDeviceId() async {
    final file = await _deviceIdFile;
    if (await file.exists()) {
      final existing = (await file.readAsString()).trim();
      if (existing.isNotEmpty) return existing;
    }
    final id = DateTime.now().microsecondsSinceEpoch.toRadixString(36);
    await file.writeAsString(id);
    return id;
  }

  Future<List<SharedCaptureMap>> getAll() async {
    final file = await _file;
    if (!await file.exists()) return [];
    final decoded = jsonDecode(await file.readAsString());
    return (decoded as List<dynamic>)
        .whereType<Map<String, dynamic>>()
        .map(SharedCaptureMap.fromJson)
        .toList();
  }

  Future<void> save(SharedCaptureMap sharedMap) async {
    final maps = await getAll();
    maps.removeWhere((map) => map.id == sharedMap.id);
    maps.add(sharedMap);
    final file = await _file;
    await file.writeAsString(
      const JsonEncoder.withIndent('  ')
          .convert(maps.map((map) => map.toJson()).toList()),
    );
  }

  Future<void> deleteById(String id) async {
    final maps = await getAll();
    maps.removeWhere((map) => map.id == id);
    final file = await _file;
    await file.writeAsString(
      const JsonEncoder.withIndent('  ')
          .convert(maps.map((map) => map.toJson()).toList()),
    );
  }

  Future<void> deleteByOwnerName(String ownerName) async {
    final normalizedOwner = ownerName.trim().toLowerCase();
    final maps = await getAll();
    maps.removeWhere(
      (map) => map.ownerName.trim().toLowerCase() == normalizedOwner,
    );
    final file = await _file;
    await file.writeAsString(
      const JsonEncoder.withIndent('  ')
          .convert(maps.map((map) => map.toJson()).toList()),
    );
  }
}

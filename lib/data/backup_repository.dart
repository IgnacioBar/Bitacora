import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../models/fishing_catch.dart';
import 'catch_repository.dart';
import 'photo_storage.dart';

class BackupRepository {
  BackupRepository._();

  static final BackupRepository instance = BackupRepository._();

  Future<File> exportCaptures() async {
    final catches = await CatchRepository.instance.getAll();
    final folder = await _backupFolder();
    final timestamp = DateTime.now()
        .toIso8601String()
        .replaceAll(':', '-')
        .replaceAll('.', '-');
    final file = File('${folder.path}/bitacora-backup-$timestamp.json');
    final captures = <Map<String, Object?>>[];
    for (final entry in catches) {
      final data = entry.toMap();
      final photoPath = entry.photoPath;
      if (photoPath != null) {
        final photo = File(photoPath);
        if (await photo.exists()) {
          data['photo_backup'] = {
            'extension': PhotoStorage.extensionOf(photo.path),
            'base64': base64Encode(await photo.readAsBytes()),
          };
        }
      }
      captures.add(data);
    }
    final payload = {
      'app': 'Bitácora',
      'backup_version': 3,
      'exported_at': DateTime.now().toUtc().toIso8601String(),
      'captures_count': catches.length,
      'photos_included': captures
          .where((entry) => entry['photo_backup'] != null)
          .length,
      'captures': captures,
      'note': 'Esta copia guarda los datos y las fotos disponibles de las capturas.',
    };
    return file.writeAsString(
      const JsonEncoder.withIndent('  ').convert(payload),
      flush: true,
    );
  }

  Future<List<File>> listBackups() async {
    final folders = <Directory>[
      Directory('/storage/emulated/0/Download/Bitacora'),
      await _appBackupFolder(),
    ];
    final files = <File>[];
    for (final folder in folders) {
      if (!await folder.exists()) continue;
      await for (final entity in folder.list()) {
        if (entity is File &&
            entity.path.toLowerCase().endsWith('.json') &&
            (entity.path.toLowerCase().contains('bitacora-backup') ||
                entity.path.toLowerCase().contains('pescatronik-backup') ||
                entity.path.toLowerCase().contains('pescatronik-v3-backup'))) {
          files.add(entity);
        }
      }
    }
    files.sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));
    return files;
  }

  Future<BackupPreview> preview(File file) async {
    final payload = await _readPayload(file);
    final captures = payload['captures'] as List<dynamic>? ?? const [];
    final exportedAtText = payload['exported_at'] as String?;
    return BackupPreview(
      file: file,
      capturesCount: captures.length,
      photosCount: captures
          .whereType<Map>()
          .where((entry) => entry['photo_backup'] != null)
          .length,
      exportedAt: exportedAtText == null
          ? null
          : DateTime.tryParse(exportedAtText)?.toLocal(),
    );
  }

  Future<int> restore(File file) async {
    final payload = await _readPayload(file);
    final captures = payload['captures'] as List<dynamic>? ?? const [];
    final entries = <FishingCatch>[];
    for (final rawEntry in captures.whereType<Map>()) {
      final entryMap = Map<String, Object?>.from(rawEntry);
      final photoBackup = entryMap.remove('photo_backup');
      var entry = FishingCatch.fromMap(entryMap);
      if (photoBackup is Map) {
        final backup = Map<String, Object?>.from(photoBackup);
        final encoded = backup['base64'] as String?;
        if (encoded != null && encoded.isNotEmpty) {
          final extension = backup['extension'] as String? ?? '.jpg';
          final restoredPath = await PhotoStorage.restoreBytes(
            base64Decode(encoded),
            entry.id,
            extension,
          );
          entry = FishingCatch(
            id: entry.id,
            countryId: entry.countryId,
            waterTypeId: entry.waterTypeId,
            speciesId: entry.speciesId,
            caughtAt: entry.caughtAt,
            createdAt: entry.createdAt,
            photoPath: restoredPath,
            weightKg: entry.weightKg,
            lengthCm: entry.lengthCm,
            latitude: entry.latitude,
            longitude: entry.longitude,
            locationName: entry.locationName,
            baitOrLure: entry.baitOrLure,
            technique: entry.technique,
            notes: entry.notes,
          );
        }
      }
      entries.add(entry);
    }
    await CatchRepository.instance.replaceAll(entries);
    return entries.length;
  }

  Future<Map<String, dynamic>> _readPayload(File file) async {
    final decoded = jsonDecode(await file.readAsString());
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Archivo de copia no válido.');
    }
    return decoded;
  }

  Future<Directory> _backupFolder() async {
    final downloads = Directory('/storage/emulated/0/Download/Bitacora');
    try {
      await downloads.create(recursive: true);
      final probe = File('${downloads.path}/.bitacora-test');
      await probe.writeAsString('ok');
      await probe.delete();
      return downloads;
    } catch (_) {
      return _appBackupFolder();
    }
  }

  Future<Directory> _appBackupFolder() async {
    final external = await getExternalStorageDirectory();
    final base = external ?? await getApplicationDocumentsDirectory();
    final folder = Directory('${base.path}/backups');
    await folder.create(recursive: true);
    return folder;
  }
}

class BackupPreview {
  const BackupPreview({
    required this.file,
    required this.capturesCount,
    required this.photosCount,
    required this.exportedAt,
  });

  final File file;
  final int capturesCount;
  final int photosCount;
  final DateTime? exportedAt;
}

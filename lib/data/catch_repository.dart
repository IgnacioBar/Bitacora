import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../models/fishing_catch.dart';
import 'spain_database_schema.dart';

class CatchRepository {
  CatchRepository._();

  static final CatchRepository instance = CatchRepository._();
  Database? _database;
  Future<Database>? _openingDatabase;

  Future<void> warmUp() async {
    await _db;
  }

  Future<Database> get _db async {
    if (_database != null) return _database!;
    if (_openingDatabase != null) return _openingDatabase!;
    _openingDatabase = _open();
    _database = await _openingDatabase!;
    _openingDatabase = null;
    return _database!;
  }

  Future<Database> _open() async {
    final folder = await getDatabasesPath();
    return openDatabase(
      join(folder, 'pescatronik.db'),
      version: 3,
      onConfigure: (database) async {
        await database.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: (database, _) async {
        for (final statement in spainDatabaseSchema) {
          await database.execute(statement);
        }
      },
      onUpgrade: (database, _, _) async {
        for (final statement in spainDatabaseSchema.where(
          (statement) => statement.trimLeft().startsWith('CREATE INDEX'),
        )) {
          await database.execute(statement);
        }
      },
    );
  }

  Future<void> save(FishingCatch entry) async {
    final database = await _db;
    await database.insert(
      'catches',
      entry.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<FishingCatch>> getAll() async {
    final database = await _db;
    final rows = await database.query('catches', orderBy: 'caught_at DESC');
    return rows.map((row) => FishingCatch.fromMap(row)).toList();
  }

  Future<List<FishingCatch>> getAllWithLocation() async {
    final database = await _db;
    final rows = await database.query(
      'catches',
      where: 'latitude IS NOT NULL AND longitude IS NOT NULL',
      orderBy: 'caught_at DESC',
    );
    return rows.map((row) => FishingCatch.fromMap(row)).toList();
  }

  Future<int> deleteById(String id) async {
    final database = await _db;
    return database.delete('catches', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> replaceAll(List<FishingCatch> entries) async {
    final database = await _db;
    await database.transaction((transaction) async {
      await transaction.delete('catches');
      final batch = transaction.batch();
      for (final entry in entries) {
        batch.insert(
          'catches',
          entry.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      await batch.commit(noResult: true);
    });
  }
}

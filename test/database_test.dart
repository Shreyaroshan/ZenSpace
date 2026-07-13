import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:zenspace/database_helper.dart';

void main() {
  // Initialize FFI for local machine testing
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  group('DatabaseHelper CRUD Tests', () {
    late Database db;

    setUp(() async {
      // Create an in-memory database for each test
      db = await openDatabase(inMemoryDatabasePath, version: 9,
          onCreate: (db, version) async {
        await db.execute(
            'CREATE TABLE mood_entries (id INTEGER PRIMARY KEY AUTOINCREMENT, date TEXT UNIQUE, mood_score INTEGER NOT NULL, note TEXT, created_at TEXT)');
      });
    });

    tearDown(() async {
      await db.close();
    });

    test('Inserting and retrieving a mood log works', () async {
      final date = '2026-03-27';
      final score = 5;
      final note = 'Feeling great!';

      await db.insert('mood_entries', {
        'date': date,
        'mood_score': score,
        'note': note,
        'created_at': DateTime.now().toIso8601String(),
      });

      final result = await db.query('mood_entries', where: 'date = ?', whereArgs: [date]);
      
      expect(result.length, 1);
      expect(result.first['mood_score'], score);
      expect(result.first['note'], note);
    });

    test('Unique constraint replaces old entry on same day', () async {
      final date = '2026-03-27';
      
      await db.insert('mood_entries', {'date': date, 'mood_score': 3});
      // Try to insert again for same day
      await db.insert('mood_entries', {'date': date, 'mood_score': 5}, 
          conflictAlgorithm: ConflictAlgorithm.replace);

      final result = await db.query('mood_entries');
      expect(result.length, 1);
      expect(result.first['mood_score'], 5);
    });
  });
}

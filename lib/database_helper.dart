import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('zenspace.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 9,
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE mood_entries (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT UNIQUE,
        mood_score INTEGER NOT NULL,
        note TEXT,
        created_at TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE gratitude_entries (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT,
        gratitude_text TEXT NOT NULL,
        created_at TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE breathing_sessions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        technique_name TEXT,
        duration_seconds INTEGER,
        created_at TEXT
      )
    ''');
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 8) {
      try {
        await db.execute('ALTER TABLE mood_entries RENAME TO mood_entries_old');
        await db.execute('''
          CREATE TABLE mood_entries (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            date TEXT UNIQUE,
            mood_score INTEGER NOT NULL,
            note TEXT,
            created_at TEXT
          )
        ''');
        await db.execute('''
          INSERT INTO mood_entries (date, mood_score, note, created_at)
          SELECT date,
                 MAX(COALESCE(mood_score, mood_level, 3)),
                 MAX(note),
                 MAX(COALESCE(created_at, date))
          FROM mood_entries_old
          GROUP BY date
        ''');
        await db.execute('DROP TABLE mood_entries_old');
      } catch (e) {
        debugPrint('Migration error V8: $e');
      }
    }

    if (oldVersion < 9) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS breathing_sessions (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          technique_name TEXT,
          duration_seconds INTEGER,
          created_at TEXT
        )
      ''');
    }
  }

  // ── Mood Methods ─────────────────────────────────────────────────────────────

  Future<void> insertMood(String date, int moodScore, String? note) async {
    final db = await database;
    final cleanDate = date.length > 10 ? date.substring(0, 10) : date;
    await db.insert(
      'mood_entries',
      {
        'date': cleanDate,
        'mood_score': moodScore,
        'note': note,
        'created_at': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Deletes a mood entry by its ID.
  Future<void> deleteMood(int id) async {
    final db = await database;
    await db.delete('mood_entries', where: 'id = ?', whereArgs: [id]);
  }

  Future<Map<String, dynamic>?> getMoodForDate(String date) async {
    final db = await database;
    final cleanDate = date.length > 10 ? date.substring(0, 10) : date;
    final result = await db.query(
        'mood_entries', where: 'date = ?', whereArgs: [cleanDate]);
    return result.isNotEmpty ? result.first : null;
  }

  Future<List<Map<String, dynamic>>> getMoodsForRange(
      String startDate, String endDate) async {
    final db = await database;
    return db.query(
      'mood_entries',
      where: 'date >= ? AND date <= ?',
      whereArgs: [startDate, endDate],
      orderBy: 'date ASC',
    );
  }

  Future<int> getTotalMoodCount() async {
    final db = await database;
    final result =
    await db.rawQuery('SELECT COUNT(*) as count FROM mood_entries');
    return (result.first['count'] as int?) ?? 0;
  }

  Future<List<Map<String, dynamic>>> getRecentMoods(int days) async {
    final now = DateTime.now();
    final start = now.subtract(Duration(days: days - 1));
    return getMoodsForRange(
      start.toIso8601String().substring(0, 10),
      now.toIso8601String().substring(0, 10),
    );
  }

  Future<List<int>> getUniqueMoodScores() async {
    final db = await database;
    final result =
    await db.rawQuery('SELECT DISTINCT mood_score FROM mood_entries');
    return result.map((row) => row['mood_score'] as int).toList();
  }

  Future<List<Map<String, dynamic>>> getAllMoodEntries() async {
    final db = await database;
    return db.query('mood_entries');
  }

  // ── Gratitude Methods ─────────────────────────────────────────────────────────

  Future<void> insertGratitude(String date, String text) async {
    final db = await database;
    await db.insert('gratitude_entries', {
      'date': date,
      'gratitude_text': text,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  Future<List<Map<String, dynamic>>> getGratitudeEntries(
      {String? searchQuery}) async {
    final db = await database;
    if (searchQuery != null && searchQuery.isNotEmpty) {
      return db.query(
        'gratitude_entries',
        where: 'gratitude_text LIKE ?',
        whereArgs: ['%$searchQuery%'],
        orderBy: 'created_at DESC',
      );
    }
    return db.query('gratitude_entries', orderBy: 'created_at DESC');
  }

  Future<int> getGratitudeCount() async {
    final db = await database;
    final result = await db
        .rawQuery('SELECT COUNT(*) as count FROM gratitude_entries');
    return (result.first['count'] as int?) ?? 0;
  }

  /// Deletes a single gratitude entry by its primary key.
  Future<void> deleteGratitude(int id) async {
    final db = await database;
    await db.delete('gratitude_entries', where: 'id = ?', whereArgs: [id]);
  }

  // ── Breathing Methods ─────────────────────────────────────────────────────────

  Future<void> insertBreathingSession(
      String technique, int durationSeconds) async {
    final db = await database;
    await db.insert('breathing_sessions', {
      'technique_name': technique,
      'duration_seconds': durationSeconds,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  Future<int> getBreathingSessionCount() async {
    final db = await database;
    final result = await db
        .rawQuery('SELECT COUNT(*) as count FROM breathing_sessions');
    return (result.first['count'] as int?) ?? 0;
  }
}
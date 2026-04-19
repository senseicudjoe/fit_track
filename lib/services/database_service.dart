import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

// Local SQLite cache for step data.
// The pedometer fires every few seconds — writing every tick to Firestore
// would be expensive. Instead we buffer to SQLite and flush a daily summary
// to Firestore once per day (handled by StatsProvider).

class DatabaseService {
  DatabaseService._();
  static final instance = DatabaseService._();

  Database? _db;

  Future<Database> get database async {
    _db ??= await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'fittrack.db');

    return openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Step cache — one row per day per user
    await db.execute('''
      CREATE TABLE step_cache (
        id        INTEGER PRIMARY KEY AUTOINCREMENT,
        uid       TEXT NOT NULL,
        date      TEXT NOT NULL,
        steps     INTEGER NOT NULL DEFAULT 0,
        synced    INTEGER NOT NULL DEFAULT 0,
        UNIQUE(uid, date)
      )
    ''');

    // Workout drafts — unsaved workout form state (survives app kill)
    await db.execute('''
      CREATE TABLE workout_drafts (
        id            INTEGER PRIMARY KEY AUTOINCREMENT,
        uid           TEXT NOT NULL,
        type          TEXT NOT NULL,
        duration_min  INTEGER NOT NULL DEFAULT 0,
        calories      REAL NOT NULL DEFAULT 0,
        distance_km   REAL NOT NULL DEFAULT 0,
        sets          INTEGER,
        reps          INTEGER,
        notes         TEXT NOT NULL DEFAULT '',
        updated_at    TEXT NOT NULL
      )
    ''');
  }

  // ── Step cache ───────────────────────────────────────────────────────────────

  Future<void> upsertSteps(String uid, String date, int steps) async {
    final db = await database;
    await db.insert(
      'step_cache',
      {'uid': uid, 'date': date, 'steps': steps, 'synced': 0},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<int> getStepsForDate(String uid, String date) async {
    final db = await database;
    final rows = await db.query(
      'step_cache',
      columns: ['steps'],
      where: 'uid = ? AND date = ?',
      whereArgs: [uid, date],
    );
    return rows.isEmpty ? 0 : rows.first['steps'] as int;
  }

  Future<List<Map<String, dynamic>>> getUnsyncedSteps(String uid) async {
    final db = await database;
    return db.query(
      'step_cache',
      where: 'uid = ? AND synced = 0',
      whereArgs: [uid],
      orderBy: 'date ASC',
    );
  }

  Future<void> markSynced(String uid, String date) async {
    final db = await database;
    await db.update(
      'step_cache',
      {'synced': 1},
      where: 'uid = ? AND date = ?',
      whereArgs: [uid, date],
    );
  }

  // ── Workout drafts ───────────────────────────────────────────────────────────

  Future<void> saveDraft(Map<String, dynamic> draft) async {
    final db = await database;
    await db.delete('workout_drafts',
        where: 'uid = ?', whereArgs: [draft['uid']]);
    await db.insert('workout_drafts', draft);
  }

  Future<Map<String, dynamic>?> getDraft(String uid) async {
    final db = await database;
    final rows = await db.query(
      'workout_drafts',
      where: 'uid = ?',
      whereArgs: [uid],
      limit: 1,
    );
    return rows.isEmpty ? null : rows.first;
  }

  Future<void> clearDraft(String uid) async {
    final db = await database;
    await db.delete('workout_drafts',
        where: 'uid = ?', whereArgs: [uid]);
  }

  // ── Cleanup ──────────────────────────────────────────────────────────────────

  Future<void> close() async {
    final db = await database;
    await db.close();
    _db = null;
  }
}
import 'package:sqflite/sqflite.dart';

/// Local SQLite database. All user data lives here first (offline-first).
class AppDatabase {
  AppDatabase(this.db);

  final Database db;

  static const int schemaVersion = 1;

  static Future<AppDatabase> open(DatabaseFactory factory, String path) async {
    final db = await factory.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: schemaVersion,
        onConfigure: (db) async {
          await db.execute('PRAGMA foreign_keys = ON');
        },
        onCreate: _onCreate,
      ),
    );
    return AppDatabase(db);
  }

  static Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE habits (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        description TEXT NOT NULL DEFAULT '',
        icon_key TEXT NOT NULL DEFAULT 'flag',
        color INTEGER NOT NULL,
        duration_minutes INTEGER NOT NULL,
        weekdays INTEGER NOT NULL,
        reminder_minutes INTEGER,
        require_proof INTEGER NOT NULL DEFAULT 0,
        is_paused INTEGER NOT NULL DEFAULT 0,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        deleted_at INTEGER,
        dirty INTEGER NOT NULL DEFAULT 1
      )
    ''');
    await db.execute('''
      CREATE TABLE completions (
        id TEXT PRIMARY KEY,
        habit_id TEXT NOT NULL,
        date_key TEXT NOT NULL,
        completed_at INTEGER NOT NULL,
        duration_seconds INTEGER NOT NULL,
        xp INTEGER NOT NULL,
        session_id TEXT NOT NULL UNIQUE,
        proof_path TEXT,
        updated_at INTEGER NOT NULL,
        deleted_at INTEGER,
        dirty INTEGER NOT NULL DEFAULT 1,
        UNIQUE (habit_id, date_key)
      )
    ''');
    await db.execute('''
      CREATE TABLE timer_session (
        id INTEGER PRIMARY KEY CHECK (id = 1),
        session_id TEXT NOT NULL,
        habit_id TEXT NOT NULL,
        target_seconds INTEGER NOT NULL,
        accumulated_ms INTEGER NOT NULL,
        started_at_ms INTEGER,
        proof_path TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE meta (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');
  }

  Future<void> close() => db.close();
}

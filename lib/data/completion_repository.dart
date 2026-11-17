import 'package:sqflite/sqflite.dart';

import '../domain/completion.dart';

class CompletionRepository {
  CompletionRepository(this._db);

  final Database _db;

  Future<List<Completion>> all() async {
    final rows = await _db.query(
      'completions',
      where: 'deleted_at IS NULL',
      orderBy: 'completed_at DESC',
    );
    return rows.map(Completion.fromMap).toList();
  }

  Future<List<Completion>> forHabit(String habitId) async {
    final rows = await _db.query(
      'completions',
      where: 'habit_id = ? AND deleted_at IS NULL',
      whereArgs: [habitId],
      orderBy: 'completed_at DESC',
    );
    return rows.map(Completion.fromMap).toList();
  }

  /// Inserts the completion unless the habit is already done for that day or
  /// the session was already counted. Returns true only when a new row was
  /// written.
  Future<bool> insertIfNew(Completion c) {
    return _db.transaction((txn) async {
      final existing = await txn.query(
        'completions',
        columns: ['id'],
        where:
            'deleted_at IS NULL AND ((habit_id = ? AND date_key = ?) OR session_id = ?)',
        whereArgs: [c.habitId, c.dateKey, c.sessionId],
        limit: 1,
      );
      if (existing.isNotEmpty) return false;
      await txn.insert('completions', {
        ...c.toMap(),
        'deleted_at': null,
        'dirty': 1,
      });
      return true;
    });
  }
}

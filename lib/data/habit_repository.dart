import 'package:sqflite/sqflite.dart';

import '../domain/habit.dart';

class HabitRepository {
  HabitRepository(this._db);

  final Database _db;

  Future<List<Habit>> all() async {
    final rows = await _db.query(
      'habits',
      where: 'deleted_at IS NULL',
      orderBy: 'created_at ASC',
    );
    return rows.map(Habit.fromMap).toList();
  }

  Future<Habit?> byId(String id) async {
    final rows = await _db.query(
      'habits',
      where: 'id = ? AND deleted_at IS NULL',
      whereArgs: [id],
      limit: 1,
    );
    return rows.isEmpty ? null : Habit.fromMap(rows.first);
  }

  Future<void> upsert(Habit habit) async {
    await _db.insert('habits', {
      ...habit.toMap(),
      'deleted_at': null,
      'dirty': 1,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  /// Soft delete keeps a tombstone so a later sync can propagate the removal.
  Future<void> softDelete(String id, DateTime now) async {
    final ms = now.millisecondsSinceEpoch;
    await _db.transaction((txn) async {
      await txn.update(
        'habits',
        {'deleted_at': ms, 'updated_at': ms, 'dirty': 1},
        where: 'id = ?',
        whereArgs: [id],
      );
      await txn.update(
        'completions',
        {'deleted_at': ms, 'updated_at': ms, 'dirty': 1},
        where: 'habit_id = ? AND deleted_at IS NULL',
        whereArgs: [id],
      );
    });
  }

  Future<void> wipeAll() async {
    await _db.transaction((txn) async {
      await txn.delete('completions');
      await txn.delete('habits');
      await txn.delete('timer_session');
      await txn.delete('meta');
    });
  }
}

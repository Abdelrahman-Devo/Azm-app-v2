import 'package:sqflite/sqflite.dart';

import '../domain/timer_session.dart';

/// Persists the single active timer session so it survives app restarts.
class TimerRepository {
  TimerRepository(this._db);

  final Database _db;

  Future<TimerSession?> load() async {
    final rows = await _db.query('timer_session', where: 'id = 1', limit: 1);
    if (rows.isEmpty) return null;
    final m = rows.first;
    return TimerSession(
      sessionId: m['session_id']! as String,
      habitId: m['habit_id']! as String,
      targetSeconds: m['target_seconds']! as int,
      accumulatedMs: m['accumulated_ms']! as int,
      startedAtMs: m['started_at_ms'] as int?,
      proofPath: m['proof_path'] as String?,
    );
  }

  Future<void> save(TimerSession s) async {
    await _db.insert('timer_session', {
      'id': 1,
      'session_id': s.sessionId,
      'habit_id': s.habitId,
      'target_seconds': s.targetSeconds,
      'accumulated_ms': s.accumulatedMs,
      'started_at_ms': s.startedAtMs,
      'proof_path': s.proofPath,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> clear() async {
    await _db.delete('timer_session');
  }
}

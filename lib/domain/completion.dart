class Completion {
  const Completion({
    required this.id,
    required this.habitId,
    required this.dateKey,
    required this.completedAt,
    required this.durationSeconds,
    required this.xp,
    required this.sessionId,
    this.proofPath,
  });

  final String id;
  final String habitId;

  /// Local calendar day (yyyy-MM-dd) the habit was completed for.
  final String dateKey;
  final DateTime completedAt;
  final int durationSeconds;
  final int xp;

  /// Unique per timer session, which prevents counting a session twice.
  final String sessionId;
  final String? proofPath;

  Map<String, Object?> toMap() => {
    'id': id,
    'habit_id': habitId,
    'date_key': dateKey,
    'completed_at': completedAt.millisecondsSinceEpoch,
    'duration_seconds': durationSeconds,
    'xp': xp,
    'session_id': sessionId,
    'proof_path': proofPath,
    'updated_at': completedAt.millisecondsSinceEpoch,
  };

  factory Completion.fromMap(Map<String, Object?> m) => Completion(
    id: m['id']! as String,
    habitId: m['habit_id']! as String,
    dateKey: m['date_key']! as String,
    completedAt: DateTime.fromMillisecondsSinceEpoch(m['completed_at']! as int),
    durationSeconds: (m['duration_seconds'] as int?) ?? 0,
    xp: (m['xp'] as int?) ?? 0,
    sessionId: m['session_id']! as String,
    proofPath: m['proof_path'] as String?,
  );
}

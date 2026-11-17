const List<int> allWeekdays = [1, 2, 3, 4, 5, 6, 7];

int weekdaysToMask(Iterable<int> weekdays) {
  var mask = 0;
  for (final d in weekdays) {
    if (d >= 1 && d <= 7) mask |= 1 << (d - 1);
  }
  return mask;
}

List<int> maskToWeekdays(int mask) => [
  for (var d = 1; d <= 7; d++)
    if (mask & (1 << (d - 1)) != 0) d,
];

class Habit {
  const Habit({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.updatedAt,
    this.description = '',
    this.iconKey = 'flag',
    this.colorValue = 0xFF2FBF71,
    this.durationMinutes = 15,
    this.weekdays = allWeekdays,
    this.reminderMinutes,
    this.requireProof = false,
    this.isPaused = false,
  });

  final String id;
  final String name;
  final String description;
  final String iconKey;
  final int colorValue;
  final int durationMinutes;

  /// DateTime.weekday values (Monday = 1 ... Sunday = 7).
  final List<int> weekdays;

  /// Minutes after midnight, or null when there is no reminder.
  final int? reminderMinutes;
  final bool requireProof;
  final bool isPaused;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get hasReminder => reminderMinutes != null;
  int get targetSeconds => durationMinutes * 60;

  bool isScheduledOn(DateTime day) => weekdays.contains(day.weekday);

  Habit copyWith({
    String? name,
    String? description,
    String? iconKey,
    int? colorValue,
    int? durationMinutes,
    List<int>? weekdays,
    int? reminderMinutes,
    bool clearReminder = false,
    bool? requireProof,
    bool? isPaused,
    DateTime? updatedAt,
  }) {
    return Habit(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      iconKey: iconKey ?? this.iconKey,
      colorValue: colorValue ?? this.colorValue,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      weekdays: weekdays ?? this.weekdays,
      reminderMinutes: clearReminder
          ? null
          : (reminderMinutes ?? this.reminderMinutes),
      requireProof: requireProof ?? this.requireProof,
      isPaused: isPaused ?? this.isPaused,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, Object?> toMap() => {
    'id': id,
    'name': name,
    'description': description,
    'icon_key': iconKey,
    'color': colorValue,
    'duration_minutes': durationMinutes,
    'weekdays': weekdaysToMask(weekdays),
    'reminder_minutes': reminderMinutes,
    'require_proof': requireProof ? 1 : 0,
    'is_paused': isPaused ? 1 : 0,
    'created_at': createdAt.millisecondsSinceEpoch,
    'updated_at': updatedAt.millisecondsSinceEpoch,
  };

  factory Habit.fromMap(Map<String, Object?> m) => Habit(
    id: m['id']! as String,
    name: m['name']! as String,
    description: (m['description'] as String?) ?? '',
    iconKey: (m['icon_key'] as String?) ?? 'flag',
    colorValue: (m['color'] as int?) ?? 0xFF2FBF71,
    durationMinutes: (m['duration_minutes'] as int?) ?? 15,
    weekdays: maskToWeekdays((m['weekdays'] as int?) ?? 127),
    reminderMinutes: m['reminder_minutes'] as int?,
    requireProof: ((m['require_proof'] as int?) ?? 0) == 1,
    isPaused: ((m['is_paused'] as int?) ?? 0) == 1,
    createdAt: DateTime.fromMillisecondsSinceEpoch(m['created_at']! as int),
    updatedAt: DateTime.fromMillisecondsSinceEpoch(m['updated_at']! as int),
  );
}

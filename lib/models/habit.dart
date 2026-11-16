class Habit {
  final String id;
  final String name;
  final String note;
  final int durationMinutes;
  final List<int> weekdays;
  final bool needsEvidence;
  final bool isPaused;
  final int completions;
  final int xp;

  const Habit({
    required this.id,
    required this.name,
    this.note = '',
    this.durationMinutes = 15,
    this.weekdays = const [1, 2, 3, 4, 5, 6, 7],
    this.needsEvidence = false,
    this.isPaused = false,
    this.completions = 0,
    this.xp = 10,
  });

  Habit copyWith({
    String? name, String? note, int? durationMinutes, List<int>? weekdays,
    bool? needsEvidence, bool? isPaused, int? completions, int? xp,
  }) => Habit(
    id: id, name: name ?? this.name, note: note ?? this.note,
    durationMinutes: durationMinutes ?? this.durationMinutes,
    weekdays: weekdays ?? this.weekdays,
    needsEvidence: needsEvidence ?? this.needsEvidence,
    isPaused: isPaused ?? this.isPaused,
    completions: completions ?? this.completions, xp: xp ?? this.xp,
  );

  Map<String, dynamic> toJson() => {
    'id': id, 'name': name, 'note': note, 'durationMinutes': durationMinutes,
    'weekdays': weekdays, 'needsEvidence': needsEvidence, 'isPaused': isPaused,
    'completions': completions, 'xp': xp,
  };

  factory Habit.fromJson(Map<String, dynamic> json) => Habit(
    id: json['id'] as String,
    name: json['name'] as String,
    note: (json['note'] as String?) ?? '',
    durationMinutes: (json['durationMinutes'] as num?)?.toInt() ?? 15,
    weekdays: ((json['weekdays'] as List?) ?? [1,2,3,4,5,6,7]).map((e) => (e as num).toInt()).toList(),
    needsEvidence: json['needsEvidence'] as bool? ?? false,
    isPaused: json['isPaused'] as bool? ?? false,
    completions: (json['completions'] as num?)?.toInt() ?? 0,
    xp: (json['xp'] as num?)?.toInt() ?? 10,
  );
}

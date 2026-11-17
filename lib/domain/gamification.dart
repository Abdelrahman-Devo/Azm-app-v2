import 'dart:math' as math;

import 'completion.dart';
import 'habit.dart';
import 'stats.dart';

/// XP is earned only by completing a full timed session, and grows with the
/// session length and the current streak. Nothing is random.
int xpForCompletion({required int durationMinutes, required int streakAfter}) {
  final lengthBonus = math.min(durationMinutes ~/ 5, 20);
  final streakBonus = math.min(streakAfter, 10);
  return 10 + lengthBonus + streakBonus;
}

class LevelInfo {
  const LevelInfo({
    required this.level,
    required this.xpIntoLevel,
    required this.xpForNext,
  });
  final int level;
  final int xpIntoLevel;
  final int xpForNext;
  double get progress => xpForNext == 0 ? 0 : xpIntoLevel / xpForNext;
}

/// Level n starts at 50 * (n - 1)^2 total XP.
LevelInfo levelForXp(int totalXp) {
  final xp = totalXp < 0 ? 0 : totalXp;
  var level = 1;
  while (xp >= 50 * level * level) {
    level++;
  }
  final start = 50 * (level - 1) * (level - 1);
  final next = 50 * level * level;
  return LevelInfo(
    level: level,
    xpIntoLevel: xp - start,
    xpForNext: next - start,
  );
}

class BadgeContext {
  const BadgeContext({
    required this.totalCompletions,
    required this.bestStreak,
    required this.proofCount,
    required this.level,
    required this.perfectDays,
    required this.totalMinutes,
  });
  final int totalCompletions;
  final int bestStreak;
  final int proofCount;
  final int level;
  final int perfectDays;
  final int totalMinutes;
}

class BadgeDef {
  const BadgeDef({
    required this.id,
    required this.title,
    required this.description,
    required this.iconKey,
    required this.earned,
  });
  final String id;
  final String title;
  final String description;
  final String iconKey;
  final bool Function(BadgeContext) earned;
}

final List<BadgeDef> allBadges = [
  BadgeDef(
    id: 'first',
    title: 'البداية',
    description: 'أكمل أول عادة لك',
    iconKey: 'start',
    earned: (c) => c.totalCompletions >= 1,
  ),
  BadgeDef(
    id: 'ten',
    title: 'عشرة إنجازات',
    description: 'أكمل 10 جلسات',
    iconKey: 'ten',
    earned: (c) => c.totalCompletions >= 10,
  ),
  BadgeDef(
    id: 'fifty',
    title: 'نصف المئة',
    description: 'أكمل 50 جلسة',
    iconKey: 'fifty',
    earned: (c) => c.totalCompletions >= 50,
  ),
  BadgeDef(
    id: 'hundred',
    title: 'المئوي',
    description: 'أكمل 100 جلسة',
    iconKey: 'hundred',
    earned: (c) => c.totalCompletions >= 100,
  ),
  BadgeDef(
    id: 'streak7',
    title: 'أسبوع متواصل',
    description: 'سلسلة التزام 7 أيام في عادة واحدة',
    iconKey: 'streak7',
    earned: (c) => c.bestStreak >= 7,
  ),
  BadgeDef(
    id: 'streak30',
    title: 'شهر من العزم',
    description: 'سلسلة التزام 30 يومًا في عادة واحدة',
    iconKey: 'streak30',
    earned: (c) => c.bestStreak >= 30,
  ),
  BadgeDef(
    id: 'proof',
    title: 'موثِّق',
    description: 'أرفق صورة إثبات بإنجاز',
    iconKey: 'camera',
    earned: (c) => c.proofCount >= 1,
  ),
  BadgeDef(
    id: 'level5',
    title: 'المستوى 5',
    description: 'ابلغ المستوى الخامس',
    iconKey: 'level',
    earned: (c) => c.level >= 5,
  ),
  BadgeDef(
    id: 'perfect7',
    title: 'أيام مثالية',
    description: 'أنجز كل عادات اليوم في 7 أيام',
    iconKey: 'perfect',
    earned: (c) => c.perfectDays >= 7,
  ),
  BadgeDef(
    id: 'focus10h',
    title: 'عشر ساعات',
    description: 'اجمع 10 ساعات من الجلسات المكتملة',
    iconKey: 'focus',
    earned: (c) => c.totalMinutes >= 600,
  ),
];

BadgeContext buildBadgeContext({
  required List<Habit> habits,
  required List<Completion> completions,
  DateTime? today,
}) {
  final now = today ?? DateTime.now();
  final byHabit = groupDoneByHabit(completions);
  var bestStreak = 0;
  for (final h in habits) {
    final r = computeStreaks(
      habit: h,
      doneKeys: byHabit[h.id] ?? const <String>{},
      today: now,
    );
    bestStreak = math.max(bestStreak, r.best);
  }
  final totalXp = completions.fold<int>(0, (sum, c) => sum + c.xp);
  return BadgeContext(
    totalCompletions: completions.length,
    bestStreak: bestStreak,
    proofCount: completions.where((c) => c.proofPath != null).length,
    level: levelForXp(totalXp).level,
    perfectDays: perfectDayCount(habits, completions),
    totalMinutes: completions.fold<int>(
      0,
      (sum, c) => sum + c.durationSeconds ~/ 60,
    ),
  );
}

List<BadgeDef> earnedBadges(BadgeContext context) =>
    allBadges.where((b) => b.earned(context)).toList();

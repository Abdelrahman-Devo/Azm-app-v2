import '../core/date_utils.dart';
import 'completion.dart';
import 'gamification.dart';
import 'habit.dart';
import 'stats.dart';

/// Everything the dashboard, stats and profile screens need, derived from the
/// raw habits and completions so there is a single source of truth.
class Overview {
  const Overview({
    required this.habits,
    required this.completions,
    required this.today,
    required this.doneByHabit,
    required this.streaks,
    required this.todayHabits,
    required this.doneToday,
    required this.totalXp,
    required this.level,
    required this.week,
    required this.weekGoal,
    required this.month,
    required this.badgeContext,
    required this.earned,
  });

  final List<Habit> habits;
  final List<Completion> completions;
  final DateTime today;
  final Map<String, Set<String>> doneByHabit;
  final Map<String, StreakResult> streaks;

  /// Active habits scheduled for today.
  final List<Habit> todayHabits;
  final Set<String> doneToday;
  final int totalXp;
  final LevelInfo level;

  /// Scheduled vs done from the start of the week up to today.
  final PeriodStats week;

  /// Scheduled vs done for the whole current week (the weekly goal).
  final PeriodStats weekGoal;
  final PeriodStats month;
  final BadgeContext badgeContext;
  final List<BadgeDef> earned;

  int get todayTotal => todayHabits.length;
  int get todayDone => todayHabits.where((h) => doneToday.contains(h.id)).length;
  double get todayProgress => todayTotal == 0 ? 0 : todayDone / todayTotal;

  int get bestCurrentStreak {
    var best = 0;
    for (final s in streaks.values) {
      if (s.current > best) best = s.current;
    }
    return best;
  }
}

Overview computeOverview({
  required List<Habit> habits,
  required List<Completion> completions,
  required DateTime now,
}) {
  final today = dayOnly(now);
  final byHabit = groupDoneByHabit(completions);
  final streaks = {
    for (final h in habits)
      h.id: computeStreaks(
        habit: h,
        doneKeys: byHabit[h.id] ?? const <String>{},
        today: today,
      ),
  };
  final todayHabits = habits
      .where((h) => !h.isPaused && h.isScheduledOn(today))
      .toList();
  final todayKey = dateKey(today);
  final doneToday = {
    for (final h in habits)
      if ((byHabit[h.id] ?? const <String>{}).contains(todayKey)) h.id,
  };
  final weekStart = startOfWeek(today);
  final totalXp = completions.fold<int>(0, (s, c) => s + c.xp);
  final ctx = buildBadgeContext(
    habits: habits,
    completions: completions,
    today: today,
  );
  return Overview(
    habits: habits,
    completions: completions,
    today: today,
    doneByHabit: byHabit,
    streaks: streaks,
    todayHabits: todayHabits,
    doneToday: doneToday,
    totalXp: totalXp,
    level: levelForXp(totalXp),
    week: periodStats(
      habits: habits,
      doneByHabit: byHabit,
      from: weekStart,
      to: today,
    ),
    weekGoal: periodStats(
      habits: habits,
      doneByHabit: byHabit,
      from: weekStart,
      to: addDays(weekStart, 6),
    ),
    month: periodStats(
      habits: habits,
      doneByHabit: byHabit,
      from: DateTime(today.year, today.month, 1),
      to: today,
    ),
    badgeContext: ctx,
    earned: earnedBadges(ctx),
  );
}

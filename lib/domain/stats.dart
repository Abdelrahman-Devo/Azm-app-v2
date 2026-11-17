import 'dart:math' as math;

import '../core/date_utils.dart';
import 'completion.dart';
import 'habit.dart';

class StreakResult {
  const StreakResult({required this.current, required this.best});
  final int current;
  final int best;
}

/// Streaks count consecutive *scheduled* days that were completed.
/// A scheduled day that is still pending today does not break the streak.
StreakResult computeStreaks({
  required Habit habit,
  required Set<String> doneKeys,
  required DateTime today,
}) {
  final todayDay = dayOnly(today);
  var first = dayOnly(habit.createdAt);
  for (final key in doneKeys) {
    final d = parseDateKey(key);
    if (d.isBefore(first)) first = d;
  }
  var run = 0;
  var best = 0;
  for (
    var d = first;
    !d.isAfter(todayDay);
    d = addDays(d, 1)
  ) {
    if (!habit.isScheduledOn(d)) continue;
    if (doneKeys.contains(dateKey(d))) {
      run++;
      best = math.max(best, run);
    } else if (d != todayDay) {
      run = 0;
    }
  }
  return StreakResult(current: run, best: best);
}

class PeriodStats {
  const PeriodStats({required this.scheduled, required this.done});
  final int scheduled;
  final int done;
  double get rate => scheduled == 0 ? 0 : (done / scheduled).clamp(0.0, 1.0);
  int get percent => (rate * 100).round();
}

/// Counts scheduled occurrences and completed occurrences of active habits
/// between [from] and [to] inclusive. A habit only counts from the day it was
/// created.
PeriodStats periodStats({
  required List<Habit> habits,
  required Map<String, Set<String>> doneByHabit,
  required DateTime from,
  required DateTime to,
}) {
  var scheduled = 0;
  var done = 0;
  final start = dayOnly(from);
  final end = dayOnly(to);
  for (final h in habits) {
    if (h.isPaused) continue;
    final created = dayOnly(h.createdAt);
    final doneKeys = doneByHabit[h.id] ?? const <String>{};
    for (var d = start; !d.isAfter(end); d = addDays(d, 1)) {
      if (d.isBefore(created)) continue;
      if (!h.isScheduledOn(d)) continue;
      scheduled++;
      if (doneKeys.contains(dateKey(d))) done++;
    }
  }
  return PeriodStats(scheduled: scheduled, done: done);
}

/// Number of completions on each day in [from]..[to] inclusive.
Map<DateTime, int> dailyCounts(
  List<Completion> completions,
  DateTime from,
  DateTime to,
) {
  final start = dayOnly(from);
  final end = dayOnly(to);
  final result = <DateTime, int>{};
  for (var d = start; !d.isAfter(end); d = addDays(d, 1)) {
    result[d] = 0;
  }
  for (final c in completions) {
    final d = parseDateKey(c.dateKey);
    if (result.containsKey(d)) result[d] = result[d]! + 1;
  }
  return result;
}

Map<String, Set<String>> groupDoneByHabit(List<Completion> completions) {
  final map = <String, Set<String>>{};
  for (final c in completions) {
    map.putIfAbsent(c.habitId, () => <String>{}).add(c.dateKey);
  }
  return map;
}

/// Days on which every active scheduled habit was completed.
int perfectDayCount(List<Habit> habits, List<Completion> completions) {
  final byDay = <String, Set<String>>{};
  for (final c in completions) {
    byDay.putIfAbsent(c.dateKey, () => <String>{}).add(c.habitId);
  }
  var count = 0;
  byDay.forEach((key, doneIds) {
    final day = parseDateKey(key);
    final scheduled = habits.where(
      (h) =>
          !h.isPaused &&
          !dayOnly(h.createdAt).isAfter(day) &&
          h.isScheduledOn(day),
    );
    if (scheduled.isNotEmpty && scheduled.every((h) => doneIds.contains(h.id))) {
      count++;
    }
  });
  return count;
}

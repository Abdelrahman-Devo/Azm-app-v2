import 'package:azm/core/date_utils.dart';
import 'package:azm/domain/completion.dart';
import 'package:azm/domain/gamification.dart';
import 'package:azm/domain/habit.dart';
import 'package:azm/domain/stats.dart';
import 'package:flutter_test/flutter_test.dart';

Habit habit({
  String id = 'h',
  List<int> weekdays = allWeekdays,
  DateTime? created,
  bool paused = false,
}) => Habit(
  id: id,
  name: id,
  weekdays: weekdays,
  isPaused: paused,
  createdAt: created ?? DateTime(2026, 1, 1),
  updatedAt: DateTime(2026, 1, 1),
);

Completion completion(String habitId, DateTime day, {String? proof}) =>
    Completion(
      id: '$habitId-${dateKey(day)}',
      habitId: habitId,
      dateKey: dateKey(day),
      completedAt: day,
      durationSeconds: 900,
      xp: 12,
      sessionId: 's-$habitId-${dateKey(day)}',
      proofPath: proof,
    );

void main() {
  final today = DateTime(2026, 11, 16); // a Monday

  group('streaks', () {
    test('counts consecutive completed days up to today', () {
      final keys = {
        dateKey(DateTime(2026, 11, 14)),
        dateKey(DateTime(2026, 11, 15)),
        dateKey(today),
      };
      final r = computeStreaks(
        habit: habit(created: DateTime(2026, 11, 10)),
        doneKeys: keys,
        today: today,
      );
      expect(r.current, 3);
      expect(r.best, 3);
    });

    test('a pending today does not break the streak', () {
      final keys = {
        dateKey(DateTime(2026, 11, 14)),
        dateKey(DateTime(2026, 11, 15)),
      };
      final r = computeStreaks(
        habit: habit(created: DateTime(2026, 11, 10)),
        doneKeys: keys,
        today: today,
      );
      expect(r.current, 2);
    });

    test('a missed past day resets the current streak but keeps best', () {
      final keys = {
        dateKey(DateTime(2026, 11, 10)),
        dateKey(DateTime(2026, 11, 11)),
        dateKey(DateTime(2026, 11, 12)),
        dateKey(DateTime(2026, 11, 15)),
      };
      final r = computeStreaks(
        habit: habit(created: DateTime(2026, 11, 10)),
        doneKeys: keys,
        today: today,
      );
      expect(r.best, 3);
      expect(r.current, 1);
    });

    test('unscheduled days are skipped, not counted as misses', () {
      // Scheduled only Saturday (6) and Monday (1).
      final h = habit(
        weekdays: const [DateTime.saturday, DateTime.monday],
        created: DateTime(2026, 11, 1),
      );
      final keys = {
        dateKey(DateTime(2026, 11, 14)), // Sat
        dateKey(DateTime(2026, 11, 16)), // Mon (today)
      };
      final r = computeStreaks(habit: h, doneKeys: keys, today: today);
      expect(r.current, 2);
    });
  });

  group('period stats', () {
    test('counts only scheduled days since the habit was created', () {
      final h = habit(created: DateTime(2026, 11, 14));
      final stats = periodStats(
        habits: [h],
        doneByHabit: {
          'h': {dateKey(DateTime(2026, 11, 14))},
        },
        from: DateTime(2026, 11, 1),
        to: today,
      );
      expect(stats.scheduled, 3);
      expect(stats.done, 1);
      expect(stats.percent, 33);
    });

    test('paused habits are excluded', () {
      final stats = periodStats(
        habits: [habit(paused: true)],
        doneByHabit: const {},
        from: DateTime(2026, 11, 1),
        to: today,
      );
      expect(stats.scheduled, 0);
      expect(stats.rate, 0);
    });
  });

  group('week helpers', () {
    test('week starts on Saturday', () {
      expect(startOfWeek(DateTime(2026, 11, 16)), DateTime(2026, 11, 14));
      expect(startOfWeek(DateTime(2026, 11, 14)), DateTime(2026, 11, 14));
      expect(startOfWeek(DateTime(2026, 11, 20)), DateTime(2026, 11, 14));
    });

    test('dateKey round trips', () {
      expect(parseDateKey(dateKey(DateTime(2026, 3, 5))), DateTime(2026, 3, 5));
      expect(dateKey(DateTime(2026, 3, 5)), '2026-03-05');
    });

    test('weekday mask round trips', () {
      final days = [1, 3, 6];
      expect(maskToWeekdays(weekdaysToMask(days)), days);
      expect(maskToWeekdays(weekdaysToMask(allWeekdays)), allWeekdays);
    });

    test('formatClock', () {
      expect(formatClock(0), '00:00');
      expect(formatClock(65), '01:05');
      expect(formatClock(3725), '01:02:05');
      expect(formatClock(-4), '00:00');
    });
  });

  group('gamification', () {
    test('xp grows with duration and streak, deterministically', () {
      expect(xpForCompletion(durationMinutes: 15, streakAfter: 1), 14);
      expect(xpForCompletion(durationMinutes: 15, streakAfter: 1), 14);
      expect(xpForCompletion(durationMinutes: 60, streakAfter: 30), 32);
    });

    test('levels follow the XP curve', () {
      expect(levelForXp(0).level, 1);
      expect(levelForXp(49).level, 1);
      expect(levelForXp(50).level, 2);
      expect(levelForXp(199).level, 2);
      expect(levelForXp(200).level, 3);
      final l = levelForXp(120);
      expect(l.level, 2);
      expect(l.xpIntoLevel, 70);
      expect(l.xpForNext, 150);
    });

    test('badges are earned from real data only', () {
      final h = habit(created: DateTime(2026, 11, 1));
      final none = buildBadgeContext(
        habits: [h],
        completions: const [],
        today: today,
      );
      expect(earnedBadges(none), isEmpty);

      final comps = [
        for (var d = 10; d <= 16; d++)
          completion('h', DateTime(2026, 11, d), proof: d == 16 ? '/p.jpg' : null),
      ];
      final ctx = buildBadgeContext(habits: [h], completions: comps, today: today);
      final ids = earnedBadges(ctx).map((b) => b.id).toSet();
      expect(ids, containsAll(['first', 'streak7', 'proof']));
      expect(ids, isNot(contains('ten')));
    });
  });
}

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../core/date_utils.dart';
import '../domain/completion.dart';
import '../domain/gamification.dart';
import '../domain/habit.dart';
import '../domain/stats.dart';
import 'providers.dart';

sealed class CompleteResult {
  const CompleteResult();
}

class CompleteSuccess extends CompleteResult {
  const CompleteSuccess({
    required this.completion,
    required this.streak,
    required this.newBadgeTitles,
    required this.leveledUpTo,
  });
  final Completion completion;
  final int streak;
  final List<String> newBadgeTitles;

  /// Non-null when this completion raised the user's level.
  final int? leveledUpTo;
}

class CompleteTooEarly extends CompleteResult {
  const CompleteTooEarly(this.remainingSeconds);
  final int remainingSeconds;
}

class CompleteNeedsProof extends CompleteResult {
  const CompleteNeedsProof();
}

class CompleteAlreadyDone extends CompleteResult {
  const CompleteAlreadyDone();
}

class CompleteNoSession extends CompleteResult {
  const CompleteNoSession();
}

/// Turns a finished timer session into a stored completion.
///
/// Guarantees: a habit can only be completed after its full duration has
/// elapsed, a required proof photo must be attached, and a session or a day
/// can never be counted twice.
class CompletionService {
  CompletionService(this._ref);

  final Ref _ref;
  static const _uuid = Uuid();

  Future<CompleteResult> complete(Habit habit) async {
    final now = _ref.read(clockProvider)();
    final nowMs = now.millisecondsSinceEpoch;
    final session = _ref.read(timerProvider).value;
    if (session == null || session.habitId != habit.id) {
      return const CompleteNoSession();
    }
    if (!session.isComplete(nowMs)) {
      return CompleteTooEarly(session.remainingSeconds(nowMs));
    }
    if (habit.requireProof && session.proofPath == null) {
      return const CompleteNeedsProof();
    }

    final completionRepo = _ref.read(completionRepositoryProvider);
    final habitRepo = _ref.read(habitRepositoryProvider);
    final key = dateKey(now);

    final existingForHabit = await completionRepo.forHabit(habit.id);
    final doneKeys = existingForHabit.map((c) => c.dateKey).toSet();
    if (doneKeys.contains(key)) {
      await _ref.read(timerProvider.notifier).clearFinished();
      return const CompleteAlreadyDone();
    }

    final streakAfter = computeStreaks(
      habit: habit,
      doneKeys: {...doneKeys, key},
      today: now,
    ).current;
    final xp = xpForCompletion(
      durationMinutes: habit.durationMinutes,
      streakAfter: streakAfter,
    );
    final completion = Completion(
      id: _uuid.v4(),
      habitId: habit.id,
      dateKey: key,
      completedAt: now,
      durationSeconds: habit.targetSeconds,
      xp: xp,
      sessionId: session.sessionId,
      proofPath: session.proofPath,
    );

    final habits = await habitRepo.all();
    final before = await completionRepo.all();
    final inserted = await completionRepo.insertIfNew(completion);
    if (!inserted) {
      await _ref.read(timerProvider.notifier).clearFinished();
      return const CompleteAlreadyDone();
    }
    final after = [completion, ...before];

    final ctxBefore = buildBadgeContext(
      habits: habits,
      completions: before,
      today: now,
    );
    final ctxAfter = buildBadgeContext(
      habits: habits,
      completions: after,
      today: now,
    );
    final earnedBefore = earnedBadges(ctxBefore).map((b) => b.id).toSet();
    final newBadges = earnedBadges(
      ctxAfter,
    ).where((b) => !earnedBefore.contains(b.id)).map((b) => b.title).toList();
    final leveledUp = ctxAfter.level > ctxBefore.level ? ctxAfter.level : null;

    await _ref.read(timerProvider.notifier).clearFinished();
    await _ref.read(completionsProvider.notifier).reload();

    return CompleteSuccess(
      completion: completion,
      streak: streakAfter,
      newBadgeTitles: newBadges,
      leveledUpTo: leveledUp,
    );
  }
}

final completionServiceProvider = Provider<CompletionService>(
  (ref) => CompletionService(ref),
);

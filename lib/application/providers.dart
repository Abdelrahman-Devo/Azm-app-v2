import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../core/app_config.dart';
import '../data/app_database.dart';
import '../data/auth_service.dart';
import '../data/completion_repository.dart';
import '../data/habit_repository.dart';
import '../data/notification_service.dart';
import '../data/proof_storage.dart';
import '../data/settings_repository.dart';
import '../data/timer_repository.dart';
import '../domain/completion.dart';
import '../domain/habit.dart';
import '../domain/overview.dart';
import '../domain/timer_session.dart';

// ---------------------------------------------------------------------------
// Infrastructure (overridden in main.dart / tests)
// ---------------------------------------------------------------------------

final databaseProvider = Provider<AppDatabase>(
  (ref) => throw UnimplementedError('databaseProvider must be overridden'),
);

final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) =>
      throw UnimplementedError('sharedPreferencesProvider must be overridden'),
);

final notificationServiceProvider = Provider<NotificationService>(
  (ref) => NoopNotificationService(),
);

final proofStorageProvider = Provider<ProofStorage>(
  (ref) => ProofStorage(getApplicationDocumentsDirectory),
);

/// Injectable clock so time-dependent logic can be tested deterministically.
final clockProvider = Provider<DateTime Function()>((ref) => DateTime.now);

final authServiceProvider = Provider<AuthService>(
  (ref) => const AuthService(configured: AppConfig.supabaseConfigured),
);

// ---------------------------------------------------------------------------
// Repositories
// ---------------------------------------------------------------------------

final habitRepositoryProvider = Provider<HabitRepository>(
  (ref) => HabitRepository(ref.watch(databaseProvider).db),
);

final completionRepositoryProvider = Provider<CompletionRepository>(
  (ref) => CompletionRepository(ref.watch(databaseProvider).db),
);

final timerRepositoryProvider = Provider<TimerRepository>(
  (ref) => TimerRepository(ref.watch(databaseProvider).db),
);

final settingsRepositoryProvider = Provider<SettingsRepository>(
  (ref) => SettingsRepository(ref.watch(sharedPreferencesProvider)),
);

// ---------------------------------------------------------------------------
// Settings
// ---------------------------------------------------------------------------

class SettingsNotifier extends Notifier<AppSettings> {
  @override
  AppSettings build() => ref.watch(settingsRepositoryProvider).load();

  Future<void> _update(AppSettings next) async {
    state = next;
    await ref.read(settingsRepositoryProvider).save(next);
  }

  Future<void> setThemeMode(String mode) =>
      _update(state.copyWith(themeMode: mode));
  Future<void> setLocale(String code) =>
      _update(state.copyWith(localeCode: code));
  Future<void> completeOnboarding() =>
      _update(state.copyWith(onboardingDone: true));
  Future<void> skipAuth() => _update(state.copyWith(authSkipped: true));
  Future<void> setDisplayName(String name) =>
      _update(state.copyWith(displayName: name.trim()));
}

final settingsProvider = NotifierProvider<SettingsNotifier, AppSettings>(
  SettingsNotifier.new,
);

// ---------------------------------------------------------------------------
// Habits
// ---------------------------------------------------------------------------

class HabitsNotifier extends AsyncNotifier<List<Habit>> {
  HabitRepository get _repo => ref.read(habitRepositoryProvider);

  @override
  Future<List<Habit>> build() => ref.watch(habitRepositoryProvider).all();

  Future<void> _reload() async {
    state = AsyncData(await _repo.all());
  }

  /// Creates or updates a habit and (re)schedules its reminders.
  Future<void> save(Habit habit) async {
    final saved = habit.copyWith(updatedAt: ref.read(clockProvider)());
    await _repo.upsert(saved);
    await _reload();
    await ref.read(notificationServiceProvider).scheduleHabitReminders(saved);
  }

  Future<void> setPaused(Habit habit, bool paused) async {
    await save(habit.copyWith(isPaused: paused));
    if (paused) {
      await ref.read(timerProvider.notifier).discardForHabit(habit.id);
    }
  }

  Future<void> delete(String id) async {
    await ref.read(timerProvider.notifier).discardForHabit(id);
    await _repo.softDelete(id, ref.read(clockProvider)());
    await ref.read(notificationServiceProvider).cancelHabitReminders(id);
    await _reload();
    await ref.read(completionsProvider.notifier).reload();
  }

  Future<void> reload() => _reload();
}

final habitsProvider = AsyncNotifierProvider<HabitsNotifier, List<Habit>>(
  HabitsNotifier.new,
);

// ---------------------------------------------------------------------------
// Completions
// ---------------------------------------------------------------------------

class CompletionsNotifier extends AsyncNotifier<List<Completion>> {
  @override
  Future<List<Completion>> build() =>
      ref.watch(completionRepositoryProvider).all();

  Future<void> reload() async {
    state = AsyncData(await ref.read(completionRepositoryProvider).all());
  }
}

final completionsProvider =
    AsyncNotifierProvider<CompletionsNotifier, List<Completion>>(
      CompletionsNotifier.new,
    );

// ---------------------------------------------------------------------------
// Timer
// ---------------------------------------------------------------------------

enum StartResult { started, alreadyActive, otherActive }

class TimerNotifier extends AsyncNotifier<TimerSession?> {
  static const _uuid = Uuid();

  TimerRepository get _repo => ref.read(timerRepositoryProvider);
  int _nowMs() => ref.read(clockProvider)().millisecondsSinceEpoch;

  @override
  Future<TimerSession?> build() => ref.watch(timerRepositoryProvider).load();

  Future<StartResult> start(Habit habit) async {
    final current = state.value;
    if (current != null) {
      return current.habitId == habit.id
          ? StartResult.alreadyActive
          : StartResult.otherActive;
    }
    final session = TimerSession.start(
      sessionId: _uuid.v4(),
      habitId: habit.id,
      targetSeconds: habit.targetSeconds,
      nowMs: _nowMs(),
    );
    await _repo.save(session);
    state = AsyncData(session);
    await ref
        .read(notificationServiceProvider)
        .scheduleTimerEnd(
          habitName: habit.name,
          remainingSeconds: habit.targetSeconds,
        );
    return StartResult.started;
  }

  Future<void> pause() async {
    final s = state.value;
    if (s == null || !s.isRunning) return;
    final next = s.pause(_nowMs());
    await _repo.save(next);
    state = AsyncData(next);
    await ref.read(notificationServiceProvider).cancelTimerEnd();
  }

  Future<void> resume(String habitName) async {
    final s = state.value;
    if (s == null || s.isRunning) return;
    final now = _nowMs();
    final next = s.resume(now);
    await _repo.save(next);
    state = AsyncData(next);
    await ref
        .read(notificationServiceProvider)
        .scheduleTimerEnd(
          habitName: habitName,
          remainingSeconds: next.remainingSeconds(now),
        );
  }

  /// Throws away the current session (the "Reset" action).
  Future<void> reset() async {
    final s = state.value;
    if (s == null) return;
    final proof = s.proofPath;
    await _repo.clear();
    state = const AsyncData(null);
    await ref.read(notificationServiceProvider).cancelTimerEnd();
    if (proof != null) {
      await ref.read(proofStorageProvider).delete(proof);
    }
  }

  Future<void> discardForHabit(String habitId) async {
    final s = state.value;
    if (s != null && s.habitId == habitId) await reset();
  }

  Future<void> setProof(String? path) async {
    final s = state.value;
    if (s == null) return;
    final old = s.proofPath;
    final next = s.withProof(path);
    await _repo.save(next);
    state = AsyncData(next);
    if (old != null && old != path) {
      await ref.read(proofStorageProvider).delete(old);
    }
  }

  /// Called by the completion service once the completion is stored.
  Future<void> clearFinished() async {
    await _repo.clear();
    state = const AsyncData(null);
    await ref.read(notificationServiceProvider).cancelTimerEnd();
  }
}

final timerProvider = AsyncNotifierProvider<TimerNotifier, TimerSession?>(
  TimerNotifier.new,
);

// ---------------------------------------------------------------------------
// Derived
// ---------------------------------------------------------------------------

final overviewProvider = Provider<AsyncValue<Overview>>((ref) {
  final habits = ref.watch(habitsProvider);
  final completions = ref.watch(completionsProvider);
  final now = ref.watch(clockProvider)();
  if (habits.hasError) {
    return AsyncError(habits.error!, habits.stackTrace ?? StackTrace.current);
  }
  if (completions.hasError) {
    return AsyncError(
      completions.error!,
      completions.stackTrace ?? StackTrace.current,
    );
  }
  final h = habits.value;
  final c = completions.value;
  if (h == null || c == null) return const AsyncLoading();
  return AsyncData(computeOverview(habits: h, completions: c, now: now));
});

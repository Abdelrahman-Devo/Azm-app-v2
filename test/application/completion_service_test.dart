import 'package:azm/application/completion_service.dart';
import 'package:azm/application/providers.dart';
import 'package:azm/data/app_database.dart';
import 'package:azm/domain/habit.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  sqfliteFfiInit();

  late AppDatabase db;
  late DateTime now;
  late ProviderContainer container;

  Habit habit({bool proof = false}) => Habit(
    id: 'h1',
    name: 'قراءة',
    durationMinutes: 10,
    requireProof: proof,
    createdAt: DateTime(2026, 11, 1),
    updatedAt: DateTime(2026, 11, 1),
  );

  Future<ProviderContainer> makeContainer() async {
    final c = ProviderContainer(
      overrides: [
        databaseProvider.overrideWithValue(db),
        clockProvider.overrideWithValue(() => now),
      ],
    );
    addTearDown(c.dispose);
    await c.read(habitsProvider.future);
    await c.read(completionsProvider.future);
    await c.read(timerProvider.future);
    return c;
  }

  setUp(() async {
    now = DateTime(2026, 11, 16, 9, 0, 0);
    db = await AppDatabase.open(databaseFactoryFfi, inMemoryDatabasePath);
    container = await makeContainer();
  });

  tearDown(() async => db.close());

  test('cannot complete before the duration has elapsed', () async {
    final h = habit();
    await container.read(habitsProvider.notifier).save(h);
    expect(
      await container.read(timerProvider.notifier).start(h),
      StartResult.started,
    );

    now = now.add(const Duration(minutes: 9, seconds: 59));
    final early = await container.read(completionServiceProvider).complete(h);
    expect(early, isA<CompleteTooEarly>());
    expect((early as CompleteTooEarly).remainingSeconds, 1);
    expect(container.read(completionsProvider).value, isEmpty);
    // The session is still there so the user can keep going.
    expect(container.read(timerProvider).value, isNotNull);
  });

  test('completes once, awards XP and clears the session', () async {
    final h = habit();
    await container.read(habitsProvider.notifier).save(h);
    await container.read(timerProvider.notifier).start(h);
    now = now.add(const Duration(minutes: 10));

    final result = await container.read(completionServiceProvider).complete(h);
    expect(result, isA<CompleteSuccess>());
    final ok = result as CompleteSuccess;
    expect(ok.completion.xp, 10 + 2 + 1);
    expect(ok.streak, 1);
    expect(container.read(timerProvider).value, isNull);
    expect(container.read(completionsProvider).value, hasLength(1));

    // Doing it again the same day is rejected, never double counted.
    await container.read(timerProvider.notifier).start(h);
    now = now.add(const Duration(minutes: 10));
    final again = await container.read(completionServiceProvider).complete(h);
    expect(again, isA<CompleteAlreadyDone>());
    expect(container.read(completionsProvider).value, hasLength(1));
  });

  test('pause time does not count toward the duration', () async {
    final h = habit();
    await container.read(habitsProvider.notifier).save(h);
    final timer = container.read(timerProvider.notifier);
    await timer.start(h);
    now = now.add(const Duration(minutes: 5));
    await timer.pause();
    now = now.add(const Duration(hours: 3));
    await timer.resume(h.name);
    now = now.add(const Duration(minutes: 4));

    expect(
      await container.read(completionServiceProvider).complete(h),
      isA<CompleteTooEarly>(),
    );
    now = now.add(const Duration(minutes: 1));
    expect(
      await container.read(completionServiceProvider).complete(h),
      isA<CompleteSuccess>(),
    );
  });

  test('required proof blocks completion until attached', () async {
    final h = habit(proof: true);
    await container.read(habitsProvider.notifier).save(h);
    await container.read(timerProvider.notifier).start(h);
    now = now.add(const Duration(minutes: 10));
    expect(
      await container.read(completionServiceProvider).complete(h),
      isA<CompleteNeedsProof>(),
    );
    await container.read(timerProvider.notifier).setProof('/proof.jpg');
    final result = await container.read(completionServiceProvider).complete(h);
    expect(result, isA<CompleteSuccess>());
    expect(
      (result as CompleteSuccess).completion.proofPath,
      '/proof.jpg',
    );
  });

  test('timer survives an app restart (new container, same database)', () async {
    final h = habit();
    await container.read(habitsProvider.notifier).save(h);
    await container.read(timerProvider.notifier).start(h);
    final startedAt = now;

    // "Kill" the app and reopen it 12 minutes later.
    now = startedAt.add(const Duration(minutes: 12));
    final reopened = await makeContainer();
    final session = reopened.read(timerProvider).value;
    expect(session, isNotNull);
    expect(session!.isRunning, isTrue);
    expect(session.isComplete(now.millisecondsSinceEpoch), isTrue);

    final result = await reopened.read(completionServiceProvider).complete(h);
    expect(result, isA<CompleteSuccess>());
  });

  test('paused timer restores with its accumulated time', () async {
    final h = habit();
    await container.read(habitsProvider.notifier).save(h);
    final timer = container.read(timerProvider.notifier);
    await timer.start(h);
    now = now.add(const Duration(minutes: 4));
    await timer.pause();

    now = now.add(const Duration(days: 1));
    final reopened = await makeContainer();
    final session = reopened.read(timerProvider).value!;
    expect(session.isRunning, isFalse);
    expect(session.elapsedMs(now.millisecondsSinceEpoch), 4 * 60 * 1000);
  });

  test('only one session at a time; reset discards it without a record', () async {
    final h = habit();
    final other = habit().copyWith(name: 'x');
    final timer = container.read(timerProvider.notifier);
    await container.read(habitsProvider.notifier).save(h);
    expect(await timer.start(h), StartResult.started);
    expect(await timer.start(h), StartResult.alreadyActive);
    expect(
      await timer.start(Habit(
        id: 'h2',
        name: other.name,
        createdAt: now,
        updatedAt: now,
      )),
      StartResult.otherActive,
    );
    await timer.reset();
    expect(container.read(timerProvider).value, isNull);
    expect(container.read(completionsProvider).value, isEmpty);
  });

  test('deleting a habit removes its running session', () async {
    final h = habit();
    await container.read(habitsProvider.notifier).save(h);
    await container.read(timerProvider.notifier).start(h);
    await container.read(habitsProvider.notifier).delete(h.id);
    expect(container.read(timerProvider).value, isNull);
    expect(container.read(habitsProvider).value, isEmpty);
  });
}

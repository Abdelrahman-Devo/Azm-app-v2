import 'dart:io';

import 'package:azm/data/app_database.dart';
import 'package:azm/data/completion_repository.dart';
import 'package:azm/data/habit_repository.dart';
import 'package:azm/data/proof_storage.dart';
import 'package:azm/data/timer_repository.dart';
import 'package:azm/domain/completion.dart';
import 'package:azm/domain/habit.dart';
import 'package:azm/domain/timer_session.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

Habit _habit(String id) => Habit(
  id: id,
  name: 'قراءة',
  description: 'وصف',
  iconKey: 'book',
  colorValue: 0xFF1E88E5,
  durationMinutes: 20,
  weekdays: const [1, 3, 6],
  reminderMinutes: 480,
  requireProof: true,
  createdAt: DateTime(2026, 11, 1),
  updatedAt: DateTime(2026, 11, 1),
);

Completion _completion(String id, String habitId, String day, String session) =>
    Completion(
      id: id,
      habitId: habitId,
      dateKey: day,
      completedAt: DateTime(2026, 11, 16, 9),
      durationSeconds: 1200,
      xp: 15,
      sessionId: session,
    );

void main() {
  sqfliteFfiInit();

  late AppDatabase appDb;

  setUp(() async {
    appDb = await AppDatabase.open(databaseFactoryFfi, inMemoryDatabasePath);
  });

  tearDown(() async => appDb.close());

  test('habit round trips through SQLite', () async {
    final repo = HabitRepository(appDb.db);
    await repo.upsert(_habit('a'));
    final loaded = (await repo.all()).single;
    expect(loaded.name, 'قراءة');
    expect(loaded.weekdays, [1, 3, 6]);
    expect(loaded.reminderMinutes, 480);
    expect(loaded.requireProof, isTrue);
    expect(loaded.colorValue, 0xFF1E88E5);
  });

  test('upsert updates, soft delete hides habit and its completions', () async {
    final habits = HabitRepository(appDb.db);
    final comps = CompletionRepository(appDb.db);
    await habits.upsert(_habit('a'));
    await habits.upsert(_habit('a').copyWith(name: 'جديد'));
    expect((await habits.all()).single.name, 'جديد');

    await comps.insertIfNew(_completion('c1', 'a', '2026-11-16', 's1'));
    expect(await comps.all(), hasLength(1));

    await habits.softDelete('a', DateTime(2026, 11, 17));
    expect(await habits.all(), isEmpty);
    expect(await comps.all(), isEmpty);
  });

  test('a day or a session can only be completed once', () async {
    final comps = CompletionRepository(appDb.db);
    await HabitRepository(appDb.db).upsert(_habit('a'));
    expect(
      await comps.insertIfNew(_completion('c1', 'a', '2026-11-16', 's1')),
      isTrue,
    );
    // Same day, different session.
    expect(
      await comps.insertIfNew(_completion('c2', 'a', '2026-11-16', 's2')),
      isFalse,
    );
    // Same session, different day.
    expect(
      await comps.insertIfNew(_completion('c3', 'a', '2026-11-17', 's1')),
      isFalse,
    );
    expect(
      await comps.insertIfNew(_completion('c4', 'a', '2026-11-17', 's4')),
      isTrue,
    );
    expect(await comps.all(), hasLength(2));
  });

  test('timer session persists and restores exactly', () async {
    final repo = TimerRepository(appDb.db);
    expect(await repo.load(), isNull);

    final running = TimerSession.start(
      sessionId: 's1',
      habitId: 'a',
      targetSeconds: 900,
      nowMs: 5000,
    );
    await repo.save(running);
    var loaded = (await repo.load())!;
    expect(loaded.isRunning, isTrue);
    expect(loaded.startedAtMs, 5000);
    expect(loaded.elapsedMs(65000), 60000);

    await repo.save(running.pause(35000).withProof('/p.jpg'));
    loaded = (await repo.load())!;
    expect(loaded.isRunning, isFalse);
    expect(loaded.accumulatedMs, 30000);
    expect(loaded.proofPath, '/p.jpg');

    await repo.clear();
    expect(await repo.load(), isNull);
  });

  group('ProofStorage', () {
    late Directory tmp;
    setUp(() => tmp = Directory.systemTemp.createTempSync('azm_proof'));
    tearDown(() => tmp.deleteSync(recursive: true));

    test('copies the file and verifies it', () async {
      final src = File('${tmp.path}/in.png')..writeAsBytesSync([1, 2, 3, 4]);
      final storage = ProofStorage(() async => tmp);
      final saved = await storage.save(src);
      expect(saved, contains('proofs'));
      expect(File(saved).lengthSync(), 4);
      expect(await storage.exists(saved), isTrue);
      await storage.delete(saved);
      expect(await storage.exists(saved), isFalse);
    });

    test('rejects missing and empty files', () async {
      final storage = ProofStorage(() async => tmp);
      await expectLater(
        storage.save(File('${tmp.path}/none.jpg')),
        throwsA(isA<ProofSaveException>()),
      );
      final empty = File('${tmp.path}/empty.jpg')..writeAsBytesSync([]);
      await expectLater(
        storage.save(empty),
        throwsA(isA<ProofSaveException>()),
      );
      final dir = Directory('${tmp.path}/proofs');
      expect(dir.existsSync() ? dir.listSync() : const [], isEmpty);
    });
  });
}

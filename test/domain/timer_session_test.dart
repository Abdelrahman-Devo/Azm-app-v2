import 'package:azm/domain/timer_session.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TimerSession fresh({int target = 600, int now = 1000000}) =>
      TimerSession.start(
        sessionId: 's1',
        habitId: 'h1',
        targetSeconds: target,
        nowMs: now,
      );

  test('elapsed derives from wall-clock timestamps', () {
    final s = fresh();
    expect(s.elapsedMs(1000000), 0);
    expect(s.elapsedMs(1000000 + 90 * 1000), 90000);
    expect(s.remainingSeconds(1000000 + 90 * 1000), 510);
  });

  test('pause freezes progress and resume continues from it', () {
    final s = fresh();
    final paused = s.pause(1000000 + 60000);
    expect(paused.isRunning, isFalse);
    // Time passing while paused does not count.
    expect(paused.elapsedMs(1000000 + 10 * 60000), 60000);
    final resumed = paused.resume(1000000 + 20 * 60000);
    expect(resumed.isRunning, isTrue);
    expect(resumed.elapsedMs(1000000 + 20 * 60000 + 30000), 90000);
  });

  test('pause and resume are idempotent', () {
    final s = fresh();
    expect(identical(s.resume(5), s), isTrue);
    final p = s.pause(1000500);
    expect(identical(p.pause(2000000), p), isTrue);
  });

  test('isComplete only after the full duration', () {
    final s = fresh(target: 60);
    expect(s.isComplete(1000000 + 59999), isFalse);
    expect(s.isComplete(1000000 + 60000), isTrue);
    expect(s.remainingSeconds(1000000 + 61000), 0);
    expect(s.progress(1000000 + 120000), 1.0);
  });

  test('a backwards clock change never reduces progress', () {
    final s = fresh();
    expect(s.elapsedMs(900000), 0);
    final p = s.pause(1030000);
    expect(p.elapsedMs(0), 30000);
  });

  test('proof path survives pause/resume', () {
    final s = fresh().withProof('/a.jpg');
    expect(s.pause(1000100).resume(1000200).proofPath, '/a.jpg');
    expect(s.withProof(null).proofPath, isNull);
  });
}

enum TimerStatus { running, paused }

/// A habit timer that is derived from wall-clock timestamps instead of a
/// ticking counter, so it stays correct when the app is closed, killed, or
/// the phone is restarted.
///
/// While running: elapsed = [accumulatedMs] + (now - [startedAtMs]).
/// While paused: elapsed = [accumulatedMs].
class TimerSession {
  const TimerSession({
    required this.sessionId,
    required this.habitId,
    required this.targetSeconds,
    required this.accumulatedMs,
    this.startedAtMs,
    this.proofPath,
  });

  factory TimerSession.start({
    required String sessionId,
    required String habitId,
    required int targetSeconds,
    required int nowMs,
  }) => TimerSession(
    sessionId: sessionId,
    habitId: habitId,
    targetSeconds: targetSeconds,
    accumulatedMs: 0,
    startedAtMs: nowMs,
  );

  final String sessionId;
  final String habitId;
  final int targetSeconds;
  final int accumulatedMs;
  final int? startedAtMs;

  /// A proof photo attached during this session (already saved to storage).
  final String? proofPath;

  TimerStatus get status =>
      startedAtMs == null ? TimerStatus.paused : TimerStatus.running;
  bool get isRunning => status == TimerStatus.running;

  int get targetMs => targetSeconds * 1000;

  int elapsedMs(int nowMs) {
    final started = startedAtMs;
    if (started == null) return accumulatedMs;
    final delta = nowMs - started;
    // A clock moved backwards must never reduce progress.
    return accumulatedMs + (delta < 0 ? 0 : delta);
  }

  int remainingMs(int nowMs) {
    final left = targetMs - elapsedMs(nowMs);
    return left < 0 ? 0 : left;
  }

  int remainingSeconds(int nowMs) => (remainingMs(nowMs) + 999) ~/ 1000;

  double progress(int nowMs) {
    if (targetMs <= 0) return 1;
    final p = elapsedMs(nowMs) / targetMs;
    return p > 1 ? 1 : p;
  }

  bool isComplete(int nowMs) => elapsedMs(nowMs) >= targetMs;

  TimerSession pause(int nowMs) {
    if (!isRunning) return this;
    return TimerSession(
      sessionId: sessionId,
      habitId: habitId,
      targetSeconds: targetSeconds,
      accumulatedMs: elapsedMs(nowMs),
      startedAtMs: null,
      proofPath: proofPath,
    );
  }

  TimerSession resume(int nowMs) {
    if (isRunning) return this;
    return TimerSession(
      sessionId: sessionId,
      habitId: habitId,
      targetSeconds: targetSeconds,
      accumulatedMs: accumulatedMs,
      startedAtMs: nowMs,
      proofPath: proofPath,
    );
  }

  TimerSession withProof(String? path) => TimerSession(
    sessionId: sessionId,
    habitId: habitId,
    targetSeconds: targetSeconds,
    accumulatedMs: accumulatedMs,
    startedAtMs: startedAtMs,
    proofPath: path,
  );
}

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../domain/habit.dart';

abstract class NotificationService {
  Future<void> init();

  /// Asks for the Android 13+ notification permission. Returns whether
  /// notifications are allowed afterwards.
  Future<bool> requestPermission();
  Future<bool> areEnabled();

  Future<void> scheduleHabitReminders(Habit habit);
  Future<void> cancelHabitReminders(String habitId);
  Future<void> rescheduleAll(List<Habit> habits);
  Future<void> cancelAll();

  Future<void> scheduleTimerEnd({
    required String habitName,
    required int remainingSeconds,
  });
  Future<void> cancelTimerEnd();
}

/// Used by tests and when notifications are unavailable.
class NoopNotificationService implements NotificationService {
  @override
  Future<void> init() async {}
  @override
  Future<bool> requestPermission() async => false;
  @override
  Future<bool> areEnabled() async => false;
  @override
  Future<void> scheduleHabitReminders(Habit habit) async {}
  @override
  Future<void> cancelHabitReminders(String habitId) async {}
  @override
  Future<void> rescheduleAll(List<Habit> habits) async {}
  @override
  Future<void> cancelAll() async {}
  @override
  Future<void> scheduleTimerEnd({
    required String habitName,
    required int remainingSeconds,
  }) async {}
  @override
  Future<void> cancelTimerEnd() async {}
}

int _stableHash(String value) {
  // FNV-1a 32-bit. Dart's String.hashCode is not guaranteed stable across runs.
  var hash = 0x811c9dc5;
  for (final unit in value.codeUnits) {
    hash ^= unit;
    hash = (hash * 0x01000193) & 0xFFFFFFFF;
  }
  return hash;
}

/// Notification ids for a habit: one per weekday, always < 2^31.
int reminderId(String habitId, int weekday) =>
    ((_stableHash(habitId) & 0x0FFFFFFF) * 8) + weekday;

const int _timerEndId = 2000000000;

class LocalNotificationService implements NotificationService {
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _ready = false;

  static const _reminderChannel = AndroidNotificationDetails(
    'azm_habit_reminders',
    'تذكيرات العادات',
    channelDescription: 'تذكير يومي بموعد عاداتك',
    importance: Importance.high,
    priority: Priority.high,
  );
  static const _timerChannel = AndroidNotificationDetails(
    'azm_timer_end',
    'انتهاء مؤقت العادة',
    channelDescription: 'تنبيه عند انتهاء مدة العادة',
    importance: Importance.high,
    priority: Priority.high,
  );

  @override
  Future<void> init() async {
    tzdata.initializeTimeZones();
    try {
      final info = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(info.identifier));
    } catch (e) {
      debugPrint('Azm: could not detect timezone ($e), using UTC');
      tz.setLocalLocation(tz.getLocation('UTC'));
    }
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      ),
    );
    _ready = true;
  }

  AndroidFlutterLocalNotificationsPlugin? get _android => _plugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >();

  @override
  Future<bool> requestPermission() async {
    if (!_ready) return false;
    final granted = await _android?.requestNotificationsPermission();
    return granted ?? false;
  }

  @override
  Future<bool> areEnabled() async {
    if (!_ready) return false;
    return await _android?.areNotificationsEnabled() ?? false;
  }

  tz.TZDateTime _nextOccurrence(int weekday, int minutesOfDay) {
    final now = tz.TZDateTime.now(tz.local);
    var d = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      minutesOfDay ~/ 60,
      minutesOfDay % 60,
    );
    while (d.weekday != weekday || !d.isAfter(now)) {
      d = d.add(const Duration(days: 1));
    }
    return d;
  }

  @override
  Future<void> scheduleHabitReminders(Habit habit) async {
    if (!_ready) return;
    await cancelHabitReminders(habit.id);
    final minutes = habit.reminderMinutes;
    if (minutes == null || habit.isPaused) return;
    for (final weekday in habit.weekdays) {
      await _plugin.zonedSchedule(
        id: reminderId(habit.id, weekday),
        title: 'حان وقت ${habit.name}',
        body: 'مدتها ${habit.durationMinutes} دقيقة. ابدأ الآن وحافظ على سلسلتك.',
        scheduledDate: _nextOccurrence(weekday, minutes),
        notificationDetails: const NotificationDetails(
          android: _reminderChannel,
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
      );
    }
  }

  @override
  Future<void> cancelHabitReminders(String habitId) async {
    if (!_ready) return;
    for (var weekday = 1; weekday <= 7; weekday++) {
      await _plugin.cancel(id: reminderId(habitId, weekday));
    }
  }

  @override
  Future<void> rescheduleAll(List<Habit> habits) async {
    if (!_ready) return;
    for (final h in habits) {
      await scheduleHabitReminders(h);
    }
  }

  @override
  Future<void> cancelAll() async {
    if (!_ready) return;
    await _plugin.cancelAll();
  }

  @override
  Future<void> scheduleTimerEnd({
    required String habitName,
    required int remainingSeconds,
  }) async {
    if (!_ready || remainingSeconds <= 0) return;
    await _plugin.zonedSchedule(
      id: _timerEndId,
      title: 'انتهى وقت $habitName',
      body: 'أحسنت! افتح التطبيق لتأكيد إنجازك.',
      scheduledDate: tz.TZDateTime.now(
        tz.local,
      ).add(Duration(seconds: remainingSeconds)),
      notificationDetails: const NotificationDetails(android: _timerChannel),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    );
  }

  @override
  Future<void> cancelTimerEnd() async {
    if (!_ready) return;
    await _plugin.cancel(id: _timerEndId);
  }
}

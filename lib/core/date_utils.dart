/// Calendar helpers. All "day" values are local calendar days.
String dateKey(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-'
    '${d.month.toString().padLeft(2, '0')}-'
    '${d.day.toString().padLeft(2, '0')}';

DateTime dayOnly(DateTime d) => DateTime(d.year, d.month, d.day);

DateTime addDays(DateTime d, int n) => DateTime(d.year, d.month, d.day + n);

DateTime parseDateKey(String key) {
  final p = key.split('-');
  return DateTime(int.parse(p[0]), int.parse(p[1]), int.parse(p[2]));
}

/// Weeks start on Saturday (Arabic calendar convention).
DateTime startOfWeek(DateTime d) {
  final delta = (d.weekday - DateTime.saturday) % 7;
  return addDays(dayOnly(d), -delta);
}

bool sameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

const List<String> arabicWeekdayNames = [
  'الاثنين',
  'الثلاثاء',
  'الأربعاء',
  'الخميس',
  'الجمعة',
  'السبت',
  'الأحد',
];

/// Index with DateTime.weekday - 1 (Monday = 0).
String weekdayName(int weekday) => arabicWeekdayNames[weekday - 1];

const List<String> arabicWeekdayShort = [
  'إثنين',
  'ثلاثاء',
  'أربعاء',
  'خميس',
  'جمعة',
  'سبت',
  'أحد',
];

String weekdayShort(int weekday) => arabicWeekdayShort[weekday - 1];

String formatClock(int totalSeconds) {
  final s = totalSeconds < 0 ? 0 : totalSeconds;
  final h = s ~/ 3600;
  final m = (s % 3600) ~/ 60;
  final sec = s % 60;
  final mm = m.toString().padLeft(2, '0');
  final ss = sec.toString().padLeft(2, '0');
  if (h > 0) return '${h.toString().padLeft(2, '0')}:$mm:$ss';
  return '$mm:$ss';
}

String formatMinutesOfDay(int minutes) {
  final h = minutes ~/ 60;
  final m = minutes % 60;
  final period = h >= 12 ? 'م' : 'ص';
  final h12 = h % 12 == 0 ? 12 : h % 12;
  return '$h12:${m.toString().padLeft(2, '0')} $period';
}

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/habit.dart';

class HabitRepository {
  static const _habitsKey = 'azm_habits_v1';
  static const _doneKey = 'azm_done_v1';
  static const _sessionKey = 'azm_session_v1';
  final _uuid = const Uuid();
  SharedPreferences? _prefs;
  List<Habit> habits = [];
  Set<String> completedToday = {};
  Map<String, dynamic>? activeSession;

  Future<void> load() async {
    _prefs = await SharedPreferences.getInstance();
    final raw = _prefs!.getString(_habitsKey);
    if (raw != null) {
      try { habits = (jsonDecode(raw) as List).map((e) => Habit.fromJson(Map<String,dynamic>.from(e))).toList(); } catch (_) { habits = []; }
    }
    final today = _todayKey();
    completedToday = (_prefs!.getStringList('$_doneKey.$today') ?? []).toSet();
    final session = _prefs!.getString(_sessionKey);
    if (session != null) {
      try { activeSession = Map<String,dynamic>.from(jsonDecode(session)); } catch (_) { activeSession = null; }
    }
    if (habits.isEmpty) {
      habits = [
        Habit(id: _uuid.v4(), name: 'قراءة القرآن', note: 'ورد يومي ولو قليلًا', durationMinutes: 15),
        Habit(id: _uuid.v4(), name: 'القراءة', note: 'اقرأ صفحات من كتابك', durationMinutes: 20),
        Habit(id: _uuid.v4(), name: 'الرياضة', note: 'حافظ على نشاطك', durationMinutes: 30),
        Habit(id: _uuid.v4(), name: 'شرب المياه', note: 'اهتم بترطيب جسمك', durationMinutes: 5),
      ];
      await _saveHabits();
    }
  }

  String _todayKey() { final d = DateTime.now(); return '${d.year}-${d.month}-${d.day}'; }
  Future<void> _saveHabits() async => _prefs!.setString(_habitsKey, jsonEncode(habits.map((e) => e.toJson()).toList()));
  Future<void> add(Habit habit) async { habits = [...habits, habit]; await _saveHabits(); }
  Future<void> update(Habit habit) async { habits = habits.map((e) => e.id == habit.id ? habit : e).toList(); await _saveHabits(); }
  Future<void> delete(String id) async { habits = habits.where((e) => e.id != id).toList(); await _saveHabits(); }
  Future<void> toggleDone(String id) async {
    if (completedToday.contains(id)) return;
    completedToday.add(id);
    await _prefs!.setStringList('$_doneKey.${_todayKey()}', completedToday.toList());
    final i = habits.indexWhere((h) => h.id == id);
    if (i >= 0) { habits[i] = habits[i].copyWith(completions: habits[i].completions + 1); await _saveHabits(); }
  }
  Future<void> saveSession(Map<String,dynamic>? session) async {
    activeSession = session;
    if (session == null) { await _prefs!.remove(_sessionKey); }
    else { await _prefs!.setString(_sessionKey, jsonEncode(session)); }
  }
  String newId() => _uuid.v4();
}

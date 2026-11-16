import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/habit_repository.dart';
import '../models/habit.dart';

final habitRepositoryProvider = Provider<HabitRepository>((ref) => throw UnimplementedError());
final habitsProvider = StateNotifierProvider<HabitsController, List<Habit>>((ref) {
  return HabitsController(ref.watch(habitRepositoryProvider));
});
final completedProvider = StateProvider<Set<String>>((ref) => ref.watch(habitRepositoryProvider).completedToday);
final themeModeProvider = StateProvider<bool>((ref) => false);

class HabitsController extends StateNotifier<List<Habit>> {
  final HabitRepository repository;
  HabitsController(this.repository) : super(List.unmodifiable(repository.habits));
  Future<void> add(Habit h) async { await repository.add(h); state = List.unmodifiable(repository.habits); }
  Future<void> update(Habit h) async { await repository.update(h); state = List.unmodifiable(repository.habits); }
  Future<void> delete(String id) async { await repository.delete(id); state = List.unmodifiable(repository.habits); }
  Future<void> complete(String id) async { await repository.toggleDone(id); state = List.unmodifiable(repository.habits); }
}

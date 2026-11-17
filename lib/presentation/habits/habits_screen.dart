import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../application/providers.dart';
import '../widgets/common.dart';
import 'habit_detail_screen.dart';
import 'habit_editor_screen.dart';
import 'habit_tile.dart';

class HabitsScreen extends ConsumerWidget {
  const HabitsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final overview = ref.watch(overviewProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('عاداتي')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () =>
            Navigator.of(context).push(azmRoute(const HabitEditorScreen())),
        icon: const Icon(Icons.add_rounded),
        label: const Text('عادة جديدة'),
      ),
      body: overview.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => EmptyState(
          icon: Icons.error_outline_rounded,
          title: 'تعذر تحميل العادات',
          message: '$e',
        ),
        data: (o) {
          if (o.habits.isEmpty) {
            return const EmptyState(
              icon: Icons.checklist_rounded,
              title: 'لا توجد عادات بعد',
              message: 'اضغط «عادة جديدة» لإنشاء أول عادة وابدأ بناء انضباطك.',
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
            itemCount: o.habits.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, i) {
              final habit = o.habits[i];
              return HabitTile(
                habit: habit,
                doneToday: o.doneToday.contains(habit.id),
                streak: o.streaks[habit.id]?.current ?? 0,
                onTap: () => Navigator.of(
                  context,
                ).push(azmRoute(HabitDetailScreen(habitId: habit.id))),
              );
            },
          );
        },
      ),
    );
  }
}

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

import '../../application/providers.dart';
import '../../core/date_utils.dart';
import '../../core/habit_style.dart';
import '../../core/motivation.dart';
import '../../core/theme.dart';
import '../../domain/overview.dart';
import '../habits/habit_detail_screen.dart';
import '../habits/habit_editor_screen.dart';
import '../habits/habit_tile.dart';
import '../profile/profile_screen.dart';
import '../widgets/common.dart';
import '../widgets/second_ticker.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final overview = ref.watch(overviewProvider);
    return Scaffold(
      body: SafeArea(
        child: overview.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => EmptyState(
            icon: Icons.error_outline_rounded,
            title: 'تعذر تحميل البيانات',
            message: '$e',
          ),
          data: (o) => _Content(overview: o),
        ),
      ),
    );
  }
}

class _Content extends ConsumerWidget {
  const _Content({required this.overview});

  final Overview overview;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final settings = ref.watch(settingsProvider);
    final o = overview;
    final date = DateFormat('EEEE، d MMMM', 'ar').format(o.today);
    final greeting = settings.displayName.isEmpty
        ? 'مرحبًا بك'
        : 'مرحبًا، ${settings.displayName}';

    if (o.habits.isEmpty) {
      return ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        children: [
          _Header(greeting: greeting, date: date),
          const SizedBox(height: 60),
          EmptyState(
            icon: Icons.flag_rounded,
            title: 'ابدأ رحلتك',
            message:
                'أضف عادتك الأولى، وحدد مدتها وأيامها، وسنتابع التزامك يومًا بيوم.',
            action: FilledButton.icon(
              onPressed: () => Navigator.of(
                context,
              ).push(azmRoute(const HabitEditorScreen())),
              icon: const Icon(Icons.add_rounded),
              label: const Text('أضف أول عادة'),
            ),
          ),
        ],
      );
    }

    final streak = o.bestCurrentStreak;
    final message = motivationFor(
      todayTotal: o.todayTotal,
      todayDone: o.todayDone,
      streak: streak,
      today: o.today,
    );

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
      children: [
        _Header(greeting: greeting, date: date),
        const SizedBox(height: 20),
        const _ActiveTimerBanner(),
        AzmCard(
          child: Row(
            children: [
              ProgressRing(
                progress: o.todayProgress,
                size: 96,
                child: Text(
                  '${(o.todayProgress * 100).round()}%',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'إنجازك اليوم',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      o.todayTotal == 0
                          ? 'لا توجد عادات مجدولة اليوم'
                          : 'أكملت ${o.todayDone} من ${o.todayTotal} عادات',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        AzmCard(
          onTap: () =>
              Navigator.of(context).push(azmRoute(const ProfileScreen())),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AzmColors.gold.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'المستوى ${o.level.level}',
                      style: const TextStyle(
                        color: AzmColors.gold,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${o.level.xpIntoLevel} / ${o.level.xpForNext} XP',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: o.level.progress.clamp(0.0, 1.0),
                  minHeight: 9,
                  backgroundColor: scheme.surfaceContainerHighest,
                  color: AzmColors.gold,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: StatTile(
                icon: Icons.local_fire_department_rounded,
                value: '$streak يوم',
                label: 'أفضل سلسلة حالية',
                color: const Color(0xFFE2674A),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: StatTile(
                icon: Icons.flag_circle_rounded,
                value: '${o.weekGoal.done} / ${o.weekGoal.scheduled}',
                label: 'هدف الأسبوع',
                color: const Color(0xFF1E88E5),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        SectionTitle(
          'عادات اليوم',
          trailing: Text(
            '${o.todayDone} / ${o.todayTotal}',
            style: TextStyle(
              color: scheme.secondary,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(height: 12),
        if (o.todayHabits.isEmpty)
          AzmCard(
            child: Text(
              'لا توجد عادات مجدولة لهذا اليوم. استمتع بيوم هادئ، أو أضف عادة جديدة.',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(height: 1.6),
            ),
          )
        else
          for (final habit in o.todayHabits)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: HabitTile(
                habit: habit,
                doneToday: o.doneToday.contains(habit.id),
                streak: o.streaks[habit.id]?.current ?? 0,
                onTap: () => Navigator.of(
                  context,
                ).push(azmRoute(HabitDetailScreen(habitId: habit.id))),
              ),
            ),
        const SizedBox(height: 12),
        AzmCard(
          color: scheme.primary,
          child: Row(
            children: [
              Icon(Icons.bolt_rounded, color: scheme.onPrimary, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: TextStyle(
                    color: scheme.onPrimary,
                    fontWeight: FontWeight.w700,
                    height: 1.6,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Header extends ConsumerWidget {
  const _Header({required this.greeting, required this.date});

  final String greeting;
  final String date;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                greeting,
                style: Theme.of(
                  context,
                ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 2),
              Text(
                date,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        IconButton.filledTonal(
          tooltip: 'الملف الشخصي',
          onPressed: () =>
              Navigator.of(context).push(azmRoute(const ProfileScreen())),
          icon: const Icon(Icons.person_rounded),
        ),
      ],
    );
  }
}

/// Shows the running/paused session (if any) so it is one tap away.
class _ActiveTimerBanner extends ConsumerWidget {
  const _ActiveTimerBanner();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(timerProvider).value;
    if (session == null) return const SizedBox.shrink();
    final habits = ref.watch(habitsProvider).value ?? const [];
    final habit = habits.where((h) => h.id == session.habitId).firstOrNull;
    if (habit == null) return const SizedBox.shrink();
    final color = colorForValue(habit.colorValue);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AzmCard(
        color: color.withValues(alpha: 0.14),
        onTap: () => Navigator.of(
          context,
        ).push(azmRoute(HabitDetailScreen(habitId: habit.id))),
        child: SecondTicker(
          builder: (context) {
            final nowMs = ref.read(clockProvider)().millisecondsSinceEpoch;
            final done = session.isComplete(nowMs);
            return Row(
              children: [
                Icon(
                  done ? Icons.check_circle_rounded : Icons.timer_rounded,
                  color: color,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        habit.name,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      Text(
                        done
                            ? 'انتهت المدة. اضغط لتأكيد الإنجاز'
                            : (session.isRunning
                                  ? 'قيد التنفيذ'
                                  : 'متوقفة مؤقتًا'),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                Text(
                  done ? '00:00' : formatClock(session.remainingSeconds(nowMs)),
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w800,
                    fontSize: 20,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

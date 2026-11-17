import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../application/providers.dart';
import '../../core/date_utils.dart';
import '../../core/habit_style.dart';
import '../../domain/overview.dart';
import '../../domain/stats.dart';
import '../widgets/common.dart';

class StatsScreen extends ConsumerWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final overview = ref.watch(overviewProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('الإحصائيات')),
      body: overview.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => EmptyState(
          icon: Icons.error_outline_rounded,
          title: 'تعذر تحميل الإحصائيات',
          message: '$e',
        ),
        data: (o) {
          if (o.habits.isEmpty) {
            return const EmptyState(
              icon: Icons.insights_rounded,
              title: 'لا توجد بيانات بعد',
              message: 'أضف عادات وأكملها لتظهر إحصائياتك هنا.',
            );
          }
          return _Content(overview: o);
        },
      ),
    );
  }
}

class _Content extends StatelessWidget {
  const _Content({required this.overview});

  final Overview overview;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final o = overview;
    final today = o.today;
    final todayStats = periodStats(
      habits: o.habits,
      doneByHabit: o.doneByHabit,
      from: today,
      to: today,
    );
    final from = addDays(today, -6);
    final counts = dailyCounts(o.completions, from, today);
    final days = counts.keys.toList();
    final maxCount = counts.values.fold<int>(0, (a, b) => a > b ? a : b);
    final totalMinutes = o.completions.fold<int>(
      0,
      (s, c) => s + c.durationSeconds ~/ 60,
    );

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      children: [
        Row(
          children: [
            Expanded(
              child: _RateCard(label: 'اليوم', stats: todayStats),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _RateCard(label: 'الأسبوع', stats: o.week),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _RateCard(label: 'الشهر', stats: o.month),
            ),
          ],
        ),
        const SizedBox(height: 20),
        const SectionTitle('آخر 7 أيام'),
        const SizedBox(height: 12),
        AzmCard(
          padding: const EdgeInsets.fromLTRB(12, 20, 16, 12),
          child: SizedBox(
            height: 190,
            child: BarChart(
              BarChartData(
                maxY: (maxCount < 3 ? 3 : maxCount + 1).toDouble(),
                alignment: BarChartAlignment.spaceAround,
                gridData: FlGridData(
                  drawVerticalLine: false,
                  horizontalInterval: 1,
                  getDrawingHorizontalLine: (_) =>
                      FlLine(color: scheme.outlineVariant, strokeWidth: 1),
                ),
                borderData: FlBorderData(show: false),
                barTouchData: BarTouchData(enabled: false),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(),
                  rightTitles: const AxisTitles(),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 26,
                      interval: 1,
                      getTitlesWidget: (v, meta) => Text(
                        v.toInt().toString(),
                        style: TextStyle(
                          fontSize: 11,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      getTitlesWidget: (v, meta) {
                        final i = v.toInt();
                        if (i < 0 || i >= days.length) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            weekdayShort(days[i].weekday),
                            style: TextStyle(
                              fontSize: 10.5,
                              color: scheme.onSurfaceVariant,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                barGroups: [
                  for (var i = 0; i < days.length; i++)
                    BarChartGroupData(
                      x: i,
                      barRods: [
                        BarChartRodData(
                          toY: counts[days[i]]!.toDouble(),
                          width: 18,
                          borderRadius: BorderRadius.circular(6),
                          color: scheme.secondary,
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: StatTile(
                icon: Icons.task_alt_rounded,
                value: '${o.completions.length}',
                label: 'إجمالي الإنجازات',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: StatTile(
                icon: Icons.timer_rounded,
                value: totalMinutes >= 60
                    ? '${(totalMinutes / 60).toStringAsFixed(1)} س'
                    : '$totalMinutes د',
                label: 'إجمالي الوقت',
                color: const Color(0xFF1E88E5),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        const SectionTitle('تقدم كل عادة هذا الشهر'),
        const SizedBox(height: 12),
        for (final h in o.habits)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _HabitRow(overview: o, habitId: h.id),
          ),
      ],
    );
  }
}

class _RateCard extends StatelessWidget {
  const _RateCard({required this.label, required this.stats});

  final String label;
  final PeriodStats stats;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AzmCard(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      child: Column(
        children: [
          ProgressRing(
            progress: stats.rate,
            size: 68,
            strokeWidth: 7,
            child: Text(
              '${stats.percent}%',
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w800)),
          Text(
            '${stats.done}/${stats.scheduled}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _HabitRow extends StatelessWidget {
  const _HabitRow({required this.overview, required this.habitId});

  final Overview overview;
  final String habitId;

  @override
  Widget build(BuildContext context) {
    final h = overview.habits.firstWhere((x) => x.id == habitId);
    final today = overview.today;
    final stats = periodStats(
      habits: [h],
      doneByHabit: overview.doneByHabit,
      from: DateTime(today.year, today.month, 1),
      to: today,
    );
    final color = colorForValue(h.colorValue);
    return AzmCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      child: Column(
        children: [
          Row(
            children: [
              Icon(iconForKey(h.iconKey), color: color, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  h.name,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
              Text(
                h.isPaused ? 'متوقفة' : '${stats.percent}%',
                style: TextStyle(color: color, fontWeight: FontWeight.w800),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: h.isPaused ? 0 : stats.rate,
              minHeight: 8,
              color: color,
              backgroundColor: color.withValues(alpha: 0.15),
            ),
          ),
        ],
      ),
    );
  }
}

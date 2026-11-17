import 'package:material_ui/material_ui.dart';

import '../../core/habit_style.dart';
import '../../domain/habit.dart';
import '../widgets/common.dart';

class HabitTile extends StatelessWidget {
  const HabitTile({
    super.key,
    required this.habit,
    required this.doneToday,
    required this.streak,
    required this.onTap,
    this.trailing,
  });

  final Habit habit;
  final bool doneToday;
  final int streak;
  final VoidCallback onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = colorForValue(habit.colorValue);
    final subtitle = [
      '${habit.durationMinutes} دقيقة',
      if (streak > 0) 'سلسلة $streak',
      if (habit.hasReminder) 'تذكير',
    ].join(' · ');
    return Opacity(
      opacity: habit.isPaused ? 0.55 : 1,
      child: AzmCard(
        onTap: onTap,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(iconForKey(habit.iconKey), color: color),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          habit.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                      ),
                      if (habit.isPaused) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: scheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'متوقفة',
                            style: Theme.of(context).textTheme.labelSmall,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            if (doneToday)
              Icon(Icons.check_circle_rounded, color: scheme.secondary)
            else if (trailing == null)
              Icon(Icons.chevron_left_rounded, color: scheme.onSurfaceVariant),
            ?trailing,
          ],
        ),
      ),
    );
  }
}

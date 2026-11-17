import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../application/providers.dart';
import '../../core/habit_style.dart';
import '../../core/theme.dart';
import '../../domain/gamification.dart';
import '../widgets/common.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  Future<void> _editName(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController(
      text: ref.read(settingsProvider).displayName,
    );
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('اسمك'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 30,
          decoration: const InputDecoration(hintText: 'الاسم الظاهر'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(minimumSize: const Size(80, 44)),
            onPressed: () => Navigator.of(ctx).pop(controller.text),
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (name != null) {
      await ref.read(settingsProvider.notifier).setDisplayName(name);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final settings = ref.watch(settingsProvider);
    final overview = ref.watch(overviewProvider).value;
    final auth = ref.watch(authServiceProvider);
    final name = settings.displayName.isEmpty
        ? 'مستخدم عزم'
        : settings.displayName;
    final earnedIds = overview?.earned.map((b) => b.id).toSet() ?? <String>{};
    final level = overview?.level;

    return Scaffold(
      appBar: AppBar(title: const Text('الملف الشخصي')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          AzmCard(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 38,
                  backgroundColor: scheme.secondary.withValues(alpha: 0.16),
                  child: Text(
                    name.characters.first,
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      color: scheme.secondary,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      name,
                      style: Theme.of(context).textTheme.titleLarge
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    IconButton(
                      tooltip: 'تعديل الاسم',
                      onPressed: () => _editName(context, ref),
                      icon: const Icon(Icons.edit_rounded, size: 20),
                    ),
                  ],
                ),
                Text(
                  auth.isSignedIn
                      ? (auth.currentUser?.email ?? 'حساب سحابي')
                      : 'حساب محلي على هذا الجهاز',
                  style: Theme.of(context).textTheme.bodySmall
                      ?.copyWith(color: scheme.onSurfaceVariant),
                ),
                if (level != null) ...[
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Text(
                        'المستوى ${level.level}',
                        style: const TextStyle(
                          color: AzmColors.gold,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${overview!.totalXp} XP',
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: level.progress.clamp(0.0, 1.0),
                      minHeight: 9,
                      color: AzmColors.gold,
                      backgroundColor: scheme.surfaceContainerHighest,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: Text(
                      'يتبقى ${level.xpForNext - level.xpIntoLevel} XP للمستوى التالي',
                      style: Theme.of(context).textTheme.bodySmall
                          ?.copyWith(color: scheme.onSurfaceVariant),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 22),
          SectionTitle(
            'الشارات',
            trailing: Text(
              '${earnedIds.length} / ${allBadges.length}',
              style: TextStyle(
                color: scheme.secondary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(height: 12),
          for (final b in allBadges)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _BadgeTile(badge: b, earned: earnedIds.contains(b.id)),
            ),
        ],
      ),
    );
  }
}

class _BadgeTile extends StatelessWidget {
  const _BadgeTile({required this.badge, required this.earned});

  final BadgeDef badge;
  final bool earned;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = earned ? AzmColors.gold : scheme.onSurfaceVariant;
    return Opacity(
      opacity: earned ? 1 : 0.6,
      child: AzmCard(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(badgeIcon(badge.iconKey), color: color),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    badge.title,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  Text(
                    badge.description,
                    style: Theme.of(context).textTheme.bodySmall
                        ?.copyWith(color: scheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            Icon(
              earned ? Icons.check_circle_rounded : Icons.lock_outline_rounded,
              color: earned ? scheme.secondary : scheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}

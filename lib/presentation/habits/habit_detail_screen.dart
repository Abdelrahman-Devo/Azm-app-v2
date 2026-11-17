import 'dart:io';
import 'dart:ui' show FontFeature;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

import '../../application/completion_service.dart';
import '../../application/providers.dart';
import '../../core/date_utils.dart';
import '../../core/habit_style.dart';
import '../../domain/habit.dart';
import '../../domain/timer_session.dart';
import '../widgets/common.dart';
import '../widgets/second_ticker.dart';
import 'habit_editor_screen.dart';

class HabitDetailScreen extends ConsumerWidget {
  const HabitDetailScreen({super.key, required this.habitId});

  final String habitId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final habits = ref.watch(habitsProvider).value ?? const <Habit>[];
    final habit = habits.where((h) => h.id == habitId).firstOrNull;
    if (habit == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const EmptyState(
          icon: Icons.search_off_rounded,
          title: 'العادة غير موجودة',
          message: 'ربما تم حذفها.',
        ),
      );
    }
    return _DetailBody(habit: habit);
  }
}

class _DetailBody extends ConsumerStatefulWidget {
  const _DetailBody({required this.habit});

  final Habit habit;

  @override
  ConsumerState<_DetailBody> createState() => _DetailBodyState();
}

class _DetailBodyState extends ConsumerState<_DetailBody> {
  bool _busy = false;

  Habit get habit => widget.habit;

  Future<void> _guard(Future<void> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
    } catch (e) {
      if (mounted) showAzmSnack(context, 'حدث خطأ: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _start() => _guard(() async {
    final result = await ref.read(timerProvider.notifier).start(habit);
    if (!mounted) return;
    if (result == StartResult.otherActive) {
      showAzmSnack(context, 'لديك جلسة أخرى نشطة. أنهِها أو أعد ضبطها أولًا');
      return;
    }
    // Ask for notification permission in context, so the end-of-timer alert
    // can reach the user when the app is closed.
    final service = ref.read(notificationServiceProvider);
    if (!await service.areEnabled()) {
      await service.requestPermission();
      final session = ref.read(timerProvider).value;
      if (session != null && session.isRunning) {
        final nowMs = ref.read(clockProvider)().millisecondsSinceEpoch;
        await service.scheduleTimerEnd(
          habitName: habit.name,
          remainingSeconds: session.remainingSeconds(nowMs),
        );
      }
    }
  });

  Future<void> _reset() async {
    final ok = await showAzmConfirm(
      context,
      title: 'إعادة ضبط المؤقت؟',
      message: 'سيُلغى التقدم الحالي في هذه الجلسة ولن يُسجل إنجاز.',
      confirmLabel: 'إعادة الضبط',
      destructive: true,
      icon: Icons.restart_alt_rounded,
    );
    if (!ok) return;
    await _guard(() => ref.read(timerProvider.notifier).reset());
  }

  Future<void> _complete() => _guard(() async {
    final result = await ref.read(completionServiceProvider).complete(habit);
    if (!mounted) return;
    switch (result) {
      case CompleteSuccess():
        final parts = <String>[
          'حصلت على ${result.completion.xp} نقطة XP.',
          if (result.streak > 1) 'سلسلتك الآن ${result.streak} أيام.',
          if (result.leveledUpTo != null)
            'ارتقيت إلى المستوى ${result.leveledUpTo}!',
          if (result.newBadgeTitles.isNotEmpty)
            'شارة جديدة: ${result.newBadgeTitles.join('، ')}.',
        ];
        await showAzmMessage(
          context,
          title: 'أحسنت! أنجزت ${habit.name}',
          message: parts.join('\n'),
        );
      case CompleteTooEarly():
        showAzmSnack(
          context,
          'لم تنتهِ المدة بعد، تبقّى ${formatClock(result.remainingSeconds)}',
        );
      case CompleteNeedsProof():
        showAzmSnack(context, 'هذه العادة تتطلب صورة إثبات قبل الإكمال');
      case CompleteAlreadyDone():
        showAzmSnack(context, 'سُجلت هذه العادة لهذا اليوم من قبل');
      case CompleteNoSession():
        showAzmSnack(context, 'ابدأ المؤقت أولًا');
    }
  });

  Future<void> _addProof() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_rounded),
              title: const Text('التقاط صورة'),
              onTap: () => Navigator.of(ctx).pop(ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_rounded),
              title: const Text('اختيار من المعرض'),
              onTap: () => Navigator.of(ctx).pop(ImageSource.gallery),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (source == null) return;
    await _guard(() async {
      final picked = await ImagePicker().pickImage(
        source: source,
        maxWidth: 1600,
        imageQuality: 85,
      );
      if (picked == null) return;
      // Only treat the proof as attached once the copy is verified on disk.
      final savedPath = await ref
          .read(proofStorageProvider)
          .save(File(picked.path));
      await ref.read(timerProvider.notifier).setProof(savedPath);
      if (mounted) showAzmSnack(context, 'تم حفظ الصورة');
    });
  }

  Future<void> _delete() async {
    final ok = await showAzmConfirm(
      context,
      title: 'حذف العادة؟',
      message: 'ستُحذف العادة وسجل إنجازاتها نهائيًا من هذا الجهاز.',
      confirmLabel: 'حذف',
      destructive: true,
      icon: Icons.delete_outline_rounded,
    );
    if (!ok || !mounted) return;
    await ref.read(habitsProvider.notifier).delete(habit.id);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = colorForValue(habit.colorValue);
    final overview = ref.watch(overviewProvider).value;
    final session = ref.watch(timerProvider).value;
    final mine = session != null && session.habitId == habit.id
        ? session
        : null;
    final otherActive = session != null && mine == null;
    final doneToday = overview?.doneToday.contains(habit.id) ?? false;
    final streak = overview?.streaks[habit.id];
    final completions = (overview?.completions ?? const [])
        .where((c) => c.habitId == habit.id)
        .toList();
    final doneKeys = overview?.doneByHabit[habit.id] ?? const <String>{};

    return Scaffold(
      appBar: AppBar(
        title: Text(habit.name),
        actions: [
          PopupMenuButton<String>(
            onSelected: (v) async {
              switch (v) {
                case 'edit':
                  await Navigator.of(
                    context,
                  ).push(azmRoute(HabitEditorScreen(existing: habit)));
                case 'pause':
                  await ref
                      .read(habitsProvider.notifier)
                      .setPaused(habit, !habit.isPaused);
                case 'delete':
                  await _delete();
              }
            },
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'edit', child: Text('تعديل')),
              PopupMenuItem(
                value: 'pause',
                child: Text(habit.isPaused ? 'استئناف العادة' : 'إيقاف مؤقت'),
              ),
              const PopupMenuItem(value: 'delete', child: Text('حذف')),
            ],
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(iconForKey(habit.iconKey), color: color, size: 30),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (habit.description.isNotEmpty)
                      Text(
                        habit.description,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                          height: 1.5,
                        ),
                      ),
                    Text(
                      '${habit.durationMinutes} دقيقة · ${habit.weekdays.length == 7 ? 'كل يوم' : habit.weekdays.map(weekdayName).join('، ')}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          _TimerCard(
            habit: habit,
            session: mine,
            doneToday: doneToday,
            paused: habit.isPaused,
            otherActive: otherActive,
            busy: _busy,
            onStart: _start,
            onPause: () => _guard(() => ref.read(timerProvider.notifier).pause()),
            onResume: () => _guard(
              () => ref.read(timerProvider.notifier).resume(habit.name),
            ),
            onReset: _reset,
            onComplete: _complete,
          ),
          if (mine != null) ...[
            const SizedBox(height: 12),
            _ProofCard(
              required: habit.requireProof,
              proofPath: mine.proofPath,
              busy: _busy,
              onAdd: _addProof,
              onRemove: () =>
                  _guard(() => ref.read(timerProvider.notifier).setProof(null)),
            ),
          ],
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: StatTile(
                  icon: Icons.local_fire_department_rounded,
                  value: '${streak?.current ?? 0}',
                  label: 'السلسلة الحالية',
                  color: const Color(0xFFE2674A),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: StatTile(
                  icon: Icons.emoji_events_rounded,
                  value: '${streak?.best ?? 0}',
                  label: 'أفضل سلسلة',
                  color: const Color(0xFFF4A024),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: StatTile(
                  icon: Icons.check_circle_rounded,
                  value: '${doneKeys.length}',
                  label: 'مرات الإنجاز',
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          const SectionTitle('سجل الإنجازات'),
          const SizedBox(height: 10),
          if (completions.isEmpty)
            AzmCard(
              child: Text(
                'لم تُسجل أي إنجازات لهذه العادة بعد.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            )
          else
            for (final c in completions.take(30))
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: AzmCard(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle_rounded, color: scheme.secondary),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          DateFormat(
                            'EEEE d MMMM',
                            'ar',
                          ).format(parseDateKey(c.dateKey)),
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                      if (c.proofPath != null &&
                          File(c.proofPath!).existsSync())
                        GestureDetector(
                          onTap: () => _showProof(c.proofPath!),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.file(
                              File(c.proofPath!),
                              width: 36,
                              height: 36,
                              fit: BoxFit.cover,
                              cacheWidth: 120,
                            ),
                          ),
                        ),
                      const SizedBox(width: 10),
                      Text(
                        '+${c.xp} XP',
                        style: TextStyle(
                          color: scheme.secondary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
        ],
      ),
    );
  }

  void _showProof(String path) {
    showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        clipBehavior: Clip.antiAlias,
        child: InteractiveViewer(child: Image.file(File(path))),
      ),
    );
  }
}

class _TimerCard extends ConsumerWidget {
  const _TimerCard({
    required this.habit,
    required this.session,
    required this.doneToday,
    required this.paused,
    required this.otherActive,
    required this.busy,
    required this.onStart,
    required this.onPause,
    required this.onResume,
    required this.onReset,
    required this.onComplete,
  });

  final Habit habit;
  final TimerSession? session;
  final bool doneToday;
  final bool paused;
  final bool otherActive;
  final bool busy;
  final VoidCallback onStart;
  final VoidCallback onPause;
  final VoidCallback onResume;
  final VoidCallback onReset;
  final VoidCallback onComplete;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final color = colorForValue(habit.colorValue);
    final s = session;

    if (doneToday && s == null) {
      return AzmCard(
        child: Row(
          children: [
            Icon(Icons.verified_rounded, color: scheme.secondary, size: 36),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                'أنجزت هذه العادة اليوم. أحسنت!',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return AzmCard(
      child: SecondTicker(
        builder: (context) {
          final nowMs = ref.read(clockProvider)().millisecondsSinceEpoch;
          final seconds = s == null
              ? habit.targetSeconds
              : s.remainingSeconds(nowMs);
          final finished = s != null && s.isComplete(nowMs);
          final progress = s?.progress(nowMs) ?? 0.0;
          return Column(
            children: [
              ProgressRing(
                progress: progress,
                size: 190,
                strokeWidth: 12,
                color: color,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      formatClock(seconds),
                      style: Theme.of(context).textTheme.displaySmall
                          ?.copyWith(
                            fontWeight: FontWeight.w800,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                    ),
                    Text(
                      s == null
                          ? 'جاهز للبدء'
                          : finished
                          ? 'انتهت المدة'
                          : (s.isRunning ? 'قيد التنفيذ' : 'متوقف مؤقتًا'),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              if (s == null)
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: (busy || paused || otherActive) ? null : onStart,
                    icon: const Icon(Icons.play_arrow_rounded),
                    label: Text(
                      paused
                          ? 'العادة متوقفة مؤقتًا'
                          : otherActive
                          ? 'جلسة أخرى نشطة'
                          : 'ابدأ',
                    ),
                  ),
                )
              else ...[
                if (!finished)
                  SizedBox(
                    width: double.infinity,
                    child: s.isRunning
                        ? OutlinedButton.icon(
                            onPressed: busy ? null : onPause,
                            icon: const Icon(Icons.pause_rounded),
                            label: const Text('إيقاف مؤقت'),
                          )
                        : FilledButton.icon(
                            onPressed: busy ? null : onResume,
                            icon: const Icon(Icons.play_arrow_rounded),
                            label: const Text('استئناف'),
                          ),
                  ),
                if (!finished) const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: busy ? null : onReset,
                        icon: const Icon(Icons.restart_alt_rounded),
                        label: const Text('إعادة'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 2,
                      child: FilledButton.icon(
                        // Enabled only once the full duration has elapsed.
                        onPressed: (busy || !finished) ? null : onComplete,
                        icon: const Icon(Icons.check_rounded),
                        label: const Text('إكمال'),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _ProofCard extends StatelessWidget {
  const _ProofCard({
    required this.required,
    required this.proofPath,
    required this.busy,
    required this.onAdd,
    required this.onRemove,
  });

  final bool required;
  final String? proofPath;
  final bool busy;
  final VoidCallback onAdd;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final path = proofPath;
    final hasFile = path != null && File(path).existsSync();
    return AzmCard(
      child: Row(
        children: [
          if (hasFile)
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.file(
                File(path),
                width: 56,
                height: 56,
                fit: BoxFit.cover,
                cacheWidth: 200,
              ),
            )
          else
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.photo_camera_rounded,
                color: scheme.onSurfaceVariant,
              ),
            ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  required ? 'صورة الإثبات (مطلوبة)' : 'صورة الإثبات (اختيارية)',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                Text(
                  hasFile ? 'تم حفظ الصورة' : 'لم تُرفق صورة بعد',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          if (hasFile)
            IconButton(
              tooltip: 'إزالة',
              onPressed: busy ? null : onRemove,
              icon: const Icon(Icons.delete_outline_rounded),
            )
          else
            FilledButton.tonal(
              onPressed: busy ? null : onAdd,
              style: FilledButton.styleFrom(minimumSize: const Size(64, 44)),
              child: const Text('إرفاق'),
            ),
        ],
      ),
    );
  }
}

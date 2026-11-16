import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../models/habit.dart';
import '../../state/app_state.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});
  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  Timer? ticker;
  DateTime? sessionStarted;
  int pausedSeconds = 0;
  String? sessionHabitId;
  int elapsed = 0;

  @override
  void initState() {
    super.initState();
    _restoreSession();
  }

  void _restoreSession() {
    final s = ref.read(habitRepositoryProvider).activeSession;
    if (s == null) return;
    sessionHabitId = s['habitId'] as String?;
    pausedSeconds = (s['elapsedSeconds'] as num?)?.toInt() ?? 0;
    final started = s['startedAt'] as String?;
    if (started != null) {
      sessionStarted = DateTime.tryParse(started);
      if (sessionStarted != null) _startTicker();
    }
    elapsed = pausedSeconds;
  }

  int get currentElapsed => pausedSeconds + (sessionStarted == null ? 0 : DateTime.now().difference(sessionStarted!).inSeconds);
  void _startTicker() {
    ticker?.cancel();
    ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => elapsed = currentElapsed);
    });
  }

  Future<void> _persistSession() async {
    await ref.read(habitRepositoryProvider).saveSession(sessionHabitId == null ? null : {
      'habitId': sessionHabitId,
      'elapsedSeconds': pausedSeconds,
      'startedAt': sessionStarted?.toIso8601String(),
    });
  }

  void _start(Habit habit) {
    if (sessionHabitId != null && sessionHabitId != habit.id) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('أنه الجلسة الحالية أولًا')));
      return;
    }
    setState(() {
      sessionHabitId = habit.id;
      sessionStarted ??= DateTime.now();
    });
    _persistSession();
    _startTicker();
  }

  Future<void> _pause() async {
    if (sessionStarted == null) return;
    setState(() {
      pausedSeconds = currentElapsed;
      sessionStarted = null;
      elapsed = pausedSeconds;
    });
    ticker?.cancel();
    await _persistSession();
  }

  Future<void> _finish(Habit habit) async {
    final required = habit.durationMinutes * 60;
    if (currentElapsed < required) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('متبقي ${_clock(required-currentElapsed)} لإكمال العادة')));
      return;
    }
    await ref.read(habitsProvider.notifier).complete(habit.id);
    await ref.read(habitRepositoryProvider).saveSession(null);
    ticker?.cancel();
    setState(() { sessionHabitId = null; sessionStarted = null; pausedSeconds = 0; elapsed = 0; });
    if (mounted) showDialog(context: context, builder: (_) => AlertDialog(
      title: const Text('أحسنت! إنجاز جديد 🎉'),
      content: Text('أكملت ${habit.name}. استمر في بناء عزمك.'),
      actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('رائع'))],
    ));
  }

  String _clock(int seconds) {
    final h = seconds ~/ 3600, m = (seconds % 3600) ~/ 60, s = seconds % 60;
    return h > 0 ? '${h.toString().padLeft(2,'0')}:${m.toString().padLeft(2,'0')}:${s.toString().padLeft(2,'0')}' : '${m.toString().padLeft(2,'0')}:${s.toString().padLeft(2,'0')}';
  }

  @override
  void dispose() { ticker?.cancel(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final habits = ref.watch(habitsProvider).where((h) => !h.isPaused).toList();
    final done = ref.watch(completedProvider);
    final completed = ref.read(habitRepositoryProvider).completedToday;
    final count = habits.where((h) => completed.contains(h.id)).length;
    final progress = habits.isEmpty ? 0.0 : count / habits.length;
    final dark = ref.watch(themeModeProvider);
    final date = DateFormat('EEEE، d MMMM', 'ar').format(DateTime.now());
    return Scaffold(
      appBar: AppBar(
        title: const Row(children: [Text('عزم', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 26)), SizedBox(width: 8), Text('AZM', style: TextStyle(letterSpacing: 2, fontWeight: FontWeight.w700, fontSize: 12))]),
        actions: [IconButton(tooltip: 'تغيير المظهر', onPressed: () => ref.read(themeModeProvider.notifier).state = !dark, icon: Icon(dark ? Icons.light_mode_rounded : Icons.dark_mode_rounded)), const SizedBox(width: 8)],
      ),
      floatingActionButton: FloatingActionButton.extended(onPressed: _addHabit, icon: const Icon(Icons.add), label: const Text('عادة جديدة')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 100),
        children: [
          Text('مرحبًا بك 👋', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text(date, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
          const SizedBox(height: 18),
          _progressCard(progress, count, habits.length),
          const SizedBox(height: 22),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('عادات اليوم', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
            Text('$count / ${habits.length} مكتملة', style: TextStyle(color: Theme.of(context).colorScheme.secondary, fontWeight: FontWeight.w700)),
          ]),
          const SizedBox(height: 12),
          if (habits.isEmpty) const Center(child: Padding(padding: EdgeInsets.all(28), child: Text('لا توجد عادات بعد. أضف عادتك الأولى!'))),
          ...habits.map((h) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _habitCard(h, completed.contains(h.id)),
          )),
          const SizedBox(height: 10),
          _quoteCard(),
        ],
      ),
    );
  }

  Widget _progressCard(double progress, int count, int total) {
    return Card(child: Padding(
      padding: const EdgeInsets.all(20),
      child: Row(children: [
        SizedBox(width: 88, height: 88, child: Stack(alignment: Alignment.center, children: [
          SizedBox.expand(child: CircularProgressIndicator(value: progress, strokeWidth: 8, backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(.10), strokeCap: StrokeCap.round)),
          Text('${(progress*100).round()}%', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 20)),
        ])),
        const SizedBox(width: 18),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('إنجازك اليوم', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
          const SizedBox(height: 5),
          Text(total == 0 ? 'ابدأ بإضافة عاداتك اليومية' : 'أكملت $count من $total عادات. خطوة صغيرة تصنع فرقًا.'),
        ])),
      ]),
    ));
  }

  Widget _habitCard(Habit habit, bool isDone) {
    final isActive = sessionHabitId == habit.id;
    final remaining = (habit.durationMinutes * 60 - currentElapsed).clamp(0, habit.durationMinutes * 60);
    return Card(child: Padding(
      padding: const EdgeInsets.all(15),
      child: Column(children: [
        Row(children: [
          Container(width: 44, height: 44, decoration: BoxDecoration(color: Theme.of(context).colorScheme.secondary.withOpacity(.12), borderRadius: BorderRadius.circular(14)), child: Icon(_iconFor(habit.name), color: Theme.of(context).colorScheme.secondary)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(habit.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
            if (habit.note.isNotEmpty) Text(habit.note, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 12)),
            Text('${habit.durationMinutes} دقيقة · ${habit.completions} إنجاز', style: TextStyle(color: Theme.of(context).colorScheme.secondary, fontSize: 11, fontWeight: FontWeight.w600)),
          ])),
          PopupMenuButton<String>(
            onSelected: (v) async {
              if (v == 'edit') _addHabit(existing: habit);
              if (v == 'pause') await ref.read(habitsProvider.notifier).update(habit.copyWith(isPaused: true));
              if (v == 'delete') await ref.read(habitsProvider.notifier).delete(habit.id);
            },
            itemBuilder: (_) => const [PopupMenuItem(value: 'edit', child: Text('تعديل')), PopupMenuItem(value: 'pause', child: Text('إيقاف مؤقت')), PopupMenuItem(value: 'delete', child: Text('حذف'))],
          ),
          if (isDone) const Icon(Icons.check_circle_rounded, color: Color(0xFF35A879)),
        ]),
        if (isActive && !isDone) ...[
          const SizedBox(height: 14),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('الوقت المتبقي ${_clock(remaining)}', style: const TextStyle(fontWeight: FontWeight.w700)), Text('من ${habit.durationMinutes}:00', style: const TextStyle(fontSize: 11))]),
          const SizedBox(height: 8),
          LinearProgressIndicator(value: (currentElapsed / (habit.durationMinutes * 60)).clamp(0, 1), minHeight: 6, borderRadius: BorderRadius.circular(8)),
        ],
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: OutlinedButton.icon(
            onPressed: isDone ? null : () => isActive && sessionStarted != null ? _pause() : _start(habit),
            icon: Icon(isActive && sessionStarted != null ? Icons.pause_rounded : Icons.play_arrow_rounded),
            label: Text(isActive && sessionStarted != null ? 'إيقاف مؤقت' : isActive ? 'استكمال' : 'ابدأ'),
          )),
          const SizedBox(width: 8),
          Expanded(child: FilledButton(
            onPressed: isDone ? null : () => _finish(habit),
            child: Text(isDone ? 'مكتملة' : 'إنهاء العادة'),
          )),
        ]),
      ]),
    ));
  }

  IconData _iconFor(String name) {
    if (name.contains('قرآن') || name.contains('صلاة')) return Icons.auto_stories_rounded;
    if (name.contains('رياض')) return Icons.fitness_center_rounded;
    if (name.contains('مياه')) return Icons.water_drop_rounded;
    if (name.contains('دراسة')) return Icons.school_rounded;
    return Icons.flag_rounded;
  }

  Widget _quoteCard() => Card(color: Theme.of(context).colorScheme.primary, child: const Padding(
    padding: EdgeInsets.all(18),
    child: Row(children: [Icon(Icons.bolt_rounded, color: Colors.white, size: 28), SizedBox(width: 12), Expanded(child: Text('الانضباط هو أن تفعل ما يجب عليك فعله، حتى عندما لا ترغب في ذلك.', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, height: 1.5)))]),
  ));

  Future<void> _addHabit({Habit? existing}) async {
    final name = TextEditingController(text: existing?.name ?? '');
    final note = TextEditingController(text: existing?.note ?? '');
    final minutes = TextEditingController(text: '${existing?.durationMinutes ?? 15}');
    final result = await showModalBottomSheet<bool>(
      context: context, isScrollControlled: true, showDragHandle: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(20, 8, 20, MediaQuery.of(ctx).viewInsets.bottom + 24),
        child: StatefulBuilder(builder: (ctx, setLocal) => SingleChildScrollView(child: Column(
          mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(existing == null ? 'إنشاء عادة جديدة' : 'تعديل العادة', style: Theme.of(ctx).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 16),
            TextField(controller: name, decoration: const InputDecoration(labelText: 'اسم العادة', hintText: 'مثال: القراءة اليومية')),
            const SizedBox(height: 10),
            TextField(controller: note, decoration: const InputDecoration(labelText: 'وصف مختصر')),
            const SizedBox(height: 10),
            TextField(controller: minutes, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'المدة بالدقائق')),
            const SizedBox(height: 18),
            FilledButton(onPressed: () {
              final n = name.text.trim();
              final m = int.tryParse(minutes.text.trim()) ?? 15;
              if (n.isEmpty || m < 1 || m > 1440) {
                ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('أدخل اسمًا ومدة صحيحة من 1 إلى 1440 دقيقة')));
                return;
              }
              final repo = ref.read(habitRepositoryProvider);
              final habit = existing == null
                ? Habit(id: repo.newId(), name: n, note: note.text.trim(), durationMinutes: m)
                : existing.copyWith(name: n, note: note.text.trim(), durationMinutes: m);
              if (existing == null) { ref.read(habitsProvider.notifier).add(habit); }
              else { ref.read(habitsProvider.notifier).update(habit); }
              Navigator.pop(ctx, true);
            }, child: const Text('حفظ العادة')),
          ],
        ))),
      ),
    );
    name.dispose(); note.dispose(); minutes.dispose();
    if (result == true && mounted) setState(() {});
  }
}

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:uuid/uuid.dart';

import '../../application/providers.dart';
import '../../core/date_utils.dart';
import '../../core/habit_style.dart';
import '../../domain/habit.dart';
import '../widgets/common.dart';

class HabitEditorScreen extends ConsumerStatefulWidget {
  const HabitEditorScreen({super.key, this.existing});

  final Habit? existing;

  @override
  ConsumerState<HabitEditorScreen> createState() => _HabitEditorScreenState();
}

class _HabitEditorScreenState extends ConsumerState<HabitEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _description;
  late String _iconKey;
  late int _color;
  late int _minutes;
  late Set<int> _weekdays;
  int? _reminder;
  late bool _requireProof;
  bool _saving = false;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final h = widget.existing;
    _name = TextEditingController(text: h?.name ?? '');
    _description = TextEditingController(text: h?.description ?? '');
    _iconKey = h?.iconKey ?? 'flag';
    _color = h?.colorValue ?? habitColors.first;
    _minutes = h?.durationMinutes ?? 15;
    _weekdays = {...(h?.weekdays ?? allWeekdays)};
    _reminder = h?.reminderMinutes;
    _requireProof = h?.requireProof ?? false;
  }

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _pickReminder() async {
    final initial = _reminder ?? 8 * 60;
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: initial ~/ 60, minute: initial % 60),
      helpText: 'وقت التذكير',
      cancelText: 'إلغاء',
      confirmText: 'تأكيد',
    );
    if (picked == null) return;
    // A reminder needs notification permission; ask in response to the tap.
    final service = ref.read(notificationServiceProvider);
    if (!await service.areEnabled()) {
      final granted = await service.requestPermission();
      if (!granted && mounted) {
        showAzmSnack(
          context,
          'لم يُمنح إذن الإشعارات، لن تصلك التذكيرات حتى تفعّله من إعدادات الهاتف',
        );
      }
    }
    setState(() => _reminder = picked.hour * 60 + picked.minute);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_weekdays.isEmpty) {
      showAzmSnack(context, 'اختر يومًا واحدًا على الأقل');
      return;
    }
    setState(() => _saving = true);
    final now = ref.read(clockProvider)();
    final days = _weekdays.toList()..sort();
    try {
      final existing = widget.existing;
      final habit = existing == null
          ? Habit(
              id: const Uuid().v4(),
              name: _name.text.trim(),
              description: _description.text.trim(),
              iconKey: _iconKey,
              colorValue: _color,
              durationMinutes: _minutes,
              weekdays: days,
              reminderMinutes: _reminder,
              requireProof: _requireProof,
              createdAt: now,
              updatedAt: now,
            )
          : existing.copyWith(
              name: _name.text.trim(),
              description: _description.text.trim(),
              iconKey: _iconKey,
              colorValue: _color,
              durationMinutes: _minutes,
              weekdays: days,
              reminderMinutes: _reminder,
              clearReminder: _reminder == null,
              requireProof: _requireProof,
            );
      await ref.read(habitsProvider.notifier).save(habit);
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      showAzmSnack(context, 'تعذر حفظ العادة: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: Text(_isEdit ? 'تعديل العادة' : 'عادة جديدة')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            TextFormField(
              controller: _name,
              textInputAction: TextInputAction.next,
              maxLength: 40,
              decoration: const InputDecoration(
                labelText: 'اسم العادة',
                hintText: 'مثال: القراءة اليومية',
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'أدخل اسم العادة' : null,
            ),
            const SizedBox(height: 4),
            TextFormField(
              controller: _description,
              maxLength: 120,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'وصف مختصر (اختياري)',
              ),
            ),
            const SizedBox(height: 16),
            const SectionTitle('الأيقونة'),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (final entry in habitIcons.entries)
                  _Choice(
                    selected: _iconKey == entry.key,
                    color: colorForValue(_color),
                    onTap: () => setState(() => _iconKey = entry.key),
                    child: Icon(entry.value, size: 22),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            const SectionTitle('اللون'),
            const SizedBox(height: 10),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                for (final c in habitColors)
                  GestureDetector(
                    onTap: () => setState(() => _color = c),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Color(c),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: _color == c
                              ? scheme.onSurface
                              : Colors.transparent,
                          width: 3,
                        ),
                      ),
                      child: _color == c
                          ? const Icon(
                              Icons.check_rounded,
                              color: Colors.white,
                              size: 20,
                            )
                          : null,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 22),
            SectionTitle(
              'مدة العادة',
              trailing: Text(
                '$_minutes دقيقة',
                style: TextStyle(
                  color: scheme.secondary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            Slider(
              value: _minutes.toDouble().clamp(1, 180),
              min: 1,
              max: 180,
              divisions: 179,
              label: '$_minutes',
              onChanged: (v) => setState(() => _minutes = v.round()),
            ),
            Wrap(
              spacing: 8,
              children: [
                for (final m in const [5, 10, 15, 30, 45, 60])
                  ChoiceChip(
                    label: Text('$m د'),
                    selected: _minutes == m,
                    onSelected: (_) => setState(() => _minutes = m),
                  ),
              ],
            ),
            const SizedBox(height: 22),
            const SectionTitle('الأيام المستهدفة'),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                // Week order for Arabic users: Saturday first.
                for (final d in const [6, 7, 1, 2, 3, 4, 5])
                  FilterChip(
                    label: Text(weekdayName(d)),
                    selected: _weekdays.contains(d),
                    showCheckmark: false,
                    onSelected: (on) => setState(() {
                      on ? _weekdays.add(d) : _weekdays.remove(d);
                    }),
                  ),
              ],
            ),
            const SizedBox(height: 22),
            AzmCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.alarm_rounded),
                    title: const Text('وقت التذكير'),
                    subtitle: Text(
                      _reminder == null
                          ? 'بدون تذكير'
                          : formatMinutesOfDay(_reminder!),
                    ),
                    trailing: _reminder == null
                        ? const Icon(Icons.chevron_left_rounded)
                        : IconButton(
                            tooltip: 'إزالة التذكير',
                            icon: const Icon(Icons.close_rounded),
                            onPressed: () => setState(() => _reminder = null),
                          ),
                    onTap: _pickReminder,
                  ),
                  const Divider(),
                  SwitchListTile(
                    secondary: const Icon(Icons.photo_camera_rounded),
                    title: const Text('إثبات بالصورة'),
                    subtitle: const Text(
                      'اطلب صورة لإكمال العادة (الكاميرا أو المعرض)',
                    ),
                    value: _requireProof,
                    onChanged: (v) => setState(() => _requireProof = v),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: Text(_isEdit ? 'حفظ التعديلات' : 'إضافة العادة'),
            ),
          ],
        ),
      ),
    );
  }
}

class _Choice extends StatelessWidget {
  const _Choice({
    required this.selected,
    required this.color,
    required this.onTap,
    required this.child,
  });

  final bool selected;
  final Color color;
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: selected
              ? color.withValues(alpha: 0.18)
              : scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? color : Colors.transparent,
            width: 2,
          ),
        ),
        child: IconTheme(
          data: IconThemeData(
            color: selected ? color : scheme.onSurfaceVariant,
          ),
          child: child,
        ),
      ),
    );
  }
}

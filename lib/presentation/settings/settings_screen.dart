import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../application/providers.dart';
import '../auth/auth_screen.dart';
import '../profile/profile_screen.dart';
import '../widgets/common.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  Future<void> _resetAll(BuildContext context, WidgetRef ref) async {
    final ok = await showAzmConfirm(
      context,
      title: 'حذف كل البيانات؟',
      message: 'ستُحذف جميع العادات والإنجازات والمؤقت من هذا الجهاز نهائيًا. لا يمكن التراجع.',
      confirmLabel: 'حذف الكل',
      destructive: true,
      icon: Icons.delete_forever_rounded,
    );
    if (!ok || !context.mounted) return;
    try {
      await ref.read(notificationServiceProvider).cancelAll();
      await ref.read(habitRepositoryProvider).wipeAll();
      ref.invalidate(habitsProvider);
      ref.invalidate(completionsProvider);
      ref.invalidate(timerProvider);
      if (context.mounted) showAzmSnack(context, 'تم حذف البيانات');
    } catch (e) {
      if (context.mounted) showAzmSnack(context, 'تعذر الحذف: $e');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final settings = ref.watch(settingsProvider);
    final auth = ref.watch(authServiceProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('الإعدادات')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          AzmCard(
            padding: EdgeInsets.zero,
            child: ListTile(
              leading: const Icon(Icons.person_rounded),
              title: const Text('الملف الشخصي'),
              subtitle: const Text('المستوى والشارات والاسم'),
              trailing: const Icon(Icons.chevron_left_rounded),
              onTap: () =>
                  Navigator.of(context).push(azmRoute(const ProfileScreen())),
            ),
          ),
          const SizedBox(height: 18),
          const SectionTitle('المظهر'),
          const SizedBox(height: 10),
          AzmCard(
            child: SegmentedButton<String>(
              showSelectedIcon: false,
              segments: const [
                ButtonSegment(
                  value: 'system',
                  icon: Icon(Icons.brightness_auto_rounded),
                  label: Text('تلقائي'),
                ),
                ButtonSegment(
                  value: 'light',
                  icon: Icon(Icons.light_mode_rounded),
                  label: Text('فاتح'),
                ),
                ButtonSegment(
                  value: 'dark',
                  icon: Icon(Icons.dark_mode_rounded),
                  label: Text('داكن'),
                ),
              ],
              selected: {settings.themeMode},
              onSelectionChanged: (s) =>
                  ref.read(settingsProvider.notifier).setThemeMode(s.first),
            ),
          ),
          const SizedBox(height: 18),
          const SectionTitle('الإشعارات'),
          const SizedBox(height: 10),
          AzmCard(
            padding: EdgeInsets.zero,
            child: ListTile(
              leading: const Icon(Icons.notifications_active_rounded),
              title: const Text('السماح بالإشعارات'),
              subtitle: const Text(
                'لتصلك تذكيرات العادات وتنبيه انتهاء المؤقت',
              ),
              onTap: () async {
                final granted = await ref
                    .read(notificationServiceProvider)
                    .requestPermission();
                if (!context.mounted) return;
                showAzmSnack(
                  context,
                  granted
                      ? 'الإشعارات مفعّلة'
                      : 'الإشعارات غير مفعّلة. فعّلها من إعدادات الهاتف',
                );
              },
            ),
          ),
          const SizedBox(height: 18),
          const SectionTitle('الحساب'),
          const SizedBox(height: 10),
          AzmCard(
            padding: EdgeInsets.zero,
            child: auth.isSignedIn
                ? ListTile(
                    leading: const Icon(Icons.logout_rounded),
                    title: const Text('تسجيل الخروج'),
                    subtitle: Text(auth.currentUser?.email ?? ''),
                    onTap: () async {
                      await auth.signOut();
                      if (context.mounted) {
                        showAzmSnack(context, 'تم تسجيل الخروج');
                        ref.invalidate(authServiceProvider);
                      }
                    },
                  )
                : ListTile(
                    leading: const Icon(Icons.login_rounded),
                    title: const Text('تسجيل الدخول / إنشاء حساب'),
                    subtitle: Text(
                      auth.configured
                          ? 'لمزامنة بياناتك سحابيًا'
                          : 'الخدمة السحابية غير مفعّلة في هذا الإصدار',
                    ),
                    onTap: () => Navigator.of(context)
                        .push(azmRoute(const AuthScreen(fromSettings: true))),
                  ),
          ),
          const SizedBox(height: 18),
          const SectionTitle('البيانات'),
          const SizedBox(height: 10),
          AzmCard(
            padding: EdgeInsets.zero,
            child: ListTile(
              leading: Icon(Icons.delete_forever_rounded, color: scheme.error),
              title: Text(
                'حذف كل البيانات المحلية',
                style: TextStyle(color: scheme.error),
              ),
              onTap: () => _resetAll(context, ref),
            ),
          ),
          const SizedBox(height: 24),
          Center(
            child: Text(
              'Azm - عزم · الإصدار 1.0.0',
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ),
        ],
      ),
    );
  }
}

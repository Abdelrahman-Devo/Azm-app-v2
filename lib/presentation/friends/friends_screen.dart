import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../application/providers.dart';
import '../auth/auth_screen.dart';
import '../widgets/common.dart';

/// Friends & challenges need a shared backend, so this screen is honest about
/// its state: the social features are not implemented in this build. The
/// database schema for them is prepared in `supabase/schema.sql`.
class FriendsScreen extends ConsumerWidget {
  const FriendsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authServiceProvider);
    final String message;
    Widget? action;
    if (!auth.configured) {
      message =
          'الأصدقاء والتحديات تحتاج حسابًا سحابيًا، والخدمة السحابية غير مفعّلة في هذا الإصدار. '
          'مسودة مخطط قاعدة البيانات موجودة في المستودع (لم تُختبر)، وتفعيلها يتطلب ربط مشروع Supabase خاص بك.';
    } else if (!auth.isSignedIn) {
      message = 'سجّل الدخول لتتمكن لاحقًا من إضافة الأصدقاء ومشاركة التحديات.';
      action = FilledButton(
        onPressed: () =>
            Navigator.of(context)
                .push(azmRoute(const AuthScreen(fromSettings: true))),
        child: const Text('تسجيل الدخول'),
      );
    } else {
      message = 'حسابك مفعّل، لكن شاشات الأصدقاء والتحديات ولوحة الترتيب لم تُنفَّذ بعد في هذا الإصدار.';
    }

    return Scaffold(
      appBar: AppBar(title: const Text('الأصدقاء والتحديات')),
      body: EmptyState(
        icon: Icons.groups_rounded,
        title: 'قريبًا',
        message: message,
        action: action,
      ),
    );
  }
}

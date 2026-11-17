import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../application/providers.dart';
import '../../data/auth_service.dart';
import '../flow.dart';
import '../widgets/azm_logo.dart';
import '../widgets/common.dart';

/// Sign in / create account. Always offers "continue without an account":
/// Azm is fully usable offline with local data.
class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key, this.fromSettings = false});

  /// When opened from Settings, closing returns to the previous screen
  /// instead of continuing the first-run flow.
  final bool fromSettings;

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _signUp = false;
  bool _busy = false;
  bool _hidePassword = true;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _finish() {
    if (widget.fromSettings) {
      Navigator.of(context).pop();
    } else {
      goToNext(context, ref);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = ref.read(authServiceProvider);
    setState(() => _busy = true);
    try {
      if (_signUp) {
        final signedIn = await auth.signUp(
          email: _email.text.trim(),
          password: _password.text,
          displayName: _name.text.trim(),
        );
        if (_name.text.trim().isNotEmpty) {
          await ref
              .read(settingsProvider.notifier)
              .setDisplayName(_name.text.trim());
        }
        if (!signedIn) {
          if (!mounted) return;
          await showAzmMessage(
            context,
            title: 'تحقق من بريدك',
            message:
                'أرسلنا رسالة تأكيد إلى ${_email.text.trim()}. أكّد حسابك ثم سجّل الدخول.',
            icon: Icons.mark_email_read_rounded,
            accent: Theme.of(context).colorScheme.secondary,
          );
          if (!mounted) return;
          setState(() => _signUp = false);
          return;
        }
      } else {
        await auth.signIn(email: _email.text.trim(), password: _password.text);
      }
      if (!mounted) return;
      _finish();
    } catch (e) {
      if (!mounted) return;
      showAzmSnack(context, authErrorMessage(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _skip() async {
    await ref.read(settingsProvider.notifier).skipAuth();
    if (!mounted) return;
    _finish();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final configured = ref.watch(authServiceProvider).configured;
    return Scaffold(
      appBar: widget.fromSettings ? AppBar() : null,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Center(child: AzmLogo(size: 76)),
                    const SizedBox(height: 20),
                    Text(
                      _signUp ? 'إنشاء حساب' : 'تسجيل الدخول',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'الحساب يتيح مزامنة بياناتك بين أجهزتك والمشاركة مع الأصدقاء. ويمكنك استخدام التطبيق بدونه.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                        height: 1.7,
                      ),
                    ),
                    const SizedBox(height: 24),
                    if (!configured)
                      AzmCard(
                        color: scheme.surfaceContainerHighest,
                        child: Row(
                          children: [
                            Icon(
                              Icons.cloud_off_rounded,
                              color: scheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'الخدمة السحابية غير مفعّلة في هذا الإصدار. بياناتك تُحفظ على هذا الجهاز فقط.',
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(height: 1.6),
                              ),
                            ),
                          ],
                        ),
                      )
                    else ...[
                      if (_signUp) ...[
                        TextFormField(
                          controller: _name,
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(
                            labelText: 'الاسم',
                            prefixIcon: Icon(Icons.person_outline_rounded),
                          ),
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? 'أدخل اسمك'
                              : null,
                        ),
                        const SizedBox(height: 12),
                      ],
                      TextFormField(
                        controller: _email,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        textDirection: TextDirection.ltr,
                        decoration: const InputDecoration(
                          labelText: 'البريد الإلكتروني',
                          prefixIcon: Icon(Icons.mail_outline_rounded),
                        ),
                        validator: (v) {
                          final value = v?.trim() ?? '';
                          if (!value.contains('@') || !value.contains('.')) {
                            return 'أدخل بريدًا إلكترونيًا صحيحًا';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _password,
                        obscureText: _hidePassword,
                        textDirection: TextDirection.ltr,
                        decoration: InputDecoration(
                          labelText: 'كلمة المرور',
                          prefixIcon: const Icon(Icons.lock_outline_rounded),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _hidePassword
                                  ? Icons.visibility_off_rounded
                                  : Icons.visibility_rounded,
                            ),
                            onPressed: () =>
                                setState(() => _hidePassword = !_hidePassword),
                          ),
                        ),
                        validator: (v) => (v == null || v.length < 6)
                            ? 'كلمة المرور 6 أحرف على الأقل'
                            : null,
                      ),
                      const SizedBox(height: 20),
                      FilledButton(
                        onPressed: _busy ? null : _submit,
                        child: _busy
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.4,
                                ),
                              )
                            : Text(_signUp ? 'إنشاء الحساب' : 'دخول'),
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: _busy
                            ? null
                            : () => setState(() => _signUp = !_signUp),
                        child: Text(
                          _signUp
                              ? 'لدي حساب بالفعل'
                              : 'ليس لدي حساب، إنشاء حساب جديد',
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    OutlinedButton(
                      onPressed: _busy
                          ? null
                          : (widget.fromSettings
                                ? () => Navigator.of(context).pop()
                                : _skip),
                      child: Text(
                        widget.fromSettings ? 'إغلاق' : 'المتابعة بدون حساب',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

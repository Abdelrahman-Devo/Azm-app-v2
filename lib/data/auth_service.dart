import 'package:supabase_flutter/supabase_flutter.dart';

/// Thin wrapper around Supabase Auth. When the build has no Supabase
/// configuration, the service reports `configured == false` and the app runs
/// fully offline with local data.
class AuthService {
  const AuthService({required this.configured});

  final bool configured;

  SupabaseClient? get client => configured ? Supabase.instance.client : null;

  User? get currentUser => client?.auth.currentUser;
  bool get isSignedIn => currentUser != null;

  Stream<AuthState> get authChanges =>
      client?.auth.onAuthStateChange ?? const Stream<AuthState>.empty();

  Future<void> signIn({required String email, required String password}) async {
    final c = client;
    if (c == null) throw const AuthException('الخدمة السحابية غير مفعّلة');
    await c.auth.signInWithPassword(email: email, password: password);
  }

  /// Returns true when the account is created and signed in immediately,
  /// false when the project requires email confirmation first.
  Future<bool> signUp({
    required String email,
    required String password,
    required String displayName,
  }) async {
    final c = client;
    if (c == null) throw const AuthException('الخدمة السحابية غير مفعّلة');
    final res = await c.auth.signUp(
      email: email,
      password: password,
      data: {'display_name': displayName},
    );
    return res.session != null;
  }

  Future<void> signOut() async {
    await client?.auth.signOut();
  }
}

String authErrorMessage(Object error) {
  if (error is AuthException) {
    final m = error.message.toLowerCase();
    if (m.contains('invalid login')) return 'البريد أو كلمة المرور غير صحيحة';
    if (m.contains('already registered') || m.contains('already exists')) {
      return 'هذا البريد مسجل مسبقًا';
    }
    if (m.contains('password')) return 'كلمة المرور ضعيفة (6 أحرف على الأقل)';
    if (m.contains('email not confirmed')) {
      return 'أكّد بريدك الإلكتروني من الرسالة المرسلة إليك أولًا';
    }
    return error.message;
  }
  return 'تعذر الاتصال. تحقق من الإنترنت وحاول مرة أخرى';
}

/// Build-time configuration. Nothing secret is stored in the repository:
/// pass values with `--dart-define` (see README / supabase/README.md).
class AppConfig {
  const AppConfig._();

  static const String supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
  );

  static const bool supabaseConfigured =
      supabaseUrl != '' && supabaseAnonKey != '';
}

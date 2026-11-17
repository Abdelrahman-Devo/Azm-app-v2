import 'package:shared_preferences/shared_preferences.dart';

class AppSettings {
  const AppSettings({
    this.themeMode = 'system',
    this.localeCode = 'ar',
    this.onboardingDone = false,
    this.authSkipped = false,
    this.displayName = '',
  });

  /// 'system' | 'light' | 'dark'
  final String themeMode;
  final String localeCode;
  final bool onboardingDone;
  final bool authSkipped;
  final String displayName;

  AppSettings copyWith({
    String? themeMode,
    String? localeCode,
    bool? onboardingDone,
    bool? authSkipped,
    String? displayName,
  }) => AppSettings(
    themeMode: themeMode ?? this.themeMode,
    localeCode: localeCode ?? this.localeCode,
    onboardingDone: onboardingDone ?? this.onboardingDone,
    authSkipped: authSkipped ?? this.authSkipped,
    displayName: displayName ?? this.displayName,
  );
}

class SettingsRepository {
  SettingsRepository(this._prefs);

  final SharedPreferences _prefs;

  static const _kTheme = 'azm.theme_mode';
  static const _kLocale = 'azm.locale';
  static const _kOnboarding = 'azm.onboarding_done';
  static const _kAuthSkipped = 'azm.auth_skipped';
  static const _kName = 'azm.display_name';

  AppSettings load() => AppSettings(
    themeMode: _prefs.getString(_kTheme) ?? 'system',
    localeCode: _prefs.getString(_kLocale) ?? 'ar',
    onboardingDone: _prefs.getBool(_kOnboarding) ?? false,
    authSkipped: _prefs.getBool(_kAuthSkipped) ?? false,
    displayName: _prefs.getString(_kName) ?? '',
  );

  Future<void> save(AppSettings s) async {
    await _prefs.setString(_kTheme, s.themeMode);
    await _prefs.setString(_kLocale, s.localeCode);
    await _prefs.setBool(_kOnboarding, s.onboardingDone);
    await _prefs.setBool(_kAuthSkipped, s.authSkipped);
    await _prefs.setString(_kName, s.displayName);
  }

  Future<void> clear() async {
    await _prefs.remove(_kTheme);
    await _prefs.remove(_kLocale);
    await _prefs.remove(_kOnboarding);
    await _prefs.remove(_kAuthSkipped);
    await _prefs.remove(_kName);
  }
}

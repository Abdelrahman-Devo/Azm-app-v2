import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import 'application/providers.dart';
import 'core/theme.dart';
import 'presentation/splash/splash_screen.dart';

ThemeMode themeModeFromString(String value) {
  switch (value) {
    case 'light':
      return ThemeMode.light;
    case 'dark':
      return ThemeMode.dark;
    default:
      return ThemeMode.system;
  }
}

class AzmApp extends ConsumerWidget {
  const AzmApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Azm - عزم',
      // Arabic (RTL) is the only translated language for now. The locale
      // preference is stored so English can be added without a migration.
      locale: const Locale('ar'),
      supportedLocales: const [Locale('ar'), Locale('en')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      themeMode: themeModeFromString(settings.themeMode),
      theme: buildAzmTheme(Brightness.light),
      darkTheme: buildAzmTheme(Brightness.dark),
      home: const SplashScreen(),
    );
  }
}

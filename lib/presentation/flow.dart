import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../application/providers.dart';
import 'auth/auth_screen.dart';
import 'onboarding/onboarding_screen.dart';
import 'shell/home_shell.dart';
import 'widgets/common.dart';

/// Decides which screen follows the splash / onboarding / auth steps.
Widget nextScreenFor(WidgetRef ref) {
  final settings = ref.read(settingsProvider);
  final auth = ref.read(authServiceProvider);
  if (!settings.onboardingDone) return const OnboardingScreen();
  if (auth.configured && !auth.isSignedIn && !settings.authSkipped) {
    return const AuthScreen();
  }
  return const HomeShell();
}

void goToNext(BuildContext context, WidgetRef ref) {
  Navigator.of(context).pushReplacement(azmRoute(nextScreenFor(ref)));
}

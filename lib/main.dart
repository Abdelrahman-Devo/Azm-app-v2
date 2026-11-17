import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:material_ui/material_ui.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';
import 'application/providers.dart';
import 'core/app_config.dart';
import 'data/app_database.dart';
import 'data/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('ar');

  final prefs = await SharedPreferences.getInstance();
  final db = await AppDatabase.open(
    databaseFactory,
    p.join(await getDatabasesPath(), 'azm.db'),
  );

  NotificationService notifications = LocalNotificationService();
  try {
    await notifications.init();
  } catch (e) {
    // The app must remain usable even if notifications can't be initialised.
    debugPrint('Azm: notification init failed: $e');
    notifications = NoopNotificationService();
  }

  if (AppConfig.supabaseConfigured) {
    await Supabase.initialize(
      url: AppConfig.supabaseUrl,
      publishableKey: AppConfig.supabaseAnonKey,
    );
  }

  runApp(
    ProviderScope(
      overrides: [
        databaseProvider.overrideWithValue(db),
        sharedPreferencesProvider.overrideWithValue(prefs),
        notificationServiceProvider.overrideWithValue(notifications),
      ],
      child: const AzmApp(),
    ),
  );
}

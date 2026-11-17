import 'package:azm/application/providers.dart';
import 'package:azm/data/app_database.dart';
import 'package:azm/presentation/dashboard/dashboard_screen.dart';
import 'package:azm/presentation/habits/habit_editor_screen.dart';
import 'package:azm/core/theme.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

Future<Widget> _app(Widget home) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final db = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
  await db.close();
  final appDb = await AppDatabase.open(
    databaseFactoryFfi,
    inMemoryDatabasePath,
  );
  addTearDown(appDb.close);
  return ProviderScope(
    overrides: [
      databaseProvider.overrideWithValue(appDb),
      sharedPreferencesProvider.overrideWithValue(prefs),
    ],
    child: MaterialApp(
      locale: const Locale('ar'),
      supportedLocales: const [Locale('ar')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      theme: buildAzmTheme(Brightness.light),
      home: home,
    ),
  );
}

void main() {
  sqfliteFfiInit();
  setUpAll(() => initializeDateFormatting('ar'));

  testWidgets('dashboard shows an honest empty state with no habits', (
    tester,
  ) async {
    await tester.runAsync(() async {});
    final app = await tester.runAsync(() => _app(const DashboardScreen()));
    await tester.pumpWidget(app!);
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 200)),
    );
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('ابدأ رحلتك'), findsOneWidget);
    expect(find.text('أضف أول عادة'), findsOneWidget);
    // No seeded/demo habits.
    expect(find.text('عادات اليوم'), findsNothing);
  });

  testWidgets('habit editor validates the name before saving', (tester) async {
    final app = await tester.runAsync(() => _app(const HabitEditorScreen()));
    await tester.pumpWidget(app!);
    await tester.pump();
    await tester.ensureVisible(find.text('إضافة العادة'));
    await tester.tap(find.text('إضافة العادة'));
    await tester.pump();
    expect(find.text('أدخل اسم العادة'), findsOneWidget);
  });
}

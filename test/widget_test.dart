import 'package:azm/app.dart';
import 'package:azm/data/habit_repository.dart';
import 'package:azm/state/app_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Azm dashboard renders with the local habit repository', (
    tester,
  ) async {
    await initializeDateFormatting('ar');
    SharedPreferences.setMockInitialValues({});
    final repository = HabitRepository();
    await repository.load();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [habitRepositoryProvider.overrideWithValue(repository)],
        child: const AzmApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('عزم'), findsOneWidget);
    expect(find.text('عادات اليوم'), findsOneWidget);
    expect(find.text('قراءة القرآن'), findsOneWidget);
  });
}

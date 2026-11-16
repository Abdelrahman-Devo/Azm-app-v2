import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'app.dart';
import 'data/habit_repository.dart';
import 'state/app_state.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('ar');
  final repository = HabitRepository();
  await repository.load();
  runApp(ProviderScope(
    overrides: [habitRepositoryProvider.overrideWithValue(repository)],
    child: const AzmApp(),
  ));
}

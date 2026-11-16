import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';
import 'data/habit_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final repository = HabitRepository();
  await repository.load();
  runApp(ProviderScope(
    overrides: [habitRepositoryProvider.overrideWithValue(repository)],
    child: const AzmApp(),
  ));
}

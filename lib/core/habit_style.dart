import 'package:material_ui/material_ui.dart';

/// Icons a habit can use, addressed by a stable string key stored in the DB.
const Map<String, IconData> habitIcons = {
  'flag': Icons.flag_rounded,
  'book': Icons.menu_book_rounded,
  'quran': Icons.auto_stories_rounded,
  'pray': Icons.mosque_rounded,
  'fitness': Icons.fitness_center_rounded,
  'run': Icons.directions_run_rounded,
  'water': Icons.water_drop_rounded,
  'sleep': Icons.bedtime_rounded,
  'study': Icons.school_rounded,
  'code': Icons.code_rounded,
  'meditate': Icons.self_improvement_rounded,
  'food': Icons.restaurant_rounded,
  'clean': Icons.cleaning_services_rounded,
  'work': Icons.work_rounded,
  'music': Icons.music_note_rounded,
  'heart': Icons.favorite_rounded,
};

IconData iconForKey(String key) => habitIcons[key] ?? Icons.flag_rounded;

/// Palette offered when creating a habit (ARGB ints).
const List<int> habitColors = [
  0xFF2FBF71,
  0xFF1E88E5,
  0xFF8E5CF7,
  0xFFF4A024,
  0xFFE5596B,
  0xFF14A3A3,
  0xFFE2674A,
  0xFF5B6B8C,
];

Color colorForValue(int value) => Color(value);

IconData badgeIcon(String key) {
  switch (key) {
    case 'start':
      return Icons.rocket_launch_rounded;
    case 'ten':
      return Icons.looks_one_rounded;
    case 'fifty':
      return Icons.workspace_premium_rounded;
    case 'hundred':
      return Icons.military_tech_rounded;
    case 'streak7':
      return Icons.local_fire_department_rounded;
    case 'streak30':
      return Icons.whatshot_rounded;
    case 'camera':
      return Icons.photo_camera_rounded;
    case 'level':
      return Icons.trending_up_rounded;
    case 'focus':
      return Icons.timer_rounded;
    case 'perfect':
      return Icons.verified_rounded;
    default:
      return Icons.emoji_events_rounded;
  }
}

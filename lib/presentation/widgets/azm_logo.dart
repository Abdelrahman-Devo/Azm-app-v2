import 'package:material_ui/material_ui.dart';

import '../../core/theme.dart';

/// Azm brand mark: navy rounded square with a green "momentum" bolt.
class AzmLogo extends StatelessWidget {
  const AzmLogo({super.key, this.size = 96});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.28),
        gradient: const LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [Color(0xFF17407A), AzmColors.navyDeep],
        ),
        boxShadow: [
          BoxShadow(
            color: AzmColors.green.withValues(alpha: 0.35),
            blurRadius: size * 0.3,
            offset: Offset(0, size * 0.1),
          ),
        ],
      ),
      child: Icon(
        Icons.bolt_rounded,
        size: size * 0.58,
        color: AzmColors.greenBright,
      ),
    );
  }
}

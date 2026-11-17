import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../application/providers.dart';
import '../../core/theme.dart';
import '../flow.dart';
import '../widgets/azm_logo.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..forward();

  String? _error;

  @override
  void initState() {
    super.initState();
    _boot();
  }

  Future<void> _boot() async {
    try {
      // Load persisted data while the logo animates.
      await Future.wait<Object?>([
        Future<void>.delayed(const Duration(milliseconds: 1500)),
        ref.read(habitsProvider.future),
        ref.read(completionsProvider.future),
        ref.read(timerProvider.future),
      ]);
      if (!mounted) return;
      goToNext(context, ref);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'تعذر تحميل بياناتك المحلية.\n$e');
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final curved = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    );
    return Scaffold(
      backgroundColor: AzmColors.navyDeep,
      body: Center(
        child: _error != null
            ? Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.error_outline_rounded,
                      color: Colors.white70,
                      size: 48,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _error!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white70),
                    ),
                    const SizedBox(height: 20),
                    FilledButton(
                      onPressed: () {
                        setState(() => _error = null);
                        _boot();
                      },
                      child: const Text('إعادة المحاولة'),
                    ),
                  ],
                ),
              )
            : FadeTransition(
                opacity: _controller,
                child: ScaleTransition(
                  scale: Tween<double>(begin: 0.8, end: 1).animate(curved),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const AzmLogo(size: 112),
                      const SizedBox(height: 24),
                      const Text(
                        'عزم',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 40,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'AZM',
                        style: TextStyle(
                          color: AzmColors.greenBright.withValues(alpha: 0.9),
                          fontSize: 14,
                          letterSpacing: 6,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 28),
                      const SizedBox(
                        width: 26,
                        height: 26,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.6,
                          color: AzmColors.greenBright,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}

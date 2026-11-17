import 'dart:async';

import 'package:material_ui/material_ui.dart';

/// Rebuilds its subtree on a short interval. Used only for *display*: timer
/// values are always recomputed from stored timestamps, never accumulated
/// from ticks.
class SecondTicker extends StatefulWidget {
  const SecondTicker({
    super.key,
    required this.builder,
    this.interval = const Duration(milliseconds: 500),
  });

  final WidgetBuilder builder;
  final Duration interval;

  @override
  State<SecondTicker> createState() => _SecondTickerState();
}

class _SecondTickerState extends State<SecondTicker> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(widget.interval, (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(context);
}

import 'package:flutter/material.dart';
import '../settings.dart';

// The splash. It shows "Elendheim" for one second, then fades into the app. No
// subtitle, no tagline, ever. With reduce-motion on, the fade is an instant cut.

class SplashScreen extends StatefulWidget {
  final VoidCallback onDone;
  const SplashScreen({super.key, required this.onDone});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _fade =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 550));

  @override
  void initState() {
    super.initState();
    _run();
  }

  Future<void> _run() async {
    // Hold "Elendheim" for one second.
    await Future<void>.delayed(const Duration(seconds: 1));
    if (!mounted) return;
    // Read the setting after the first frame - not during initState.
    final reduceMotion = SettingsScope.of(context).reduceMotion;
    if (reduceMotion) {
      widget.onDone(); // instant cut, no fade
      return;
    }
    // Then fade it out and hand over to the app.
    await _fade.forward();
    if (mounted) widget.onDone();
  }

  @override
  void dispose() {
    _fade.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.onSurface;
    return Scaffold(
      body: Center(
        child: FadeTransition(
          opacity: Tween<double>(begin: 1, end: 0).animate(_fade),
          child: Text(
            'Elendheim',
            // The one word. Large, quiet, letter-spaced.
            style: TextStyle(
              color: color,
              fontSize: 34,
              letterSpacing: 6,
              fontWeight: FontWeight.w300,
            ),
          ),
        ),
      ),
    );
  }
}

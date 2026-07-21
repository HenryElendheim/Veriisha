import 'package:flutter/material.dart';
import '../settings.dart';
import 'new_run_screen.dart';
import 'settings_screen.dart';

// The title screen. The app's name lives here, so nothing else needs to repeat
// it. New Run is a stub for now - the game screens are the next build.

class TitleScreen extends StatelessWidget {
  const TitleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  kAppName,
                  style: TextStyle(
                    color: scheme.onSurface,
                    fontSize: 40,
                    letterSpacing: 4,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 48),
                _MenuButton(
                  label: 'New Run',
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(builder: (_) => const NewRunScreen()),
                  ),
                ),
                const SizedBox(height: 12),
                _MenuButton(
                  label: 'Settings',
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(builder: (_) => const SettingsScreen()),
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

class _MenuButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  const _MenuButton({required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: scheme.primary,
          side: BorderSide(color: scheme.primary),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: const RoundedRectangleBorder(),
        ),
        child: Text(label, style: const TextStyle(letterSpacing: 2, fontSize: 16)),
      ),
    );
  }
}

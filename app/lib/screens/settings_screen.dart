import 'package:flutter/material.dart';
import '../settings.dart';

// The settings menu. Accessibility first - contrast, text size, reduced motion -
// with the version shown plainly at the bottom so you always know which build you
// are on. The app's name is not repeated here; it lives on the title screen.

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = SettingsScope.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          children: [
            const _SectionHeader('Display'),
            SwitchListTile(
              title: const Text('Dark mode'),
              subtitle: const Text('Off switches to a light palette.'),
              value: s.darkMode,
              onChanged: (v) =>
                  SettingsScope.update(context, s.copyWith(darkMode: v)),
            ),
            SwitchListTile(
              title: const Text('High contrast'),
              subtitle: const Text('Pure black and white with a brighter accent.'),
              value: s.highContrast,
              onChanged: (v) =>
                  SettingsScope.update(context, s.copyWith(highContrast: v)),
            ),

            const _SectionHeader('Reading'),
            ListTile(
              title: const Text('Text size'),
              subtitle: Slider(
                value: s.fontScale,
                min: 0.8,
                max: 1.6,
                divisions: 8,
                label: '${(s.fontScale * 100).round()}%',
                onChanged: (v) =>
                    SettingsScope.update(context, s.copyWith(fontScale: v)),
              ),
              trailing: Text('${(s.fontScale * 100).round()}%'),
            ),

            const _SectionHeader('Motion'),
            SwitchListTile(
              title: const Text('Reduce motion'),
              subtitle: const Text('Disables the splash fade and screen transitions.'),
              value: s.reduceMotion,
              onChanged: (v) =>
                  SettingsScope.update(context, s.copyWith(reduceMotion: v)),
            ),

            const SizedBox(height: 32),
            // The version, plainly. No app name - it is already on the title screen.
            Center(
              child: Text(
                'v$kAppVersion',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                  letterSpacing: 2,
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String label;
  const _SectionHeader(this.label);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 4, left: 4),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          color: Theme.of(context).colorScheme.primary,
          letterSpacing: 3,
          fontSize: 12,
        ),
      ),
    );
  }
}

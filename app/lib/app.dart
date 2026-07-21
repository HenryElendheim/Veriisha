import 'package:flutter/material.dart';
import 'settings.dart';
import 'theme.dart';
import 'screens/splash_screen.dart';
import 'screens/title_screen.dart';

// The root of the app. It holds the settings, rebuilds the whole tree when they
// change (so contrast, text size and motion apply everywhere at once), and shows
// the splash before the title.

class VeriishaApp extends StatefulWidget {
  const VeriishaApp({super.key});

  @override
  State<VeriishaApp> createState() => _VeriishaAppState();
}

class _VeriishaAppState extends State<VeriishaApp> {
  final SettingsStore _store = SettingsStore();
  AppSettings _settings = const AppSettings();
  bool _splashDone = false;

  @override
  void initState() {
    super.initState();
    // Load saved accessibility choices. Until they arrive, the dark defaults
    // stand - and the one-second splash covers the load.
    _store.load().then((loaded) {
      if (mounted) setState(() => _settings = loaded);
    });
  }

  void _apply(AppSettings next) {
    setState(() => _settings = next);
    _store.save(next); // persist so the choice survives the next launch
  }

  @override
  Widget build(BuildContext context) {
    return SettingsScope(
      settings: _settings,
      onChanged: _apply,
      child: MaterialApp(
        title: kAppName,
        debugShowCheckedModeBanner: false,
        theme: VeriishaTheme.from(_settings),
        // Text size is applied app-wide here, respecting the setting on top of the
        // system scale.
        builder: (context, child) {
          final media = MediaQuery.of(context);
          return MediaQuery(
            data: media.copyWith(
              textScaler: TextScaler.linear(_settings.fontScale),
            ),
            child: child!,
          );
        },
        home: _splashDone
            ? const TitleScreen()
            : SplashScreen(onDone: () => setState(() => _splashDone = true)),
      ),
    );
  }
}

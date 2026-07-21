import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

// App-wide identity and the accessibility settings that shape how everything is
// drawn. Kept small and passed down through an inherited widget, so no extra
// state-management package is needed.

/// The app's name. Shown on the title screen; the settings screen deliberately
/// does not repeat it, only the version.
const String kAppName = 'Veriisha';

/// The build's version. Releases run v1.0, v1.1, up to v2.0 for big changes; this
/// pre-release shell sits below that line.
const String kAppVersion = '0.1.0';

/// The accessibility and display settings. Dark mode is the default - this game
/// is dark first.
class AppSettings {
  final bool darkMode;
  final bool highContrast;
  final double fontScale; // 0.8 .. 1.6, multiplied over the system text size
  final bool reduceMotion; // disables the splash fade and screen transitions

  const AppSettings({
    this.darkMode = true,
    this.highContrast = false,
    this.fontScale = 1.0,
    this.reduceMotion = false,
  });

  AppSettings copyWith({
    bool? darkMode,
    bool? highContrast,
    double? fontScale,
    bool? reduceMotion,
  }) =>
      AppSettings(
        darkMode: darkMode ?? this.darkMode,
        highContrast: highContrast ?? this.highContrast,
        fontScale: fontScale ?? this.fontScale,
        reduceMotion: reduceMotion ?? this.reduceMotion,
      );
}

/// Loads and saves the settings so a player's accessibility choices survive
/// between launches. Backed by shared_preferences, which is test-safe via
/// `SharedPreferences.setMockInitialValues`.
class SettingsStore {
  static const _darkMode = 'darkMode';
  static const _highContrast = 'highContrast';
  static const _fontScale = 'fontScale';
  static const _reduceMotion = 'reduceMotion';

  Future<AppSettings> load() async {
    final p = await SharedPreferences.getInstance();
    return AppSettings(
      darkMode: p.getBool(_darkMode) ?? true,
      highContrast: p.getBool(_highContrast) ?? false,
      fontScale: p.getDouble(_fontScale) ?? 1.0,
      reduceMotion: p.getBool(_reduceMotion) ?? false,
    );
  }

  Future<void> save(AppSettings s) async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(_darkMode, s.darkMode);
    await p.setBool(_highContrast, s.highContrast);
    await p.setDouble(_fontScale, s.fontScale);
    await p.setBool(_reduceMotion, s.reduceMotion);
  }
}

/// Exposes the current settings and a way to change them to the whole widget
/// tree. Read with `SettingsScope.of(context)` and change with
/// `SettingsScope.update(context, ...)`.
class SettingsScope extends InheritedWidget {
  final AppSettings settings;
  final ValueChanged<AppSettings> onChanged;

  const SettingsScope({
    super.key,
    required this.settings,
    required this.onChanged,
    required super.child,
  });

  static SettingsScope _scope(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<SettingsScope>();
    assert(scope != null, 'No SettingsScope found in the widget tree.');
    return scope!;
  }

  static AppSettings of(BuildContext context) => _scope(context).settings;

  /// Apply a change to the current settings.
  static void update(BuildContext context, AppSettings next) =>
      _scope(context).onChanged(next);

  @override
  bool updateShouldNotify(SettingsScope oldWidget) =>
      settings != oldWidget.settings;
}

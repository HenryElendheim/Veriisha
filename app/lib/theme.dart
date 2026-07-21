import 'package:flutter/material.dart';
import 'settings.dart';

// The look of the app. Dark first, with a high-contrast variant. Colour is never
// the only signal in the game screens - here it just sets the mood: cold, spare,
// a little clinical, like a shelter readout.

class VeriishaTheme {
  // The base dark palette - deep slate, a cold cyan accent, a warning amber.
  static const _bg = Color(0xFF0E1114);
  static const _surface = Color(0xFF171B20);
  static const _accent = Color(0xFF5FB0C4);
  static const _amber = Color(0xFFD8A657);
  static const _text = Color(0xFFE6E9EC);

  // High contrast pushes to pure black and white with a brighter accent, for
  // readability over mood.
  static const _bgHc = Color(0xFF000000);
  static const _surfaceHc = Color(0xFF0A0A0A);
  static const _accentHc = Color(0xFF7FE0F5);
  static const _textHc = Color(0xFFFFFFFF);

  /// Build the theme from the current settings.
  static ThemeData from(AppSettings s) {
    final hc = s.highContrast;
    final scheme = ColorScheme.dark(
      surface: hc ? _bgHc : _bg,
      surfaceContainer: hc ? _surfaceHc : _surface,
      primary: hc ? _accentHc : _accent,
      secondary: hc ? _amber : _amber,
      onSurface: hc ? _textHc : _text,
      onPrimary: Colors.black,
      error: const Color(0xFFE06C6C),
    );

    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      fontFamily: 'monospace', // a spare, readout feel; swappable later
    );

    return base.copyWith(
      textTheme: base.textTheme.apply(
        bodyColor: scheme.onSurface,
        displayColor: scheme.onSurface,
      ),
      // Reduce motion strips the default page slide/fade to an instant cut.
      pageTransitionsTheme: s.reduceMotion
          ? const PageTransitionsTheme(builders: {
              TargetPlatform.android: _NoTransitionsBuilder(),
              TargetPlatform.linux: _NoTransitionsBuilder(),
            })
          : const PageTransitionsTheme(),
    );
  }
}

// A page transition that does nothing - used when reduce-motion is on.
class _NoTransitionsBuilder extends PageTransitionsBuilder {
  const _NoTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) =>
      child; // no animation, just the destination
}

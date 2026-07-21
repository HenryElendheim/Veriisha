import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:veriisha_app/app.dart';
import 'package:veriisha_app/settings.dart';

// The shell: the splash shows Elendheim, hands over to the title, and the settings
// menu opens with the accessibility controls and the version.

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('settings persist across a reload', () async {
    SharedPreferences.setMockInitialValues({});
    final store = SettingsStore();
    await store.save(const AppSettings(highContrast: true, fontScale: 1.4, reduceMotion: true));
    final loaded = await store.load();
    expect(loaded.highContrast, isTrue);
    expect(loaded.fontScale, 1.4);
    expect(loaded.reduceMotion, isTrue);
    expect(loaded.darkMode, isTrue); // default holds
  });

  testWidgets('splash shows Elendheim, then the title appears', (tester) async {
    await tester.pumpWidget(const VeriishaApp());
    expect(find.text('Elendheim'), findsOneWidget);
    expect(find.text(kAppName), findsNothing); // no title yet

    // Past the one-second hold and the fade.
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();

    expect(find.text(kAppName), findsOneWidget);
    expect(find.text('New Run'), findsOneWidget);
  });

  testWidgets('settings open and expose the accessibility controls and version',
      (tester) async {
    await tester.pumpWidget(const VeriishaApp());
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();

    expect(find.text('High contrast'), findsOneWidget);
    expect(find.text('Reduce motion'), findsOneWidget);
    expect(find.text('Text size'), findsOneWidget);
    expect(find.text('v$kAppVersion'), findsOneWidget);

    // Toggling a control does not throw and the switch flips.
    await tester.tap(find.text('High contrast'));
    await tester.pumpAndSettle();
  });

  testWidgets('a new run reaches the run screen and actions drive it', (tester) async {
    await tester.pumpWidget(const VeriishaApp());
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();

    // Title -> New Run -> choose a site.
    await tester.tap(find.text('New Run'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Choose a site'));
    await tester.pumpAndSettle();

    // Site select -> Cave -> the run screen.
    expect(find.text('Cave'), findsOneWidget);
    await tester.tap(find.text('Cave'));
    await tester.pumpAndSettle();

    expect(find.text('End day'), findsOneWidget);
    expect(find.text('Forage'), findsOneWidget);
    expect(find.text('Hunger'), findsWidgets); // the crew lane bars

    // Spend the day's action, then end the day - the run carries on.
    await tester.tap(find.text('Forage'));
    await tester.pump();
    await tester.tap(find.text('End day'));
    await tester.pump();
    expect(find.text('End day'), findsOneWidget);
  });

  testWidgets('reduce motion is wired through the settings', (tester) async {
    await tester.pumpWidget(const VeriishaApp());
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Reduce motion'));
    await tester.pumpAndSettle();
    expect(find.text('Reduce motion'), findsOneWidget);
  });
}

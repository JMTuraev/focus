// Renders the shell at Telegram-like window sizes in light and dark mode and
// fails on any layout overflow or other exception.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fokus/auth/mock_auth.dart';
import 'package:fokus/main.dart';
import 'package:fokus/state/app_state.dart';
import 'package:fokus/state/settings.dart';

import 'helpers/fonts.dart';

void main() {
  setUpAll(() async {
    // Real metrics instead of the test font, so overflows match the app.
    await loadSegoeUi();
  });

  const sizes = {
    'wide 1440x900': Size(1440, 900),
    'medium 1000x700': Size(1000, 700),
    'medium min 800x600': Size(800, 600),
    'narrow 600x700': Size(600, 700),
    'narrow min 420x560': Size(420, 560),
  };

  for (final dark in [false, true]) {
    for (final entry in sizes.entries) {
      testWidgets('${dark ? 'dark' : 'light'} ${entry.key}', (tester) async {
        tester.view.physicalSize = entry.value;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);

        final state = AppState();
        await tester.pumpWidget(FokusApp(
          state: state,
          settings: Settings.inMemory(dark ? ThemeMode.dark : ThemeMode.light),
          auth: MockAuth(loggedIn: true),
        ));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);

        // Open a chat (narrow: switches from the list to the chat).
        await tester.tap(find.text('Madina Rahimova').first);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.text('Xabar yozing…'), findsOneWidget);

        // Toggle the info panel (docked, overlay or full screen). It starts
        // docked open in the wide layout and closed in the others.
        final wasOpen = find.text('Ma’lumot').evaluate().isNotEmpty;
        expect(wasOpen, entry.value.width >= 1200);
        await tester.tap(find.byTooltip('Ma’lumot paneli').first);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.text('Ma’lumot').evaluate().isNotEmpty, !wasOpen);

        // Other modules render too.
        state.openModule(Module.tasks);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets('narrow back button returns to the chat list', (tester) async {
    tester.view.physicalSize = const Size(600, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(FokusApp(state: AppState(), settings: Settings.inMemory(ThemeMode.light), auth: MockAuth(loggedIn: true)));
    await tester.pumpAndSettle();
    expect(find.text('Qidiruv'), findsOneWidget);
    expect(find.text('Xabar yozing…'), findsNothing);

    await tester.tap(find.text('Onam').first);
    await tester.pumpAndSettle();
    expect(find.text('Xabar yozing…'), findsOneWidget);
    expect(find.text('Qidiruv'), findsNothing);

    await tester.tap(find.byTooltip('Orqaga'));
    await tester.pumpAndSettle();
    expect(find.text('Qidiruv'), findsOneWidget);
  });

  testWidgets('theme button switches light to dark', (tester) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final settings = Settings.inMemory(ThemeMode.light);
    await tester.pumpWidget(FokusApp(state: AppState(), settings: settings, auth: MockAuth(loggedIn: true)));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Tungi rejimga o‘tish'));
    await tester.pumpAndSettle();
    expect(settings.themeMode, ThemeMode.dark);
    expect(find.byTooltip('Yorug‘ rejimga o‘tish'), findsOneWidget);
  });
}

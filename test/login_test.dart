// Login screen (mock auth): phone → code → 2FA password → app, errors,
// going back, logout, and layout at small and large sizes in both themes.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fokus/auth/auth.dart';
import 'package:fokus/auth/mock_auth.dart';
import 'package:fokus/main.dart';
import 'package:fokus/state/settings.dart';

import 'helpers/fonts.dart';

Future<MockAuth> _pumpLogin(
  WidgetTester tester, {
  Size size = const Size(1200, 800),
  bool dark = false,
  Duration delay = Duration.zero,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final auth = MockAuth(delay: delay);
  await tester.pumpWidget(FokusApp(
    settings: Settings.inMemory(dark ? ThemeMode.dark : ThemeMode.light),
    auth: auth,
  ));
  unawaited(auth.start());
  await tester.pumpAndSettle();
  return auth;
}

Future<void> _enter(WidgetTester tester, String text) async {
  await tester.enterText(find.byType(TextField), text);
  await tester.pumpAndSettle();
}

Future<void> _press(WidgetTester tester, String label) async {
  await tester.tap(find.widgetWithText(FilledButton, label));
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(loadSegoeUi);

  testWidgets('full login flow ends in the app', (tester) async {
    final auth = await _pumpLogin(tester);
    expect(find.text('Telefon raqamingiz'), findsOneWidget);
    expect(find.textContaining('Sinov rejimi'), findsOneWidget);

    await _enter(tester, '+998901234567');
    expect(find.text('+998 90 123 45 67'), findsOneWidget, reason: 'phone is formatted while typing');
    await _press(tester, 'Davom etish');

    expect(auth.state.value.step, AuthStep.waitCode);
    expect(find.text('+998 90 123 45 67'), findsOneWidget);
    expect(find.textContaining('Telegram ilovasiga yubordik'), findsOneWidget);

    // 5 digits submit automatically.
    await _enter(tester, '12345');
    expect(auth.state.value.step, AuthStep.waitPassword);
    expect(find.text('Ikki bosqichli tekshiruv'), findsOneWidget);
    expect(find.text('Maslahat: sevimli shahar'), findsOneWidget);

    await _enter(tester, 'maxfiy');
    await _press(tester, 'Kirish');
    expect(auth.state.value.step, AuthStep.ready);
    expect(find.text('Qidiruv'), findsOneWidget, reason: 'chat list is shown');
  });

  testWidgets('errors are shown in Uzbek and the user can retry', (tester) async {
    final auth = await _pumpLogin(tester);

    await _enter(tester, '12');
    await _press(tester, 'Davom etish');
    expect(find.text('Telefon raqamini mamlakat kodi bilan to‘liq kiriting.'), findsOneWidget);
    expect(auth.state.value.step, AuthStep.waitPhone);

    await _enter(tester, '998901234567');
    await _press(tester, 'Davom etish');
    await _enter(tester, '00000');
    expect(find.text('Kod noto‘g‘ri. Qaytadan tekshirib kiriting.'), findsOneWidget);
    expect(auth.state.value.step, AuthStep.waitCode);

    await _enter(tester, '11111');
    await _enter(tester, 'xato');
    await _press(tester, 'Kirish');
    expect(find.text('Parol noto‘g‘ri.'), findsOneWidget);
    expect(auth.state.value.step, AuthStep.waitPassword);
  });

  testWidgets('a wrong code keeps the field focused for the next try', (tester) async {
    // A real delay, so the field is rendered in its busy state.
    final auth = await _pumpLogin(tester, delay: const Duration(milliseconds: 300));
    await _enter(tester, '+998901234567');
    await _press(tester, 'Davom etish');
    expect(auth.state.value.step, AuthStep.waitCode);

    await _enter(tester, '00000');
    expect(find.text('Kod noto‘g‘ri. Qaytadan tekshirib kiriting.'), findsOneWidget);
    expect(tester.widget<EditableText>(find.byType(EditableText)).focusNode.hasFocus, isTrue);
  });

  testWidgets('change number goes back and keeps the number', (tester) async {
    final auth = await _pumpLogin(tester);
    await _enter(tester, '998935550011');
    await _press(tester, 'Davom etish');
    expect(auth.state.value.step, AuthStep.waitCode);

    await tester.tap(find.text('Raqamni o‘zgartirish'));
    await tester.pumpAndSettle();
    expect(auth.state.value.step, AuthStep.waitPhone);
    expect(find.text('+998 93 555 00 11'), findsOneWidget);
  });

  testWidgets('logout asks for confirmation and returns to login', (tester) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final auth = MockAuth(loggedIn: true, delay: Duration.zero);
    await tester.pumpWidget(FokusApp(settings: Settings.inMemory(ThemeMode.light), auth: auth));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Akkauntdan chiqish'));
    await tester.pumpAndSettle();
    expect(find.text('Akkauntdan chiqasizmi?'), findsOneWidget);

    await tester.tap(find.text('Bekor qilish'));
    await tester.pumpAndSettle();
    expect(auth.state.value.step, AuthStep.ready);

    await tester.tap(find.byTooltip('Akkauntdan chiqish'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, 'Chiqish'));
    await tester.pumpAndSettle();
    expect(auth.state.value.step, AuthStep.waitPhone);
    expect(find.text('Telefon raqamingiz'), findsOneWidget);
  });

  for (final dark in [false, true]) {
    for (final size in const [Size(420, 560), Size(800, 600), Size(1440, 900)]) {
      testWidgets('every step lays out at ${size.width.toInt()}x${size.height.toInt()} ${dark ? 'dark' : 'light'}',
          (tester) async {
        final auth = await _pumpLogin(tester, size: size, dark: dark);
        expect(tester.takeException(), isNull);
        await _enter(tester, '998901234567');
        await _press(tester, 'Davom etish');
        expect(tester.takeException(), isNull);
        await _enter(tester, '12345');
        expect(tester.takeException(), isNull);
        expect(auth.state.value.step, AuthStep.waitPassword);
      });
    }
  }
}

// Right click on a message: copy, edit an own text in the composer,
// delete with "also for the other side".

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fokus/auth/mock_auth.dart';
import 'package:fokus/main.dart';
import 'package:fokus/state/settings.dart';

import 'helpers/fonts.dart';

const _own = 'Va alaykum assalom! 3 ta filial uchun «Biznes» tarifi to‘g‘ri keladi. Demo ko‘rsatib beraman.';
const _theirs = 'Assalomu alaykum, Jafar aka! Zalimiz uchun AllClubs tizimini ko‘rib chiqyapmiz.';

Future<void> _pump(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1440, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(FokusApp(settings: Settings.inMemory(ThemeMode.light), auth: MockAuth(loggedIn: true)));
  await tester.pumpAndSettle();
}

Future<void> _menuOn(WidgetTester tester, String text) async {
  await tester.tap(find.text(text).last, buttons: kSecondaryButton);
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(loadSegoeUi);

  testWidgets('an own message is edited in the composer; Escape cancels', (tester) async {
    await _pump(tester);

    // Someone else's message cannot be edited.
    await _menuOn(tester, _theirs);
    expect(find.text('Nusxalash'), findsOneWidget);
    expect(find.text('Tahrirlash'), findsNothing);
    expect(find.text('O‘chirish'), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();

    // Edit, then cancel with Escape: the composer is empty again.
    await _menuOn(tester, _own);
    await tester.tap(find.text('Tahrirlash'));
    await tester.pumpAndSettle();
    final composer = find.byType(TextField).last;
    expect(tester.widget<TextField>(composer).controller!.text, _own);
    expect(find.byTooltip('Tahrirlashni bekor qilish (Esc)'), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.byTooltip('Tahrirlashni bekor qilish (Esc)'), findsNothing);
    expect(tester.widget<TextField>(composer).controller!.text, '');

    // Edit and save with Enter: new text and "tahrirlangan".
    await _menuOn(tester, _own);
    await tester.tap(find.text('Tahrirlash'));
    await tester.pumpAndSettle();
    await tester.enterText(composer, 'Biznes tarifi mos keladi, demo payshanba.');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    expect(find.text('Biznes tarifi mos keladi, demo payshanba.'), findsWidgets);
    expect(find.text('tahrirlangan'), findsOneWidget);
    expect(find.text(_own), findsNothing);
    expect(tester.widget<TextField>(composer).controller!.text, '');
    expect(tester.takeException(), isNull);
  });

  testWidgets('delete asks first and offers "also for" the other side', (tester) async {
    await _pump(tester);
    await _menuOn(tester, _own);
    await tester.tap(find.text('O‘chirish'));
    await tester.pumpAndSettle();
    expect(find.text('Xabar o‘chirilsinmi?'), findsOneWidget);
    expect(find.text('Dilshod Karimov uchun ham o‘chirish'), findsOneWidget);

    // Cancel keeps it.
    await tester.tap(find.text('Bekor qilish'));
    await tester.pumpAndSettle();
    expect(find.text(_own), findsOneWidget);

    await _menuOn(tester, _own);
    await tester.tap(find.text('O‘chirish'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'O‘chirish'));
    await tester.pumpAndSettle();
    expect(find.text(_own), findsNothing);

    // Copy puts the text on the clipboard.
    String? copied;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'Clipboard.setData') copied = (call.arguments as Map)['text'] as String?;
      return null;
    });
    await _menuOn(tester, _theirs);
    await tester.tap(find.text('Nusxalash'));
    await tester.pumpAndSettle();
    expect(copied, _theirs);
    expect(find.text('Nusxalandi'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

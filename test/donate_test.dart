import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fokus/auth/mock_auth.dart';
import 'package:fokus/config.dart';
import 'package:fokus/donate/donate_info.dart';
import 'package:fokus/main.dart';
import 'package:fokus/state/settings.dart';
import 'package:fokus/theme.dart';
import 'package:fokus/ui/donate_dialog.dart';
import 'package:fokus/ui/title_bar.dart';

import 'helpers/fonts.dart';

const _full = DonateInfo(
  card: '8600 1234-5678 9012',
  cardHolder: 'Test Egasi',
  cardLabel: 'Uzcard',
  payme: 'https://payme.uz/test',
  click: 'http://click.uz/insecure',
  tirikchilik: 'https://tirikchilik.uz/test',
  otherUrl: 'javascript:alert(1)',
  telegram: 'https://t.me/fokus_test',
);

Future<void> _pumpDialog(WidgetTester tester, DonateInfo info, {required LinkOpener open, bool dark = false}) async {
  await tester.pumpWidget(MaterialApp(
    theme: buildTheme(dark ? Brightness.dark : Brightness.light),
    home: Builder(
      builder: (context) => Scaffold(
        body: Center(
          child: TextButton(
            onPressed: () => showDonateDialog(context, info: info, open: open),
            child: const Text('open'),
          ),
        ),
      ),
    ),
  ));
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(loadSegoeUi);

  group('DonateInfo', () {
    test('formats valid card numbers in groups of four', () {
      expect(_full.cardNumber, '8600 1234 5678 9012');
      expect(_full.cardDigits, '8600123456789012');
      expect(const DonateInfo(card: '1234').cardNumber, isNull);
      expect(const DonateInfo(card: '8600 12ab 5678 9012').cardNumber, isNull);
      expect(const DonateInfo().hasPayment, isFalse);
    });

    test('keeps only https links, in order, with default labels', () {
      final links = _full.links;
      expect(links.map((l) => l.label), ['Payme', 'Tirikchilik']);
      expect(links.first.url.host, 'payme.uz');
      expect(_full.telegramUrl?.path, '/fokus_test');
      final other = const DonateInfo(otherUrl: 'https://buymeacoffee.com/x').links.single;
      expect(other.label, 'Xalqaro to‘lov');
      expect(const DonateInfo(otherUrl: 'https://ko-fi.com/x', otherLabel: 'Ko-fi').links.single.label, 'Ko-fi');
    });
  });

  testWidgets('empty config shows the placeholder and the help links', (tester) async {
    final opened = <Uri>[];
    await _pumpDialog(tester, const DonateInfo(), open: (u) async {
      opened.add(u);
      return true;
    });
    expect(find.text('To‘lov usullari hali qo‘shilmagan. Tez orada shu yerda paydo bo‘ladi.'), findsOneWidget);
    expect(find.text('Bank kartasi'), findsNothing);
    expect(find.text('Yangiliklar kanali'), findsNothing);

    await tester.tap(find.text('Xato yoki taklif yozish'));
    await tester.pumpAndSettle();
    expect(opened.single.toString(), '${AppConfig.repoUrl}/issues/new');

    await tester.tap(find.text('Yopish'));
    await tester.pumpAndSettle();
    expect(find.byType(DonateDialog), findsNothing);
  });

  for (final dark in [false, true]) {
    testWidgets('full config: copy the card and open links (${dark ? 'dark' : 'light'})', (tester) async {
      String? clipboard;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
        if (call.method == 'Clipboard.setData') clipboard = (call.arguments as Map)['text'] as String;
        return null;
      });
      addTearDown(() => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, null));

      final opened = <Uri>[];
      var fail = false;
      await _pumpDialog(tester, _full, dark: dark, open: (u) async {
        opened.add(u);
        return !fail;
      });
      expect(tester.takeException(), isNull);
      expect(find.text('Uzcard'), findsOneWidget);
      expect(find.text('8600 1234 5678 9012\nTest Egasi'), findsOneWidget);
      expect(find.text('Payme'), findsOneWidget);
      expect(find.text('Tirikchilik'), findsOneWidget);
      expect(find.text('Click'), findsNothing); // http link is ignored
      expect(find.text('Xalqaro to‘lov'), findsNothing);
      expect(find.text('To‘lov usullari hali qo‘shilmagan. Tez orada shu yerda paydo bo‘ladi.'), findsNothing);

      await tester.tap(find.text('Nusxalash'));
      await tester.pump();
      expect(clipboard, '8600123456789012');
      expect(find.text('Nusxalandi'), findsOneWidget);
      await tester.pump(const Duration(seconds: 3));
      expect(find.text('Nusxalash'), findsOneWidget);

      await tester.tap(find.text('Payme'));
      await tester.pump();
      expect(opened.last.toString(), 'https://payme.uz/test');

      fail = true;
      await tester.ensureVisible(find.text('Yangiliklar kanali'));
      await tester.tap(find.text('Yangiliklar kanali'));
      await tester.pumpAndSettle();
      expect(opened.last.toString(), 'https://t.me/fokus_test');
      expect(find.text('Havolani ochib bo‘lmadi: t.me'), findsOneWidget);
    });
  }

  for (final loggedIn in [true, false]) {
    testWidgets('title bar heart opens the donation dialog (${loggedIn ? 'shell' : 'login'}, narrow)', (tester) async {
      tester.view.physicalSize = const Size(420, 560);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      final auth = MockAuth(loggedIn: loggedIn);
      await tester.pumpWidget(FokusApp(settings: Settings.inMemory(ThemeMode.light), auth: auth));
      if (!loggedIn) unawaited(auth.start());
      await tester.pumpAndSettle();
      await tester.tap(find.descendant(of: find.byType(FokusTitleBar), matching: find.byIcon(Icons.favorite_border)));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.byType(DonateDialog), findsOneWidget);
      expect(find.text('Focus’ni qo‘llab-quvvatlash'), findsOneWidget);
    });
  }
}

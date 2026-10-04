// Russian and English UI: every module renders without overflow at the
// supported window sizes, and the language can be switched at runtime.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fokus/auth/mock_auth.dart';
import 'package:fokus/data/format.dart';
import 'package:fokus/l10n/l10n.dart';
import 'package:fokus/main.dart';
import 'package:fokus/state/settings.dart';
import 'package:fokus/ui/rail.dart';
import 'package:fokus/ui/title_bar.dart';

import 'helpers/fonts.dart';

const _moduleIcons = [
  Icons.chat_bubble_outline,
  Icons.grid_view_outlined,
  Icons.checklist,
  Icons.calendar_today_outlined,
  Icons.sticky_note_2_outlined,
  Icons.folder_outlined,
  Icons.bar_chart,
];

void main() {
  setUpAll(loadSegoeUi);
  tearDown(() => S.current = S.uz);

  test('Russian plurals', () {
    String files(int n) => ruPlural(n, 'файл', 'файла', 'файлов');
    expect([1, 2, 5, 11, 12, 21, 22, 25, 101, 111].map(files),
        ['файл', 'файла', 'файлов', 'файлов', 'файлов', 'файл', 'файла', 'файлов', 'файл', 'файлов']);
    expect(enPlural(1, 'file', 'files'), 'file');
    expect(enPlural(0, 'file', 'files'), 'files');
  });

  test('dates and sizes follow the language', () {
    final d = DateTime(2026, 10, 8, 15, 30);
    final now = DateTime(2026, 10, 20);
    S.current = S.ru;
    expect(Fmt.dayLabel(d, now: now), '8 октября');
    expect(Fmt.size(4404019), '4,2 МБ');
    S.current = S.en;
    expect(Fmt.dayLabel(d, now: now), 'October 8');
    expect(Fmt.size(4404019), '4.2 MB');
    expect(Fmt.dueLabel(DateTime(2026, 10, 21), now: now), 'Tomorrow');
    S.current = S.uz;
    expect(Fmt.dayLabel(d, now: now), '8-oktabr');
  });

  for (final lang in [AppLanguage.ru, AppLanguage.en]) {
    for (final size in const [Size(1440, 900), Size(800, 600), Size(420, 560)]) {
      testWidgets('${lang.name} ${size.width.toInt()}x${size.height.toInt()}: all modules render', (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);

        await tester.pumpWidget(FokusApp(
          settings: Settings.inMemory(ThemeMode.light, lang),
          auth: MockAuth(loggedIn: true),
        ));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        final t = S.of(lang);
        // Narrow windows show labels only in tooltips.
        if (size.width >= 800) expect(find.text(t.app.chats), findsWidgets);

        for (final icon in _moduleIcons) {
          await tester.tap(find.descendant(of: find.byType(Rail), matching: find.byIcon(icon)));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull, reason: '$icon');
        }

        // A chat with its composer.
        await tester.tap(find.descendant(of: find.byType(Rail), matching: find.byIcon(Icons.chat_bubble_outline)));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Madina Rahimova').first);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);

        // Settings and the donation dialog.
        await tester.tap(find.descendant(of: find.byType(Rail), matching: find.byIcon(Icons.settings_outlined)));
        await tester.pumpAndSettle();
        expect(find.text(t.app.settings), findsWidgets);
        expect(tester.takeException(), isNull);
        await tester.tap(find.text(t.common.close).last);
        await tester.pumpAndSettle();
        await tester.tap(find.descendant(of: find.byType(FokusTitleBar), matching: find.byIcon(Icons.favorite_border)));
        await tester.pumpAndSettle();
        expect(find.text(t.app.supportFocus), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets('the title bar switches the language at runtime', (tester) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final settings = Settings.inMemory(ThemeMode.light);
    await tester.pumpWidget(FokusApp(settings: settings, auth: MockAuth(loggedIn: true)));
    await tester.pumpAndSettle();
    expect(find.text('Chatlar'), findsWidgets);

    await tester.tap(find.descendant(of: find.byType(FokusTitleBar), matching: find.byIcon(Icons.translate)));
    await tester.pumpAndSettle();
    await tester.tap(find.text('English'));
    await tester.pumpAndSettle();
    expect(settings.language, AppLanguage.en);
    expect(find.text('Chats'), findsWidgets);
    expect(find.text('Chatlar'), findsNothing);

    await tester.tap(find.descendant(of: find.byType(FokusTitleBar), matching: find.byIcon(Icons.translate)));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Русский'));
    await tester.pumpAndSettle();
    expect(find.text('Чаты'), findsWidgets);
    expect(tester.takeException(), isNull);
  });
}

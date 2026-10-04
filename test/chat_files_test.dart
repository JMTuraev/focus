// Sending files, the emoji panel and opening downloaded files.
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fokus/auth/mock_auth.dart';
import 'package:fokus/data/models.dart';
import 'package:fokus/data/send_plan.dart';
import 'package:fokus/main.dart';
import 'package:fokus/state/settings.dart';
import 'package:fokus/theme.dart';
import 'package:fokus/ui/chats/chat_view.dart';
import 'package:fokus/ui/chats/file_actions.dart';
import 'package:fokus/ui/chats/send_files_dialog.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers/fonts.dart';

const _img = OutgoingFile(path: r'C:\nope\photo.jpg', name: 'photo.jpg', size: 200000);
const _pdf = OutgoingFile(path: r'C:\nope\hisobot.pdf', name: 'hisobot.pdf', size: 1500000);

Future<void> _pumpHost(WidgetTester tester, Future<void> Function(BuildContext) onOpen) async {
  await tester.pumpWidget(MaterialApp(
    theme: buildTheme(Brightness.light),
    home: Builder(
      builder: (context) => Scaffold(
        body: Center(child: TextButton(onPressed: () => onOpen(context), child: const Text('open'))),
      ),
    ),
  ));
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(loadSegoeUi);

  group('send plan', () {
    test('Telegram photo limits', () {
      expect(photoFits(100, 1280, 960), isTrue);
      expect(photoFits(11 * 1024 * 1024, 1280, 960), isFalse);
      expect(photoFits(100, 9000, 2000), isFalse);
      expect(photoFits(100, 4200, 200), isFalse); // ratio over 20
      expect(photoFits(100, 0, 10), isFalse);
    });

    test('photos first in albums of ten, then documents', () async {
      final files = [
        for (var i = 0; i < 12; i++) OutgoingFile(path: 'p$i.jpg', name: 'p$i.jpg', size: 10),
        for (var i = 0; i < 3; i++) OutgoingFile(path: 'd$i.zip', name: 'd$i.zip', size: 10),
      ];
      final planned = await planFiles(files, compressImages: true, measure: (_) async => (800, 600));
      final groups = groupForSending(planned);
      expect(groups.map((g) => g.length), [10, 2, 3]);
      expect(groups[2].every((p) => !p.asPhoto), isTrue);

      final plain = await planFiles(files, compressImages: false, measure: (_) async => (800, 600));
      expect(plain.any((p) => p.asPhoto), isFalse);
      final unreadable = await planFiles(files.take(1).toList(), compressImages: true, measure: (_) async => null);
      expect(unreadable.single.asPhoto, isFalse);
    });

    test('programs and scripts count as risky', () {
      for (final n in ['setup.exe', 'run.BAT', 'x.ps1', 'a.lnk', 'b.msi']) {
        expect(isRiskyFile(n), isTrue, reason: n);
      }
      for (final n in ['hisobot.pdf', 'photo.jpg', 'README', 'data.xlsx']) {
        expect(isRiskyFile(n), isFalse, reason: n);
      }
    });
  });

  testWidgets('send dialog: remove a file, keep compression, return the caption', (tester) async {
    SendFilesChoice? result;
    await _pumpHost(tester, (context) async {
      result = await showSendFilesDialog(context, [_img, _pdf], caption: 'Salom', pickMore: () async => []);
    });
    expect(find.text('2 ta fayl yuborish'), findsOneWidget);
    expect(find.text('Rasmlarni siqib yuborish'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.byTooltip('Olib tashlash').first); // the photo
    await tester.pumpAndSettle();
    expect(find.text('Fayl yuborish'), findsOneWidget);
    expect(find.text('Rasmlarni siqib yuborish'), findsNothing);

    await tester.enterText(find.byType(TextField), 'Mana hisobot');
    await tester.tap(find.text('Yuborish'));
    await tester.pumpAndSettle();
    expect(result!.files.single.name, 'hisobot.pdf');
    expect(result!.caption, 'Mana hisobot');
    expect(result!.compressImages, isTrue);
  });

  testWidgets('send dialog: cancel returns nothing', (tester) async {
    SendFilesChoice? result = const SendFilesChoice(files: [], caption: '', compressImages: true);
    await _pumpHost(tester, (context) async {
      result = await showSendFilesDialog(context, [_img], pickMore: () async => []);
    });
    expect(find.text('Rasm yuborish'), findsOneWidget);
    await tester.tap(find.text('Bekor qilish'));
    await tester.pumpAndSettle();
    expect(result, isNull);
  });

  testWidgets('a program asks before it is opened', (tester) async {
    await _pumpHost(tester, (context) => openDownloadedFile(context, r'C:\nope\setup.exe', 'setup.exe'));
    expect(find.text('Faylni ochasizmi?'), findsOneWidget);
    await tester.tap(find.text('Bekor qilish'));
    await tester.pumpAndSettle();
    expect(find.text('Faylni ochasizmi?'), findsNothing);
  });

  testWidgets('emoji panel opens, inserts at the cursor and closes', (tester) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(FokusApp(settings: Settings.inMemory(ThemeMode.light), auth: MockAuth(loggedIn: true)));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Madina Rahimova').first);
    await tester.pumpAndSettle();

    final input = find.descendant(of: find.byType(ChatView), matching: find.byType(TextField));
    await tester.enterText(input, 'Salom ');
    await tester.tap(find.byTooltip('Emoji'));
    await tester.pumpAndSettle();
    expect(find.byType(EmojiPicker), findsOneWidget);

    // Recents are empty at first; the smileys tab has 😀.
    await tester.tap(find.byIcon(Icons.tag_faces));
    await tester.pumpAndSettle();
    await tester.tap(find.text('😀').first);
    await tester.pumpAndSettle();
    expect(tester.widget<TextField>(input).controller!.text, 'Salom 😀');
    expect(tester.takeException(), isNull);

    await tester.tap(find.byTooltip('Emojilarni yopish'));
    await tester.pumpAndSettle();
    expect(find.byType(EmojiPicker), findsNothing);
  });

  testWidgets('sent files show in the chat as file rows', (tester) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(FokusApp(settings: Settings.inMemory(ThemeMode.dark), auth: MockAuth(loggedIn: true)));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Madina Rahimova').first);
    await tester.pumpAndSettle();

    await tester.widget<ChatView>(find.byType(ChatView)).state.sendFiles([_pdf], caption: 'Hisobot ilova qilindi');
    await tester.pumpAndSettle();
    expect(find.byType(FileRow), findsWidgets);
    expect(find.text('hisobot.pdf'), findsWidgets);
    expect(find.text('Hisobot ilova qilindi'), findsWidgets);
    expect(tester.takeException(), isNull);
  });
}

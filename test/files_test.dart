// "Fayllar" module: only what the user saved from chats (files and texts),
// marks (favorite, tags), filters, grouping, rename and removal.

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fokus/auth/mock_auth.dart';
import 'package:fokus/data/local_store.dart';
import 'package:fokus/data/mock_source.dart';
import 'package:fokus/data/models.dart';
import 'package:fokus/main.dart';
import 'package:fokus/state/app_state.dart';
import 'package:fokus/state/settings.dart';
import 'package:fokus/ui/chats/info_panel.dart';
import 'package:fokus/ui/files/files_screen.dart';
import 'package:fokus/ui/rail.dart';
import 'package:fokus/ui/shell.dart';

import 'helpers/fonts.dart';

Future<void> _pump(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1440, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(FokusApp(settings: Settings.inMemory(ThemeMode.light), auth: MockAuth(loggedIn: true)));
  await tester.pumpAndSettle();
}

AppState _state(WidgetTester tester) => tester.widget<Shell>(find.byType(Shell)).state;

Finder _inFiles(String text) => find.descendant(of: find.byType(FilesScreen), matching: find.text(text));

Finder _textCard() => find.descendant(of: find.byType(FilesScreen), matching: find.textContaining('Narxlarni'));

Future<void> _openFiles(WidgetTester tester) async {
  await tester.tap(find.descendant(of: find.byType(Rail), matching: find.byIcon(Icons.folder_outlined)));
  await tester.pumpAndSettle();
}

/// Dilshod's PDF (d4, with a caption) and his last text (d6) in "Fayllar".
Future<void> _saveBoth(WidgetTester tester) async {
  final s = _state(tester);
  final msgs = s.messagesOf('dilshod');
  s.saveToFiles(msgs.firstWhere((m) => m.id == 'd4'));
  s.saveToFiles(msgs.firstWhere((m) => m.id == 'd6'));
  await tester.pumpAndSettle();
}

/// The marks button of the card that shows [text].
Finder _marksOf(Finder text) =>
    find.descendant(of: find.ancestor(of: text, matching: find.byType(MouseRegion)).first, matching: find.byTooltip('Belgilash'));

void main() {
  setUpAll(loadSegoeUi);

  test('saving keeps a snapshot; marks from the old list are adopted once', () async {
    final s = AppState(source: MockChatSource(), store: LocalStore.memory());
    s.openChat('dilshod');
    final pdf = s.messagesOf('dilshod').firstWhere((m) => m.id == 'd4');
    expect(s.saveToFiles(pdf), isTrue);
    expect(s.saveToFiles(pdf), isFalse, reason: 'already saved');
    final item = s.store.savedOf('dilshod', 'd4')!;
    expect((item.kind, item.fileName, item.chatTitle, item.text),
        (SavedKind.documents, 'AllClubs_taqdimot.pdf', 'Dilshod Karimov', 'Qisqacha taqdimot:'));
    expect(SavedKind.of(s.messagesOf('dilshod').firstWhere((m) => m.id == 'd6')), SavedKind.text);

    // A mark made in the old all-chats list (Bekzod's contract) is adopted.
    s.store.setMark(FileMark(chatId: 'bekzod', messageId: 'b1', kind: 'documents', favorite: true, updatedAt: DateTime(2026, 10, 4)));
    await s.adoptMarkedFiles();
    expect(s.store.savedOf('bekzod', 'b1')?.fileName, 'Hamkorlik_shartnomasi_v3.docx');
    expect(s.savedCountFor('dilshod'), 1);

    s.removeFromFiles('dilshod', 'd4');
    expect(s.isSaved('dilshod', 'd4'), isFalse);
  });

  testWidgets('empty at first; "Fayllarga" in the chat and the file menu save into it', (tester) async {
    await _pump(tester);
    await _openFiles(tester);
    expect(find.textContaining('Hali hech narsa saqlanmagan'), findsOneWidget);

    // Back in Dilshod's chat: the quick action saves the latest incoming text.
    await tester.tap(find.descendant(of: find.byType(Rail), matching: find.byIcon(Icons.chat_bubble_outline)));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Fayllarga'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Fayllarga saqlandi'), findsOneWidget);
    await tester.tap(find.text('Fayllarga'));
    await tester.pumpAndSettle();
    expect(find.text('Bu xabar Fayllarda bor'), findsOneWidget);

    // Right click on the PDF in the chat → "Fayllarga saqlash".
    await tester.tap(find.text('AllClubs_taqdimot.pdf').first, buttons: kSecondaryButton);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Fayllarga saqlash'));
    await tester.pumpAndSettle();

    // The info panel's "Fayllar" link opens the chat's saved items.
    await tester.tap(find.descendant(of: find.byType(InfoPanel), matching: find.text('Fayllar')));
    await tester.pumpAndSettle();
    expect(find.byType(FilesScreen), findsOneWidget);
    expect(_inFiles('AllClubs_taqdimot.pdf'), findsOneWidget);
    expect(_textCard(), findsOneWidget);
    expect(_inFiles('Hammasi 2'), findsOneWidget);
    expect(_inFiles('Hujjatlar 1'), findsOneWidget);
    expect(_inFiles('Matnlar 1'), findsOneWidget);
    expect(find.byType(InputChip), findsOneWidget, reason: 'chat filter chip');

    await tester.tap(_inFiles('Matnlar 1'));
    await tester.pumpAndSettle();
    expect(_inFiles('AllClubs_taqdimot.pdf'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('marks popover, filters, search, grouping and removal', (tester) async {
    await _pump(tester);
    await _saveBoth(tester);
    await _openFiles(tester);

    await tester.tap(_marksOf(_inFiles('AllClubs_taqdimot.pdf')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sevimlilarga qo‘shish'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, 'Shartnoma');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.text('Sevimlilardan olish'), findsNothing, reason: 'Escape closes the popover');

    // Favorites and tag pills filter; a second tap clears them.
    await tester.tap(_inFiles('Sevimlilar 1'));
    await tester.pumpAndSettle();
    expect(_inFiles('AllClubs_taqdimot.pdf'), findsOneWidget);
    expect(_textCard(), findsNothing);
    await tester.tap(_inFiles('Sevimlilar 1'));
    await tester.pumpAndSettle();
    await tester.tap(_inFiles('Shartnoma 1'));
    await tester.pumpAndSettle();
    expect(_textCard(), findsNothing);
    await tester.tap(_inFiles('Shartnoma 1'));
    await tester.pumpAndSettle();
    expect(_textCard(), findsOneWidget);

    // Search covers texts, names and tags.
    final search = find.descendant(of: find.byType(FilesScreen), matching: find.byType(TextField));
    await tester.enterText(search, 'narx');
    await tester.pumpAndSettle();
    expect(_inFiles('AllClubs_taqdimot.pdf'), findsNothing);
    await tester.enterText(search, 'shartnoma');
    await tester.pumpAndSettle();
    expect(_inFiles('AllClubs_taqdimot.pdf'), findsOneWidget);
    expect(_textCard(), findsNothing);
    await tester.enterText(search, '');
    await tester.pumpAndSettle();

    // Grouping: mock messages have no date; by chat there is one header.
    expect(_inFiles('Sanasiz'), findsOneWidget);
    await tester.tap(_inFiles('Chatlar'));
    await tester.pumpAndSettle();
    expect(_inFiles('Sanasiz'), findsNothing);
    expect(_inFiles('Dilshod Karimov'), findsNWidgets(3), reason: 'group header and two card footers');

    // Remove the text from its popover.
    await tester.tap(_marksOf(_textCard()));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Fayllardan olib tashlash'));
    await tester.pumpAndSettle();
    expect(_textCard(), findsNothing);
    expect(_inFiles('Matnlar 0'), findsOneWidget);

    // "Chatga o‘tish" from the context menu opens the chat.
    await tester.tap(_inFiles('AllClubs_taqdimot.pdf'), buttons: kSecondaryButton);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Chatga o‘tish'));
    await tester.pumpAndSettle();
    expect(find.byType(FilesScreen), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a saved file is renamed inline, Focus-only, and the original name is kept', (tester) async {
    await _pump(tester);
    await _saveBoth(tester);
    await _openFiles(tester);

    // Pencil shows on hover; Enter saves the new name.
    final g = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await g.addPointer(location: Offset.zero);
    addTearDown(g.removePointer);
    await g.moveTo(tester.getCenter(_inFiles('AllClubs_taqdimot.pdf')));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Nomini o‘zgartirish'));
    await tester.pumpAndSettle();
    final field = find.descendant(of: find.byType(FilesScreen), matching: find.byType(TextField)).last;
    await tester.enterText(field, 'AllClubs taqdimoti (final).pdf');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    expect(_inFiles('AllClubs taqdimoti (final).pdf'), findsOneWidget);
    expect(_inFiles('Asl nomi: AllClubs_taqdimot.pdf'), findsOneWidget);

    // The chat shows the Focus name too; Telegram's message is untouched.
    await tester.tap(find.descendant(of: find.byType(Rail), matching: find.byIcon(Icons.chat_bubble_outline)));
    await tester.pumpAndSettle();
    expect(find.text('AllClubs taqdimoti (final).pdf'), findsWidgets);
    expect(find.text('AllClubs_taqdimot.pdf'), findsNothing);

    // An empty name restores the original.
    await _openFiles(tester);
    await tester.tap(_inFiles('AllClubs taqdimoti (final).pdf'), buttons: kSecondaryButton);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Nomini o‘zgartirish'));
    await tester.pumpAndSettle();
    await tester.enterText(find.descendant(of: find.byType(FilesScreen), matching: find.byType(TextField)).last, '');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    expect(_inFiles('AllClubs_taqdimot.pdf'), findsOneWidget);
    expect(find.textContaining('Asl nomi'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}

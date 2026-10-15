import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fokus/data/chat_source.dart';
import 'package:fokus/data/local_store.dart';
import 'package:fokus/data/mock_source.dart';
import 'package:fokus/data/models.dart';
import 'package:fokus/l10n/l10n.dart';
import 'package:fokus/state/app_state.dart';
import 'package:fokus/theme.dart';
import 'package:fokus/ui/chats/chat_view.dart';
import 'package:fokus/ui/chats/message_menu.dart';

import 'helpers/fonts.dart';

const first =
    Message(id: 'first', text: 'Customer request\nFull context', time: '12:01');
const last =
    Message(id: 'last', text: 'Other message', time: '12:02', out: true);

class _Source extends MockChatSource {
  Future<MessageRights>? pendingRights;
  bool failRights = false;
  List<Message> fixture = [first, last];
  @override
  List<Message> messagesOf(String chatId) => fixture;
  @override
  Future<MessageRights> rightsOf(String chatId, String messageId) async {
    if (failRights) throw StateError('Synthetic offline state');
    return pendingRights ?? super.rightsOf(chatId, messageId);
  }
}

Future<AppState> _mount(WidgetTester tester, _Source source,
    {AppLanguage language = AppLanguage.uz, bool narrow = false}) async {
  tester.view.physicalSize =
      narrow ? const Size(420, 560) : const Size(1100, 780);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final state = AppState(
      source: source, store: LocalStore.memory(), initialChatId: 'dilshod');
  addTearDown(() async {
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
    state.dispose();
    source.dispose();
    S.current = S.uz;
  });
  await tester.pumpWidget(LanguageScope(
      language: language,
      child: MaterialApp(
        theme: buildTheme(narrow ? Brightness.dark : Brightness.light),
        home: Scaffold(
            body: Padding(
                padding: const EdgeInsets.only(top: 36),
                child: Row(children: [
                  if (!narrow) const SizedBox(width: 180),
                  Expanded(
                      child: ListenableBuilder(
                          listenable: state,
                          builder: (_, __) => ChatView(
                              state: state, infoActive: false, onInfo: () {}))),
                ]))),
      )));
  await tester.pumpAndSettle();
  return state;
}

Finder action(String label) =>
    find.widgetWithText(PopupMenuItem<String>, label);
Future<void> menu(WidgetTester tester, String id) async {
  await tester.tap(find.byKey(ValueKey('message-bubble:$id')),
      buttons: kSecondaryButton);
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(loadSegoeUi);
  setUp(() => S.current = S.uz);

  test(
      'menu uses free space beside incoming/outgoing bubbles and stays in the viewport',
      () {
    const viewport = Rect.fromLTRB(180, 140, 1100, 700);
    for (final bubble in [
      const Rect.fromLTRB(900, 600, 1080, 640),
      const Rect.fromLTRB(200, 150, 400, 200)
    ]) {
      final rect = messageMenuRect(
          bubble, viewport, const Size(260, 296), bubble.center);
      expect(rect.overlaps(bubble), isFalse);
      expect(viewport.contains(rect.topLeft), isTrue);
      expect(viewport.contains(rect.bottomRight), isTrue);
    }
    const narrow = Rect.fromLTRB(0, 140, 420, 500);
    for (final bubble in [
      const Rect.fromLTRB(12, 145, 400, 170),
      const Rect.fromLTRB(12, 470, 400, 495)
    ]) {
      final rect =
          messageMenuRect(bubble, narrow, const Size(260, 200), bubble.center);
      expect(rect.overlaps(bubble), isFalse);
      expect(narrow.contains(rect.topLeft), isTrue);
      expect(narrow.contains(rect.bottomRight), isTrue);
    }
  });

  testWidgets(
      'menu is outside the clicked bubble with a shifted chat overlay and closes on Escape',
      (tester) async {
    await _mount(tester, _Source());
    await menu(tester, 'last');
    final popup = find
        .ancestor(
            of: action(S.uz.chats.toTask), matching: find.byType(Material))
        .first;
    final bubble =
        tester.getRect(find.byKey(const ValueKey('message-bubble:last')));
    expect(tester.getRect(popup).overlaps(bubble), isFalse);
    expect(tester.getRect(popup).left, greaterThanOrEqualTo(180));
    expect(find.byType(PopupMenuItem<String>), findsNWidgets(7));
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.byType(PopupMenuItem<String>), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'task and note use the right-clicked message, not the selected/latest message',
      (tester) async {
    final state = await _mount(tester, _Source());
    state.selectMessage('last');
    await tester.pumpAndSettle();
    await menu(tester, 'first');
    await tester.tap(action(S.uz.chats.toTask));
    await tester.pumpAndSettle();
    final task = state.tasks.all.single;
    expect(task.title, 'Customer request');
    expect(task.messageText, first.text);
    expect(task.messageId, first.id);
    expect(task.chatId, 'dilshod');
    await menu(tester, 'first');
    await tester.tap(action(S.uz.chats.toNote));
    await tester.pumpAndSettle();
    final note = state.notes.all.single;
    expect(note.body, first.text);
    expect(note.messageId, first.id);
    expect(note.chatId, 'dilshod');
    expect(note.chatTitle, 'Dilshod Karimov');
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'local actions remain available when Telegram rights cannot load, including a captionless photo',
      (tester) async {
    final source = _Source()
      ..failRights = true
      ..fixture = [
        const Message(
            id: 'photo',
            text: '',
            time: '12:03',
            info: MediaInfo(kind: MediaKind.photo))
      ];
    final state = await _mount(tester, source);
    await menu(tester, 'photo');
    expect(action(S.uz.chats.replyMessage), findsNothing);
    await tester.tap(action(S.uz.chats.toNote));
    await tester.pumpAndSettle();
    expect(state.notes.all.single.body, S.uz.chats.message);
    expect(state.notes.all.single.messageId, 'photo');
  });

  testWidgets('changing chat closes an open menu and discards pending rights',
      (tester) async {
    final source = _Source();
    final state = await _mount(tester, source);
    await menu(tester, 'last');
    state.openChat('madina');
    await tester.pumpAndSettle();
    expect(find.byType(PopupMenuItem<String>), findsNothing);
    final pending = Completer<MessageRights>();
    source.pendingRights = pending.future;
    await tester.tap(find.byKey(const ValueKey('message-bubble:last')),
        buttons: kSecondaryButton);
    await tester.pump();
    state.openChat('dilshod');
    await tester.pumpAndSettle();
    pending.complete(const MessageRights(canEdit: true));
    await tester.pumpAndSettle();
    expect(find.byType(PopupMenuItem<String>), findsNothing);
    expect(state.tasks.all, isEmpty);
    expect(state.notes.all, isEmpty);
  });

  testWidgets(
      'right-clicking a document row offers local actions and preserves file commands',
      (tester) async {
    final source = _Source()
      ..fixture = [
        const Message(
            id: 'document',
            text: '',
            time: '12:03',
            fileName: 'Synthetic.pdf',
            file: FileInfo(fileId: 10, size: 100, path: 'synthetic.pdf'))
      ];
    final state = await _mount(tester, source);
    await tester.tap(find.text('Synthetic.pdf'), buttons: kSecondaryButton);
    await tester.pumpAndSettle();
    expect(find.byType(PopupMenuItem<String>), findsWidgets);
    expect(action(S.uz.common.open), findsOneWidget);
    expect(action(S.uz.chats.showInFolder), findsOneWidget);
    expect(action(S.uz.chats.saveAs), findsOneWidget);
    await tester.tap(action(S.uz.chats.toTask));
    await tester.pumpAndSettle();
    expect(state.tasks.all.single.title, 'Synthetic.pdf');
    expect(state.tasks.all.single.messageId, 'document');
  });

  for (final language in AppLanguage.values) {
    testWidgets(
        'menu stays below the title bar in a narrow dark ${language.name} window',
        (tester) async {
      await _mount(tester, _Source(), narrow: true, language: language);
      await menu(tester, 'last');
      final popup = find
          .ancestor(
              of: action(S.current.chats.toTask),
              matching: find.byType(Material))
          .first;
      final rect = tester.getRect(popup);
      expect(rect.top, greaterThanOrEqualTo(140));
      expect(rect.bottom, lessThanOrEqualTo(504));
      expect(rect.left, greaterThanOrEqualTo(0));
      expect(rect.right, lessThanOrEqualTo(420));
      expect(tester.takeException(), isNull);
    });
  }
}

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
import 'package:fokus/ui/chats/chat_search.dart';
import 'package:fokus/ui/chats/chat_view.dart';

import 'helpers/fonts.dart';

class _Source extends MockChatSource {
  final replies = <(String, String, String)>[];
  final forwards = <(String, String, List<String>)>[];
  Completer<void>? replyPending;
  bool protected = false;
  List<Message>? fixture;
  final searches = <(String, String)>[];
  Future<MessageSearchPage> Function(String, String)? search;

  @override
  List<Message> messagesOf(String chatId) => fixture ?? super.messagesOf(chatId);
  @override
  Future<void> sendReply(String chatId, String text, String messageId) async {
    replies.add((chatId, text, messageId));
    if (replyPending != null) {
      await replyPending!.future;
    } else {
      await super.sendReply(chatId, text, messageId);
    }
  }

  @override
  Future<void> forwardMessages(String chatId, String fromChatId, List<String> messageIds) async {
    forwards.add((chatId, fromChatId, messageIds));
    await super.forwardMessages(chatId, fromChatId, messageIds);
  }

  @override
  Future<MessageRights> rightsOf(String chatId, String messageId) async =>
      protected ? const MessageRights(canReply: true) : super.rightsOf(chatId, messageId);
  @override
  Future<MessageSearchPage> searchMessages(String chatId, String query, {String fromMessageId = '', int limit = 50}) {
    searches.add((query, fromMessageId));
    return search?.call(query, fromMessageId) ?? super.searchMessages(chatId, query, fromMessageId: fromMessageId, limit: limit);
  }
}

Finder get _composer => find.descendant(of: find.byType(ChatView), matching: find.byType(TextField)).last;
Future<AppState> _pump(WidgetTester tester, _Source source, {AppLanguage language = AppLanguage.uz, bool narrow = false}) async {
  tester.view.physicalSize = narrow ? const Size(420, 560) : const Size(900, 800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final state = AppState(source: source, store: LocalStore.memory(), initialChatId: 'dilshod');
  addTearDown(() async {
    await tester.pumpWidget(const SizedBox());
    state.dispose();
    source.dispose();
    S.current = S.uz;
  });
  await tester.pumpWidget(LanguageScope(
      language: language,
      child: MaterialApp(
        theme: buildTheme(narrow ? Brightness.dark : Brightness.light),
        home: Scaffold(
            body: ListenableBuilder(listenable: state, builder: (_, __) => ChatView(state: state, infoActive: false, onInfo: () {}))),
      )));
  await tester.pumpAndSettle();
  return state;
}

Future<void> _reply(WidgetTester tester, _Source source) async {
  final text = source.messagesOf('dilshod').first.text;
  await tester.tap(find.text(text).last, buttons: kSecondaryButton);
  await tester.pumpAndSettle();
  await tester.tap(find.text(S.current.chats.replyMessage));
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(loadSegoeUi);
  setUp(() => S.current = S.uz);

  testWidgets('reply stays with its chat and sent messages show the original preview', (tester) async {
    final source = _Source();
    final state = await _pump(tester, source);
    await _reply(tester, source);
    final original = state.replyOf('dilshod')!;
    await tester.enterText(_composer, 'Customer answer');
    state.openChat('madina');
    await tester.pumpAndSettle();
    expect(find.byTooltip(S.uz.chats.cancelReply), findsNothing);
    state.openChat('dilshod');
    await tester.pumpAndSettle();
    expect(find.byTooltip(S.uz.chats.cancelReply), findsOneWidget);
    expect(tester.widget<TextField>(_composer).controller!.text, 'Customer answer');
    await tester.tap(find.byIcon(Icons.send_rounded));
    await tester.pumpAndSettle();
    expect(source.replies.single, ('dilshod', 'Customer answer', original.messageId));
    expect(state.replyOf('dilshod'), isNull);
    expect(source.messagesOf('dilshod').last.reply!.messageId, original.messageId);
    expect(find.text(original.text), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('failed reply restores its draft but never overwrites a new reply', (tester) async {
    final source = _Source()..replyPending = Completer<void>();
    final state = await _pump(tester, source);
    await _reply(tester, source);
    final reply = state.replyOf('dilshod');
    await tester.enterText(_composer, 'Retain on failure');
    await tester.tap(find.byIcon(Icons.send_rounded));
    await tester.pump();
    source.replyPending!.completeError(StateError('offline'));
    await tester.pumpAndSettle();
    expect(state.draftOf('dilshod'), 'Retain on failure');
    expect(state.replyOf('dilshod'), same(reply));
    source.replyPending = Completer<void>();
    await tester.tap(find.byIcon(Icons.send_rounded));
    await tester.pump();
    const newer = ReplyInfo(chatId: 'dilshod', messageId: 'new', author: 'New customer', text: 'New question');
    state.setReply('dilshod', newer);
    state.setDraft('dilshod', 'New response');
    await tester.pump();
    source.replyPending!.completeError(StateError('offline'));
    await tester.pumpAndSettle();
    expect(state.replyOf('dilshod'), same(newer));
    expect(state.draftOf('dilshod'), 'New response');
    await tester.tap(find.byTooltip(S.uz.chats.cancelReply));
    await tester.pumpAndSettle();
    expect(state.replyOf('dilshod'), isNull);
  });

  testWidgets('forward waits for recipient confirmation and retains attribution', (tester) async {
    final source = _Source();
    final state = await _pump(tester, source);
    final original = source.messagesOf('dilshod').first;
    await tester.tap(find.text(original.text).last, buttons: kSecondaryButton);
    await tester.pumpAndSettle();
    await tester.tap(find.text(S.uz.chats.forwardMessage));
    await tester.pumpAndSettle();
    final dialog = find.byType(Dialog);
    final search = find.descendant(of: dialog, matching: find.byType(TextField));
    await tester.enterText(search, 'Madina');
    await tester.pumpAndSettle();
    await tester.tap(find.descendant(of: dialog, matching: find.byType(ListTile)).first);
    await tester.pumpAndSettle();
    expect(source.forwards, isEmpty);
    await tester.tap(find.widgetWithText(FilledButton, S.uz.common.send));
    await tester.pumpAndSettle();
    expect(source.forwards.single.$1, 'madina');
    expect(source.forwards.single.$2, 'dilshod');
    expect(source.forwards.single.$3, [original.id]);
    expect(state.activeChatId, 'madina');
    expect(source.messagesOf('madina').last.forwardedFrom, isNotNull);
    expect(tester.takeException(), isNull);
  });

  testWidgets('protected messages do not offer forwarding', (tester) async {
    final source = _Source()..protected = true;
    await _pump(tester, source);
    await tester.tap(find.text(source.messagesOf('dilshod').first.text).last, buttons: kSecondaryButton);
    await tester.pumpAndSettle();
    expect(find.text(S.uz.chats.forwardMessage), findsNothing);
    expect(find.text(S.uz.chats.replyMessage), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
  });

  for (final language in AppLanguage.values) {
    testWidgets('narrow ${language.name}: search jumps to an old result and returns to latest', (tester) async {
      final source = _Source()
        ..fixture = [for (var i = 1; i <= 120; i++) Message(id: '$i', text: i == 10 ? 'Invoice 10 original' : 'Invoice $i', time: '12:00')];
      final t = S.of(language);
      await _pump(tester, source, language: language, narrow: true);
      await tester.tap(_composer);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyF);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await tester.pumpAndSettle();
      expect(find.byType(ChatSearch), findsOneWidget);
      final input = find.descendant(of: find.byType(ChatSearch), matching: find.byType(TextField));
      await tester.enterText(input, 'Invoice 10 original');
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pumpAndSettle();
      await tester.tap(find.descendant(of: find.byType(ChatSearch), matching: find.byType(ListTile)).last);
      await tester.pumpAndSettle();
      final history = find.byType(CustomScrollView);
      final result = find.descendant(of: history, matching: find.text('Invoice 10 original'));
      expect(result, findsOneWidget);
      final rect = tester.getRect(result);
      expect(rect.center.dy, greaterThan(tester.getRect(history).top));
      expect(rect.center.dy, lessThan(tester.getRect(history).bottom));
      expect(find.byTooltip(t.chats.latestMessages), findsOneWidget);
      await tester.tap(find.byTooltip(t.chats.latestMessages));
      await tester.pumpAndSettle();
      expect(find.byTooltip(t.chats.latestMessages), findsNothing);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.byType(ChatSearch), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('search ignores a late response after query changes and handles paging', (tester) async {
    final old = Completer<MessageSearchPage>();
    final source = _Source()
      ..search = (query, cursor) async {
        if (query == 'old') return old.future;
        return MessageSearchPage(
            messages: [Message(id: cursor.isEmpty ? '1' : '2', text: '$query result', time: '12:00')],
            total: 2,
            nextFromMessageId: cursor.isEmpty ? 'next' : '');
      };
    await _pump(tester, source);
    await tester.tap(find.byTooltip(S.uz.chats.searchInChat));
    await tester.pumpAndSettle();
    final input = find.descendant(of: find.byType(ChatSearch), matching: find.byType(TextField));
    await tester.enterText(input, 'old');
    await tester.pump(const Duration(milliseconds: 350));
    await tester.enterText(input, 'new');
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pumpAndSettle();
    old.complete(const MessageSearchPage(messages: [Message(id: 'old', text: 'Old result', time: '')], total: 1));
    await tester.pumpAndSettle();
    expect(find.text('Old result'), findsNothing);
    await tester.tap(find.text(S.uz.chats.loadMoreResults));
    await tester.pumpAndSettle();
    expect(source.searches.last, ('new', 'next'));
    expect(find.descendant(of: find.byType(ChatSearch), matching: find.byType(ListTile)), findsNWidgets(2));
    await tester.enterText(input, '');
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pumpAndSettle();
    expect(find.descendant(of: find.byType(ChatSearch), matching: find.byType(ListTile)), findsNothing);
  });

  testWidgets('search offers retry and no-results states without leaving the chat', (tester) async {
    var fail = true;
    final source = _Source()
      ..search = (_, __) async {
        if (fail) throw StateError('offline');
        return const MessageSearchPage(messages: [], total: 0);
      };
    await _pump(tester, source, narrow: true);
    await tester.tap(find.byTooltip(S.uz.chats.searchInChat));
    await tester.pumpAndSettle();
    final input = find.descendant(of: find.byType(ChatSearch), matching: find.byType(TextField));
    await tester.enterText(input, 'missing');
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pumpAndSettle();
    expect(find.text(S.uz.chats.searchFailed), findsOneWidget);
    fail = false;
    await tester.tap(find.text(S.uz.common.retry));
    await tester.pumpAndSettle();
    expect(find.text(S.uz.chats.noSearchResults), findsOneWidget);
    expect(find.text(S.uz.chats.searchFailed), findsNothing);
    await tester.tap(find.byTooltip(S.uz.chats.emoji));
    await tester.pumpAndSettle();
    expect(find.byType(ChatSearch), findsNothing, reason: 'small windows keep room for the composer');
    expect(tester.takeException(), isNull);
  });
}

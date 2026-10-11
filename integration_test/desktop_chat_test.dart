import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:media_kit/media_kit.dart';
import 'package:window_manager/window_manager.dart';
import 'package:fokus/auth/auth.dart';
import 'package:fokus/auth/mock_auth.dart';
import 'package:fokus/data/account_storage.dart';
import 'package:fokus/data/chat_source.dart';
import 'package:fokus/data/local_store.dart';
import 'package:fokus/data/mock_source.dart';
import 'package:fokus/data/models.dart';
import 'package:fokus/main.dart';
import 'package:fokus/state/app_state.dart';
import 'package:fokus/state/settings.dart';
import 'package:fokus/ui/chats/chat_search.dart';
import 'package:fokus/ui/chats/chat_view.dart';
import 'package:fokus/ui/shell.dart';
import 'package:fokus/l10n/l10n.dart';

// Synthetic accounts use real SQLite files in a new temporary directory.
// This harness never calls TdAuth, loads settings, or initializes notifications.
class _DesktopAuth extends MockAuth {
  _DesktopAuth(this.root);
  final Directory root;
  final status = ValueNotifier(const AuthState(AuthStep.ready));
  String account = '11';
  final sessions = <_NativeSession>[];

  @override
  ValueListenable<AuthState> get state => status;

  void switchTo(String id) {
    status.value = const AuthState(AuthStep.loggingOut);
    account = id;
    status.value = const AuthState(AuthStep.ready);
  }

  @override
  Future<ChatSession> openSession() async {
    final storage = AccountStorage(root, account);
    final db = await storage.open();
    final session = _NativeSession(
      source: MockChatSource(),
      store: await LocalStore.openDb(db),
      db: db,
      accountStorage: storage,
    );
    sessions.add(session);
    return session;
  }
}

class _NativeSession extends ChatSession {
  _NativeSession(
      {required super.source,
      required super.store,
      required super.db,
      required super.accountStorage})
      : super(initialChatId: 'dilshod');
  Future<void>? _closing;
  @override
  Future<void> close() => _closing ??= super.close();
}

Finder get _composer => find
    .descendant(of: find.byType(ChatView), matching: find.byType(TextField))
    .last;
AppState _state(WidgetTester tester) =>
    tester.widget<Shell>(find.byType(Shell)).state;

Future<void> _settleAccount(WidgetTester tester) async {
  for (var i = 0; i < 100; i++) {
    await tester.pump(const Duration(milliseconds: 50));
    if (find.byType(Shell).evaluate().isNotEmpty &&
        _state(tester).tasks.loaded) {
      await tester.pumpAndSettle();
      return;
    }
  }
  fail('The account session did not open');
}

Future<void> _mount(WidgetTester tester, _DesktopAuth auth) async {
  addTearDown(() async {
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
    for (final session in auth.sessions) {
      await session.close();
    }
    auth.status.dispose();
  });
  await tester.pumpWidget(
      FokusApp(settings: Settings.inMemory(ThemeMode.light), auth: auth));
  await _settleAccount(tester);
}

Future<void> _menu(WidgetTester tester, String text) async {
  await tester.tap(find.text(text).last, buttons: kSecondaryButton);
  await tester.pumpAndSettle();
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  late Directory root;
  setUpAll(() async {
    MediaKit.ensureInitialized();
    await windowManager.ensureInitialized();
    await windowManager.waitUntilReadyToShow(
      const WindowOptions(
          title: 'Focus',
          size: Size(1200, 780),
          minimumSize: Size(420, 560),
          titleBarStyle: TitleBarStyle.hidden),
      () async {
        await windowManager.show();
        await windowManager.focus();
      },
    );
    root = await Directory.systemTemp.createTemp('focus_native_chat_test_');
  });
  tearDownAll(() async {
    // Only the directory allocated by this test is ever removed.
    final expected = '${Directory.systemTemp.absolute.path}${Platform.pathSeparator}focus_native_chat_test_';
    if (!root.absolute.path.startsWith(expected)) throw StateError('Unexpected test data directory');
    await root.delete(recursive: true);
  });

  testWidgets(
      'native SQLite account switch A → B → A preserves owned data and reply drafts',
      (tester) async {
    final auth = _DesktopAuth(root);
    await _mount(tester, auth);
    final a = _state(tester);
    await a.tasks.add(title: 'Synthetic A task');
    a.setDraft('dilshod', 'Synthetic A draft');
    a.setReply(
        'dilshod',
        const ReplyInfo(
            chatId: 'dilshod',
            messageId: 'original-A',
            author: 'A',
            text: 'A question'));
    await a.store.flush();

    auth.switchTo('22');
    await _settleAccount(tester);
    final b = _state(tester);
    expect(b.tasks.all, isEmpty);
    expect(b.store.draftOf('dilshod'), isEmpty);
    expect(b.replyOf('dilshod'), isNull);
    expect(find.text('Synthetic A draft'), findsNothing);
    await b.tasks.add(title: 'Synthetic B task');
    b.setDraft('dilshod', 'Synthetic B draft');
    await b.store.flush();

    auth.switchTo('11');
    await _settleAccount(tester);
    final restored = _state(tester);
    expect(restored.tasks.all.single.title, 'Synthetic A task');
    expect(restored.store.draftOf('dilshod'), 'Synthetic A draft');
    expect(restored.replyOf('dilshod')!.messageId, 'original-A');
    expect(find.text('Synthetic B draft'), findsNothing);

    auth.switchTo('22');
    await _settleAccount(tester);
    expect(_state(tester).tasks.all.single.title, 'Synthetic B task');
    expect(_state(tester).store.draftOf('dilshod'), 'Synthetic B draft');
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
  });

  testWidgets(
      'native reply, multiline Enter and attributed forward use the selected chat',
      (tester) async {
    final auth = _DesktopAuth(await root.createTemp('interactions_'));
    await _mount(tester, auth);
    final state = _state(tester);
    final original = state.source.messagesOf('dilshod').last;
    await _menu(tester, original.text);
    await tester.tap(find.text(S.uz.chats.replyMessage));
    await tester.pumpAndSettle();
    await tester.enterText(_composer, 'Synthetic reply');
    state.openChat('madina');
    await tester.pumpAndSettle();
    expect(find.byTooltip(S.uz.chats.cancelReply), findsNothing);
    state.openChat('dilshod');
    await tester.pumpAndSettle();
    expect(find.byTooltip(S.uz.chats.cancelReply), findsOneWidget);
    await tester.tap(_composer);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
    await tester.pumpAndSettle();
    expect(state.source.messagesOf('dilshod').last.id, original.id);
    await tester.enterText(_composer, 'Synthetic reply\nSecond line');
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    final reply = state.source.messagesOf('dilshod').last;
    expect(reply.text, 'Synthetic reply\nSecond line');
    expect(reply.reply!.messageId, original.id);
    expect(find.byTooltip(S.uz.chats.cancelReply), findsNothing);

    await _menu(tester, reply.text);
    await tester.tap(find.text(S.uz.chats.forwardMessage));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ListTile, 'Madina Rahimova'));
    await tester.pumpAndSettle();
    expect(state.activeChatId, 'dilshod');
    await tester.tap(find.widgetWithText(FilledButton, S.uz.common.send));
    await tester.pumpAndSettle();
    expect(state.activeChatId, 'madina');
    final forwarded = state.source.messagesOf('madina').last;
    expect(forwarded.text, reply.text);
    expect(forwarded.forwardedFrom, isNotNull);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
  });

  testWidgets('native Ctrl+F search jumps, navigates and closes with Escape',
      (tester) async {
    final auth = _DesktopAuth(await root.createTemp('search_'));
    await _mount(tester, auth);
    await tester.tap(_composer);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyF);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pumpAndSettle();
    expect(find.byType(ChatSearch), findsOneWidget);
    final search = find.descendant(
        of: find.byType(ChatSearch), matching: find.byType(TextField));
    await tester.enterText(search, 'PDF');
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pumpAndSettle();
    final results = find.descendant(
        of: find.byType(ChatSearch), matching: find.byType(ListTile));
    expect(results, findsNWidgets(2));
    await tester.tap(results.first);
    await tester.pumpAndSettle();
    expect(find.text('1/2'), findsOneWidget);
    await tester.tap(find.byTooltip(S.uz.chats.olderResult));
    await tester.pumpAndSettle();
    expect(find.text('2/2'), findsOneWidget);
    await tester.tap(find.byTooltip(S.uz.chats.newerResult));
    await tester.pumpAndSettle();
    expect(find.text('1/2'), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.byType(ChatSearch), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
  });
}

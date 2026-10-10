import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fokus/auth/auth.dart';
import 'package:fokus/auth/mock_auth.dart';
import 'package:fokus/data/account_storage.dart';
import 'package:fokus/data/chat_source.dart';
import 'package:fokus/data/local_store.dart';
import 'package:fokus/data/mock_source.dart';
import 'package:fokus/main.dart';
import 'package:fokus/reminders/reminder_service.dart';
import 'package:fokus/state/settings.dart';
import 'package:fokus/ui/shell.dart';
import 'package:fokus/state/app_state.dart';
import 'package:fokus/db/database.dart';
import 'package:fokus/l10n/l10n.dart';

import 'helpers/fonts.dart';

class _Auth extends MockAuth {
  final status = ValueNotifier(const AuthState(AuthStep.ready));
  final pending = <Completer<ChatSession>>[];
  int calls = 0;
  @override
  ValueListenable<AuthState> get state => status;
  @override
  Future<ChatSession> openSession() {
    calls++;
    return pending.removeAt(0).future;
  }
}

class _Storage extends AccountStorage {
  _Storage(String id) : super(Directory.systemTemp, id);
  @override
  Future<bool> get offerLegacyImport async => false;
}

class _LegacyStorage extends _Storage {
  _LegacyStorage() : super('22');
  bool imported = false;
  bool kept = false;
  @override
  Future<bool> get offerLegacyImport async => !imported && !kept;
  @override
  Future<void> importLegacy(AppDatabase target) async {
    imported = true;
  }

  @override
  Future<void> keepLegacySeparate() async {
    kept = true;
  }
}

ChatSession _session(String id) {
  final store = LocalStore.memory()..setDraft('dilshod', 'Account $id draft');
  return ChatSession(source: MockChatSource(), store: store, initialChatId: 'dilshod', accountStorage: _Storage(id));
}

Future<void> _pump(WidgetTester tester, _Auth auth, {FakeNotifier? notifier}) async {
  tester.view.physicalSize = const Size(1200, 800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  addTearDown(() async {
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
  });
  await tester.pumpWidget(FokusApp(settings: Settings.inMemory(), auth: auth, notifier: notifier));
  await tester.pump();
}

void main() {
  setUpAll(loadSegoeUi);
  testWidgets('switching accounts during open discards the old session and opens the current one', (tester) async {
    final first = Completer<ChatSession>();
    final second = Completer<ChatSession>();
    final auth = _Auth()..pending.addAll([first, second]);
    await _pump(tester, auth);
    auth.status.value = const AuthState(AuthStep.loggingOut);
    auth.status.value = const AuthState(AuthStep.ready);
    first.complete(_session('11'));
    await tester.pump();
    expect(find.byType(Shell), findsNothing, reason: 'account A must never flash in account B');
    expect(auth.calls, 2);
    final current = _session('22');
    second.complete(current);
    await tester.pumpAndSettle();
    expect(tester.widget<Shell>(find.byType(Shell)).state.store, same(current.store));
    expect(find.text('Account 11 draft'), findsNothing);
  });

  testWidgets('opening failure stays closed and retry opens a fresh session', (tester) async {
    final first = Completer<ChatSession>();
    final second = Completer<ChatSession>();
    final auth = _Auth()..pending.addAll([first, second]);
    await _pump(tester, auth);
    first.completeError(StateError('local data unavailable'));
    await tester.pumpAndSettle();
    expect(find.byType(Shell), findsNothing);
    expect(find.text('Qayta urinish'), findsOneWidget);
    await tester.tap(find.text('Qayta urinish'));
    await tester.pump();
    second.complete(_session('22'));
    await tester.pumpAndSettle();
    expect(find.byType(Shell), findsOneWidget);
  });

  testWidgets('old account notification links cannot navigate the new session', (tester) async {
    final pending = Completer<ChatSession>();
    final auth = _Auth()..pending.add(pending);
    final notifier = FakeNotifier();
    await _pump(tester, auth, notifier: notifier);
    pending.complete(_session('22'));
    await tester.pumpAndSettle();
    final state = tester.widget<Shell>(find.byType(Shell)).state;
    notifier.tap('account:11:task:1');
    await tester.pumpAndSettle();
    expect(state.module, Module.chats);
    notifier.tap('task:1');
    await tester.pumpAndSettle();
    expect(state.module, Module.chats);
    notifier.tap('account:22:task:1');
    await tester.pumpAndSettle();
    expect(state.module, Module.tasks);
  });

  for (final import in [true, false]) {
    testWidgets('legacy data stays hidden until an explicit choice (import=$import)', (tester) async {
      final pending = Completer<ChatSession>();
      final auth = _Auth()..pending.add(pending);
      final storage = _LegacyStorage();
      await _pump(tester, auth);
      pending.complete(ChatSession(source: MockChatSource(), store: LocalStore.memory(), accountStorage: storage));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text(S.uz.auth.legacyTitle), findsOneWidget);
      expect(find.byType(Shell), findsNothing);
      expect(storage.imported, isFalse);
      expect(storage.kept, isFalse);
      await tester.tap(find.text(import ? S.uz.auth.importLegacy : S.uz.auth.keepSeparate));
      await tester.pumpAndSettle();
      expect(storage.imported, import);
      expect(storage.kept, !import);
      expect(find.byType(Shell), findsOneWidget);
    });
  }
}

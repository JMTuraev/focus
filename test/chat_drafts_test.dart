import 'dart:async';
import 'dart:io';

import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fokus/data/local_store.dart';
import 'package:fokus/data/mock_source.dart';
import 'package:fokus/data/models.dart';
import 'package:fokus/state/app_state.dart';
import 'package:fokus/theme.dart';
import 'package:fokus/ui/chats/chats_screen.dart';
import 'package:fokus/ui/chats/chat_view.dart';
import 'package:fokus/ui/chats/send_files_dialog.dart';
import 'package:fokus/ui/layout.dart';

import 'helpers/fonts.dart';

class _DelayedSource extends MockChatSource {
  final sends = <(String, String)>[];
  final fileSends = <(String, String)>[];
  Completer<void>? pendingSend;
  Completer<void>? pendingFiles;

  @override
  Future<void> send(String chatId, String text) async {
    sends.add((chatId, text));
    await pendingSend?.future;
  }

  @override
  Future<void> sendFiles(String chatId, List<OutgoingFile> files, {String caption = '', bool compressImages = true}) async {
    fileSends.add((chatId, caption));
    await pendingFiles?.future;
  }
}

Finder get _input => find.descendant(of: find.byType(ChatView), matching: find.byType(TextField));
String _text(WidgetTester tester) => tester.widget<TextField>(_input).controller!.text;

Future<AppState> _pump(WidgetTester tester, _DelayedSource source, {bool dark = false, bool narrow = false}) async {
  tester.view.physicalSize = narrow ? const Size(420, 560) : const Size(1440, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final state = AppState(source: source, store: LocalStore.memory(), initialChatId: 'dilshod');
  state.openChat('dilshod');
  addTearDown(() async {
    await tester.pumpWidget(const SizedBox());
    state.dispose();
    source.dispose();
  });
  await tester.pumpWidget(MaterialApp(
    theme: buildTheme(dark ? Brightness.dark : Brightness.light),
    home: Scaffold(body: ListenableBuilder(
      listenable: state,
      builder: (context, _) => ChatsScreen(state: state, mode: narrow ? LayoutMode.narrow : LayoutMode.wide),
    )),
  ));
  await tester.pumpAndSettle();
  return state;
}

Future<void> _drop(WidgetTester tester) async {
  final dir = Directory.systemTemp.createTempSync('focus_draft_test');
  addTearDown(() => dir.deleteSync(recursive: true));
  final file = File('${dir.path}/report.pdf')..writeAsStringSync('local test');
  tester.widget<DropTarget>(find.byType(DropTarget)).onDragDone!(DropDoneDetails(
    files: [DropItemFile(file.path)],
    localPosition: Offset.zero,
    globalPosition: Offset.zero,
  ));
  await tester.pumpAndSettle();
  expect(find.byType(SendFilesDialog), findsOneWidget);
}

void main() {
  setUpAll(loadSegoeUi);

  for (final narrow in [false, true]) {
    testWidgets('drafts follow their chat across switching and remounting (narrow=$narrow)', (tester) async {
      final state = await _pump(tester, _DelayedSource(), narrow: narrow, dark: narrow);
      await tester.enterText(_input, 'Birinchi mijoz 😀');
      state.openChat('madina');
      await tester.pumpAndSettle();
      expect(_text(tester), '');
      await tester.enterText(_input, 'Ikkinchi mijoz');
      state.openChat('dilshod');
      await tester.pumpAndSettle();
      expect(_text(tester), 'Birinchi mijoz 😀');
      if (narrow) {
        state.closeChat();
        await tester.pumpAndSettle();
        expect(find.text('Qoralama: Birinchi mijoz 😀'), findsOneWidget);
        state.openChat('dilshod');
        await tester.pumpAndSettle();
        expect(_text(tester), 'Birinchi mijoz 😀');
      }
      expect(state.draftOf('madina'), 'Ikkinchi mijoz');
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('a failed send restores the original chat draft after switching', (tester) async {
    final source = _DelayedSource()..pendingSend = Completer<void>();
    final state = await _pump(tester, source);
    await tester.enterText(_input, 'Birinchi xabar');
    await tester.tap(find.byTooltip('Yuborish'));
    await tester.pump();
    expect(source.sends, [('dilshod', 'Birinchi xabar')]);
    expect(_text(tester), '');
    state.openChat('madina');
    await tester.pumpAndSettle();
    await tester.enterText(_input, 'Madina qoralamasi');
    source.pendingSend!.completeError(Exception('offline'));
    await tester.pumpAndSettle();
    expect(_text(tester), 'Madina qoralamasi');
    state.openChat('dilshod');
    await tester.pumpAndSettle();
    expect(_text(tester), 'Birinchi xabar');
    expect(tester.takeException(), isNull);
  });

  testWidgets('a stale composer cannot send into a newly selected chat before rebuild', (tester) async {
    final source = _DelayedSource();
    final state = await _pump(tester, source);
    await tester.enterText(_input, 'Birinchi xabar');
    state.openChat('madina');
    // Invoke the still-rendered button before the scheduled frame.
    tester.widget<IconButton>(find.ancestor(
      of: find.byIcon(Icons.send_rounded),
      matching: find.byType(IconButton),
    )).onPressed!();
    await tester.pumpAndSettle();
    expect(source.sends, isEmpty);
    expect(_text(tester), '');
    expect(state.draftOf('dilshod'), 'Birinchi xabar');
    expect(tester.takeException(), isNull);
  });

  testWidgets('a delayed send failure never overwrites newer typing', (tester) async {
    final source = _DelayedSource()..pendingSend = Completer<void>();
    await _pump(tester, source);
    await tester.enterText(_input, 'Yuborilgan');
    await tester.tap(find.byTooltip('Yuborish'));
    await tester.pump();
    await tester.enterText(_input, 'Yangi qoralama');
    source.pendingSend!.completeError(Exception('offline'));
    await tester.pumpAndSettle();
    expect(_text(tester), 'Yangi qoralama');
    expect(tester.takeException(), isNull);
  });

  testWidgets('typing and clearing after send invalidates the old failed draft', (tester) async {
    final source = _DelayedSource()..pendingSend = Completer<void>();
    await _pump(tester, source);
    await tester.enterText(_input, 'Eski xabar');
    await tester.tap(find.byTooltip('Yuborish'));
    await tester.pump();
    await tester.enterText(_input, 'Yangi matn');
    await tester.enterText(_input, '');
    source.pendingSend!.completeError(Exception('offline'));
    await tester.pumpAndSettle();
    expect(_text(tester), '');
    expect(tester.takeException(), isNull);
  });

  testWidgets('editing and cancelling restores the existing draft', (tester) async {
    final state = await _pump(tester, _DelayedSource());
    await tester.enterText(_input, 'Keyingi xabar');
    final own = state.messagesOf('dilshod').firstWhere((m) => m.out);
    await tester.tap(find.text(own.text).last, buttons: kSecondaryButton);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tahrirlash'));
    await tester.pumpAndSettle();
    await tester.enterText(_input, 'Tahrir matni');
    expect(state.draftOf('dilshod'), 'Keyingi xabar');
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(_text(tester), 'Keyingi xabar');
    expect(tester.takeException(), isNull);
  });

  testWidgets('switching chats during editing keeps both drafts isolated', (tester) async {
    final state = await _pump(tester, _DelayedSource());
    await tester.enterText(_input, 'Keyingi xabar');
    final own = state.messagesOf('dilshod').firstWhere((m) => m.out);
    await tester.tap(find.text(own.text).last, buttons: kSecondaryButton);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tahrirlash'));
    await tester.pumpAndSettle();
    await tester.enterText(_input, 'Tahrir matni');
    state.openChat('madina');
    await tester.pumpAndSettle();
    expect(_text(tester), '');
    expect(find.byTooltip('Tahrirlashni bekor qilish (Esc)'), findsNothing);
    state.openChat('dilshod');
    await tester.pumpAndSettle();
    expect(_text(tester), 'Keyingi xabar');
    expect(tester.takeException(), isNull);
  });

  testWidgets('Enter sends multiline text and Shift Enter keeps composing', (tester) async {
    final source = _DelayedSource();
    await _pump(tester, source, narrow: true);
    await tester.enterText(_input, 'Birinchi satr\nIkkinchi satr');
    await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
    await tester.pump();
    expect(source.sends, isEmpty);
    expect(tester.widget<TextField>(_input).maxLines, 5);
    await tester.enterText(_input, 'Birinchi satr\nIkkinchi satr\nUchinchi satr');
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(source.sends, [('dilshod', 'Birinchi satr\nIkkinchi satr\nUchinchi satr')]);
    expect(_text(tester), '');
    expect(tester.takeException(), isNull);
  });

  testWidgets('Enter does not send while an IME composition is active', (tester) async {
    final source = _DelayedSource();
    await _pump(tester, source);
    await tester.enterText(_input, 'Salom');
    tester.widget<TextField>(_input).controller!.value = const TextEditingValue(
      text: 'Salom',
      selection: TextSelection.collapsed(offset: 5),
      composing: TextRange(start: 0, end: 5),
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    expect(source.sends, isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets('file dialog cancels the send if the active chat changes', (tester) async {
    final source = _DelayedSource();
    final state = await _pump(tester, source);
    await tester.enterText(_input, 'Birinchi caption');
    await _drop(tester);
    state.openChat('madina');
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Yuborish'));
    await tester.pumpAndSettle();
    expect(source.fileSends, isEmpty);
    expect(state.draftOf('dilshod'), 'Birinchi caption');
    expect(_text(tester), '');
    expect(tester.takeException(), isNull);
  });

  testWidgets('file failure preserves caption and success leaves newer typing intact', (tester) async {
    final source = _DelayedSource()..pendingFiles = Completer<void>();
    final state = await _pump(tester, source);
    await tester.enterText(_input, 'Caption');
    await _drop(tester);
    await tester.enterText(find.descendant(of: find.byType(SendFilesDialog), matching: find.byType(TextField)), 'Yangilangan caption');
    await tester.tap(find.widgetWithText(FilledButton, 'Yuborish'));
    await tester.pumpAndSettle();
    expect(source.fileSends, [('dilshod', 'Yangilangan caption')]);
    source.pendingFiles!.completeError(Exception('offline'));
    await tester.pumpAndSettle();
    expect(_text(tester), 'Yangilangan caption');

    source.pendingFiles = Completer<void>();
    await _drop(tester);
    await tester.tap(find.widgetWithText(FilledButton, 'Yuborish'));
    await tester.pumpAndSettle();
    await tester.enterText(_input, 'Keyingi caption');
    source.pendingFiles!.complete();
    await tester.pumpAndSettle();
    expect(state.draftOf('dilshod'), 'Keyingi caption');
    expect(_text(tester), 'Keyingi caption');
    expect(tester.takeException(), isNull);
  });

  testWidgets('successful file send clears only its original draft after switching', (tester) async {
    final source = _DelayedSource()..pendingFiles = Completer<void>();
    final state = await _pump(tester, source);
    await tester.enterText(_input, 'Caption');
    await _drop(tester);
    await tester.tap(find.widgetWithText(FilledButton, 'Yuborish'));
    await tester.pumpAndSettle();
    state.openChat('madina');
    await tester.pumpAndSettle();
    await tester.enterText(_input, 'Madina caption');
    source.pendingFiles!.complete();
    await tester.pumpAndSettle();
    expect(source.fileSends, [('dilshod', 'Caption')]);
    expect(state.draftOf('dilshod'), '');
    expect(_text(tester), 'Madina caption');
    expect(tester.takeException(), isNull);
  });
}

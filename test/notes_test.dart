// Notes: store, v2 → v3 migration, the notes screen, editor and chat link.
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fokus/auth/mock_auth.dart';
import 'package:fokus/data/chat_source.dart';
import 'package:fokus/data/local_store.dart';
import 'package:fokus/data/mock_source.dart';
import 'package:fokus/db/database.dart';
import 'package:fokus/main.dart';
import 'package:fokus/notes/note_store.dart';
import 'package:fokus/state/settings.dart';
import 'package:fokus/ui/notes/notes_screen.dart';
import 'package:fokus/ui/rail.dart';
import 'package:sqlite3/sqlite3.dart';

import 'helpers/fonts.dart';

class _DbAuth extends MockAuth {
  _DbAuth(this.db) : super(loggedIn: true, delay: Duration.zero);

  final AppDatabase db;

  @override
  Future<ChatSession> openSession() async =>
      ChatSession(source: MockChatSource(), store: LocalStore.memory(), db: db, initialChatId: 'dilshod');
}

Future<AppDatabase> _seeded() async {
  final db = AppDatabase.memory();
  final notes = NoteStore(db);
  await notes.add(title: 'Uchrashuv uchun', body: 'Narxlar jadvali\nShartnoma namunasi', color: NoteColor.yellow, pinned: true);
  await notes.add(title: 'Xaridlar', checklist: true, items: const [NoteItem('Qog‘oz'), NoteItem('Printer kartriji', done: true)]);
  await notes.add(body: 'Narxlarni PDF’da yuboring, iltimos', chatId: 'dilshod', chatTitle: 'Dilshod Karimov');
  notes.dispose();
  return db;
}

Future<void> _pump(WidgetTester tester, AppDatabase db, {Size size = const Size(1440, 900), bool dark = false}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(FokusApp(settings: Settings.inMemory(dark ? ThemeMode.dark : ThemeMode.light), auth: _DbAuth(db)));
  await tester.pumpAndSettle();
}

Future<void> _openNotes(WidgetTester tester) async {
  await tester.tap(find.descendant(of: find.byType(Rail), matching: find.byIcon(Icons.sticky_note_2_outlined)), warnIfMissed: false);
  await tester.pumpAndSettle();
}

Future<List<Note>> _rows(AppDatabase db) => db.select(db.notes).get();

void main() {
  setUpAll(loadSegoeUi);

  group('NoteStore', () {
    late AppDatabase db;
    late NoteStore store;
    setUp(() async {
      db = AppDatabase.memory();
      store = NoteStore(db);
      await Future<void>.delayed(Duration.zero);
    });
    tearDown(() async {
      store.dispose();
      await db.close();
    });

    test('pinned first, then most recently edited; filters and search', () async {
      final a = await store.add(title: 'A');
      await store.add(title: 'B', checklist: true, items: const [NoteItem('sut'), NoteItem('  '), NoteItem(' non ')]);
      await store.add(body: 'chatdan', chatId: '5', chatTitle: 'Sardor');
      await store.edit(a, pinned: true);
      expect(store.all.first.title, 'A');

      // (Times are stored with 1 s precision, so edits within the same second
      // are ordered by id; not asserted here.)
      await store.edit(a, pinned: false, body: 'yangilandi');

      final b = store.all.firstWhere((n) => n.title == 'B');
      expect(b.items, const [NoteItem('sut'), NoteItem('non')], reason: 'empty items dropped, text trimmed');
      expect(store.filtered(filter: NoteFilter.checklists).map((n) => n.title), ['B']);
      expect(store.filtered(filter: NoteFilter.fromChats).single.body, 'chatdan');
      expect(store.filtered(query: 'NON').single.title, 'B', reason: 'search finds checklist items');
      expect(store.filtered(query: 'sardor').single.body, 'chatdan', reason: 'and chat names');
      expect(store.countForChat('5'), 1);
    });

    test('toggle items, convert text and checklist, remove and restore', () async {
      final id = await store.add(checklist: true, items: const [NoteItem('bir'), NoteItem('ikki')]);
      await store.toggleItem(id, 1);
      expect(store.byId(id)!.items[1].done, isTrue);

      final (body, none) = NoteStore.convert(toChecklist: false, body: '', items: store.byId(id)!.items);
      expect(body, 'bir\nikki');
      expect(none, isEmpty);
      final (_, items) = NoteStore.convert(toChecklist: true, body: 'a\n\n b \nc', items: const []);
      expect(items, const [NoteItem('a'), NoteItem('b'), NoteItem('c')]);

      final n = store.byId(id)!;
      await store.remove(id);
      expect(store.byId(id), isNull);
      await store.restore(n);
      expect(store.byId(id)!.items.length, 2);
    });

    test('checklist JSON survives a round trip', () {
      const conv = NoteItemsConverter();
      const items = [NoteItem('“Qo‘shtirnoq”, emoji 🎉'), NoteItem('done', done: true)];
      expect(conv.fromSql(conv.toSql(items)), items);
      expect(conv.fromSql('not json'), isEmpty);
    });
  });

  test('a v2 database (tasks, events) is upgraded and keeps its data', () async {
    final dir = Directory.systemTemp.createTempSync('fokus_migrate3');
    addTearDown(() => dir.deleteSync(recursive: true));
    final file = File('${dir.path}${Platform.pathSeparator}fokus.sqlite');

    final probe = AppDatabase.memory();
    final create = <String>[
      for (final t in ['tasks', 'events'])
        (await probe.customSelect("SELECT sql FROM sqlite_master WHERE name = '$t'").getSingle()).read<String>('sql'),
    ];
    await probe.close();
    final raw = sqlite3.open(file.path);
    for (final s in create) {
      raw.execute(s);
    }
    raw
      ..execute('INSERT INTO events (title, note, start, "end", all_day, created_at, updated_at) '
          "VALUES ('Eski uchrashuv', '', 0, 3600, 0, 0, 0)")
      ..execute('PRAGMA user_version = 2');
    raw.close();

    final db = AppDatabase(NativeDatabase(file));
    final notes = NoteStore(db);
    await notes.add(title: 'Yangi');
    expect(notes.all.single.title, 'Yangi');
    expect((await db.select(db.events).get()).single.title, 'Eski uchrashuv');
    notes.dispose();
    await db.close();
  });

  for (final dark in [false, true]) {
    for (final size in const [Size(1440, 900), Size(800, 600), Size(420, 560)]) {
      testWidgets('notes lay out at ${size.width.toInt()}x${size.height.toInt()} ${dark ? 'dark' : 'light'}', (tester) async {
        await _pump(tester, await _seeded(), size: size, dark: dark);
        await _openNotes(tester);
        expect(find.byType(NotesScreen), findsOneWidget);
        expect(find.text('QADALGAN'), findsOneWidget);
        expect(find.text('Uchrashuv uchun'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets('new note saves on "Tayyor"; an empty one is dropped', (tester) async {
    final db = AppDatabase.memory();
    await _pump(tester, db);
    await _openNotes(tester);
    expect(find.textContaining('Hali eslatma yo‘q'), findsOneWidget);

    await tester.tap(find.text('Yangi eslatma'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tayyor'));
    await tester.pumpAndSettle();
    expect(await _rows(db), isEmpty);

    await tester.tap(find.text('Yangi eslatma'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).at(1), 'Telefon raqamlar');
    await tester.enterText(find.byType(TextField).at(2), 'Bank: 1234');
    await tester.tap(find.text('Tayyor'));
    await tester.pumpAndSettle();
    expect(find.text('Telefon raqamlar'), findsOneWidget);
    expect((await _rows(db)).single.body, 'Bank: 1234');
  });

  testWidgets('closing with Escape saves the changes', (tester) async {
    final db = await _seeded();
    await _pump(tester, db);
    await _openNotes(tester);
    await tester.tap(find.text('Uchrashuv uchun'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).at(1), 'Uchrashuv uchun (yangilandi)');
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.text('Uchrashuv uchun (yangilandi)'), findsOneWidget);
  });

  testWidgets('checklist: Enter adds a line, tick on the card', (tester) async {
    final db = AppDatabase.memory();
    await _pump(tester, db);
    await _openNotes(tester);
    await tester.tap(find.text('Yangi ro‘yxat'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, 'Sut');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, 'Non');
    await tester.tap(find.text('Tayyor'));
    await tester.pumpAndSettle();

    final note = (await _rows(db)).single;
    expect(note.checklist, isTrue);
    expect(note.items.map((i) => i.text), ['Sut', 'Non']);

    await tester.tap(find.text('Non'));
    await tester.pumpAndSettle();
    expect((await _rows(db)).single.items.last.done, isTrue);
  });

  testWidgets('pin, color and delete with undo from the card menu', (tester) async {
    final db = await _seeded();
    await _pump(tester, db);
    await _openNotes(tester);

    await tester.tap(find.text('Xaridlar'), buttons: kSecondaryButton);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Qadash'));
    await tester.pumpAndSettle();
    expect((await _rows(db)).firstWhere((n) => n.title == 'Xaridlar').pinned, isTrue);

    await tester.tap(find.text('Xaridlar'), buttons: kSecondaryButton);
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Ko‘k'));
    await tester.pumpAndSettle();
    expect((await _rows(db)).firstWhere((n) => n.title == 'Xaridlar').color, NoteColor.blue);

    await tester.tap(find.text('Xaridlar'), buttons: kSecondaryButton);
    await tester.pumpAndSettle();
    await tester.tap(find.text('O‘chirish'));
    await tester.pumpAndSettle();
    expect(find.text('Xaridlar'), findsNothing);
    await tester.tap(find.text('Qaytarish'));
    await tester.pumpAndSettle();
    expect(find.text('Xaridlar'), findsOneWidget);
  });

  testWidgets('"Eslatmaga" saves the message; the info panel opens the chat\'s notes', (tester) async {
    final db = AppDatabase.memory();
    await _pump(tester, db);
    await tester.tap(find.text('Eslatmaga'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Eslatmaga saqlandi'), findsOneWidget);
    final saved = (await _rows(db)).single;
    expect(saved.chatId, 'dilshod');
    expect(saved.body, contains('Narxlarni PDF’da yuboring'));

    await tester.tap(find.text('Eslatmalar').last);
    await tester.pumpAndSettle();
    expect(find.byType(NotesScreen), findsOneWidget);
    expect(find.text('Faqat: Dilshod Karimov'), findsOneWidget);
    expect(find.descendant(of: find.byType(NotesScreen), matching: find.textContaining('Narxlarni PDF’da')), findsOneWidget);
  });

  testWidgets('text note turns into a checklist in the editor', (tester) async {
    final db = AppDatabase.memory();
    await NoteStore(db).add(body: 'bir\nikki');
    await _pump(tester, db);
    await _openNotes(tester);
    await tester.tap(find.textContaining('bir'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Ro‘yxatga aylantirish'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tayyor'));
    await tester.pumpAndSettle();
    final n = (await _rows(db)).single;
    expect(n.checklist, isTrue);
    expect(n.items.map((i) => i.text), ['bir', 'ikki']);
  });
}

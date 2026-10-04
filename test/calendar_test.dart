// Calendar: event store, overlap layout, v1 → v2 migration, the grid and
// adding meetings from chats.
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fokus/auth/mock_auth.dart';
import 'package:fokus/calendar/event_store.dart';
import 'package:fokus/data/chat_source.dart';
import 'package:fokus/data/local_store.dart';
import 'package:fokus/data/mock_source.dart';
import 'package:fokus/db/database.dart';
import 'package:fokus/main.dart';
import 'package:fokus/state/settings.dart';
import 'package:fokus/tasks/task_store.dart';
import 'package:fokus/ui/calendar/calendar_screen.dart';
import 'package:fokus/ui/calendar/time_grid.dart';
import 'package:fokus/ui/rail.dart';
import 'package:sqlite3/sqlite3.dart';

import 'helpers/fonts.dart';

DateTime _today() => EventStore.day(DateTime.now());

class _DbAuth extends MockAuth {
  _DbAuth(this.db) : super(loggedIn: true, delay: Duration.zero);

  final AppDatabase db;

  @override
  Future<ChatSession> openSession() async =>
      ChatSession(source: MockChatSource(), store: LocalStore.memory(), db: db, initialChatId: 'dilshod');
}

Future<AppDatabase> _seeded() async {
  final db = AppDatabase.memory();
  final events = EventStore(db);
  final t = _today();
  await events.add(title: 'Demo', start: t.add(const Duration(hours: 10)), end: t.add(const Duration(hours: 11)));
  await events.add(title: 'Qo‘ng‘iroq', start: t.add(const Duration(hours: 10, minutes: 30)), end: t.add(const Duration(hours: 11, minutes: 30)));
  await events.add(title: 'Konferensiya', start: t, end: t, allDay: true);
  events.dispose();
  final tasks = TaskStore(db);
  await tasks.add(title: 'Hisobot topshirish', due: t);
  tasks.dispose();
  return db;
}

Future<void> _pump(WidgetTester tester, AppDatabase db, {Size size = const Size(1440, 900), bool dark = false}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(FokusApp(settings: Settings.inMemory(dark ? ThemeMode.dark : ThemeMode.light), auth: _DbAuth(db)));
  await tester.pumpAndSettle();
}

Future<void> _openCalendar(WidgetTester tester) async {
  await tester.tap(find.descendant(of: find.byType(Rail), matching: find.byIcon(Icons.calendar_today_outlined)), warnIfMissed: false);
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(loadSegoeUi);

  group('EventStore', () {
    late AppDatabase db;
    late EventStore store;
    setUp(() async {
      db = AppDatabase.memory();
      store = EventStore(db);
      await Future<void>.delayed(Duration.zero);
    });
    tearDown(() async {
      store.dispose();
      await db.close();
    });

    test('normalizes lengths, finds events by day, reschedules', () async {
      final t = DateTime(2026, 10, 8);
      final a = await store.add(title: 'Qisqa', start: t.add(const Duration(hours: 9)), end: t.add(const Duration(hours: 9)));
      expect(store.byId(a)!.end, t.add(const Duration(hours: 9, minutes: 15)), reason: 'at least 15 minutes');

      final b = await store.add(title: 'Kun bo‘yi', start: t.add(const Duration(hours: 13)), end: t, allDay: true);
      expect(store.byId(b)!.start, t);
      expect(store.byId(b)!.end, t.add(const Duration(days: 1)));

      final late = await store.add(
        title: 'Tunda',
        start: t.add(const Duration(hours: 23)),
        end: t.add(const Duration(days: 1, hours: 1)),
      );
      expect(store.onDay(t).map((e) => e.id), containsAll([a, b, late]));
      expect(store.onDay(t.add(const Duration(days: 1))).map((e) => e.id), [late], reason: 'spans midnight');

      await store.reschedule(a, t.add(const Duration(days: 1, hours: 14)), t.add(const Duration(days: 1, hours: 15)));
      expect(store.onDay(t.add(const Duration(days: 1))).map((e) => e.id), containsAll([a, late]));
    });

    test('per chat, remaining today, edit, remove and restore', () async {
      final now = DateTime.now();
      final soon = now.add(const Duration(minutes: 30));
      final sameDay = EventStore.day(soon) == EventStore.day(now);
      final id = await store.add(title: 'Uchrashuv', start: soon, end: soon.add(const Duration(hours: 1)), chatId: '7');
      await store.add(title: 'O‘tgan', start: now.subtract(const Duration(hours: 3)), end: now.subtract(const Duration(hours: 2)), chatId: '7');
      expect(store.upcomingForChat('7').map((e) => e.id), [id]);
      expect(store.remainingToday(), sameDay ? 1 : 0);

      await store.edit(id, title: 'Yangi nom', start: soon, end: soon.add(const Duration(hours: 2)), allDay: false, note: 'izoh', remindBefore: 10);
      final e = store.byId(id)!;
      expect(e.title, 'Yangi nom');
      expect(e.remindBefore, 10);
      await store.remove(id);
      expect(store.byId(id), isNull);
      await store.restore(e);
      expect(store.byId(id)!.note, 'izoh');
    });
  });

  test('overlapping events share the column', () async {
    final db = AppDatabase.memory();
    final store = EventStore(db);
    final t = DateTime(2026, 10, 8);
    await store.add(title: 'A', start: t.add(const Duration(hours: 10)), end: t.add(const Duration(hours: 11)));
    await store.add(title: 'B', start: t.add(const Duration(hours: 10, minutes: 30)), end: t.add(const Duration(hours: 11, minutes: 30)));
    await store.add(title: 'C', start: t.add(const Duration(hours: 11, minutes: 30)), end: t.add(const Duration(hours: 12)));
    await store.add(title: 'D', start: t.add(const Duration(hours: 14)), end: t.add(const Duration(hours: 15)));
    final placed = {for (final p in layoutDay(store.onDay(t), t)) p.event.title: (p.lane, p.lanes)};
    expect(placed['A'], (0, 2));
    expect(placed['B'], (1, 2));
    expect(placed['C'], (0, 1), reason: 'C starts when B ends: no overlap, full width');
    expect(placed['D'], (0, 1));
    store.dispose();
    await db.close();
  });

  test('a v1 database (tasks only) is upgraded and keeps its tasks', () async {
    final dir = Directory.systemTemp.createTempSync('fokus_migrate');
    addTearDown(() => dir.deleteSync(recursive: true));
    final file = File('${dir.path}${Platform.pathSeparator}fokus.sqlite');

    // The v1 schema exactly as drift creates it.
    final probe = AppDatabase.memory();
    final createTasks = (await probe.customSelect("SELECT sql FROM sqlite_master WHERE name = 'tasks'").getSingle()).read<String>('sql');
    await probe.close();
    final raw = sqlite3.open(file.path)
      ..execute(createTasks)
      ..execute('INSERT INTO tasks (title, note, status, important, position, created_at, updated_at) '
          "VALUES ('Eski vazifa', '', 'planned', 0, 1, 0, 0)")
      ..execute('PRAGMA user_version = 1');
    raw.close();

    final db = AppDatabase(NativeDatabase(file));
    final events = EventStore(db);
    await events.add(title: 'Yangi', start: DateTime(2026, 10, 8, 10), end: DateTime(2026, 10, 8, 11));
    expect(events.all.single.title, 'Yangi');
    final tasks = await db.select(db.tasks).get();
    expect(tasks.single.title, 'Eski vazifa');
    events.dispose();
    await db.close();
  });

  for (final dark in [false, true]) {
    for (final size in const [Size(1440, 900), Size(800, 600), Size(420, 560)]) {
      testWidgets('calendar lays out at ${size.width.toInt()}x${size.height.toInt()} ${dark ? 'dark' : 'light'}', (tester) async {
        await _pump(tester, await _seeded(), size: size, dark: dark);
        await _openCalendar(tester);
        expect(find.byType(CalendarScreen), findsOneWidget);
        expect(find.text('Konferensiya'), findsOneWidget);
        expect(find.text('Hisobot topshirish'), findsOneWidget, reason: 'tasks due today are in the all-day row');
        expect(find.text('Demo'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets('click an empty slot to add, drag to move, stretch to resize', (tester) async {
    final db = AppDatabase.memory();
    await _pump(tester, db, size: const Size(1440, 1000));
    await _openCalendar(tester);
    await tester.tap(find.text('Kun'));
    await tester.pumpAndSettle();

    // The grid starts scrolled to ~07:30 (or an hour before now): click 10:00.
    final grid = find.byType(TimeGrid);
    final scroll = tester.widget<SingleChildScrollView>(find.descendant(of: grid, matching: find.byType(SingleChildScrollView)));
    final offset = scroll.controller!.offset;
    final scrollTop = tester.getTopLeft(find.descendant(of: grid, matching: find.byType(SingleChildScrollView))).dy;
    final x = tester.getCenter(grid).dx;
    await tester.tapAt(Offset(x, scrollTop + 10 * kHourHeight - offset + 5));
    await tester.pumpAndSettle();
    expect(find.text('Yangi uchrashuv'), findsWidgets);
    Finder inDialog(String t) => find.descendant(of: find.byType(AlertDialog), matching: find.text(t));
    expect(inDialog('10:00'), findsOneWidget);
    expect(inDialog('11:00'), findsOneWidget);
    await tester.enterText(find.byType(TextField).first, 'Rejalashtirish');
    await tester.tap(find.text('Qo‘shish'));
    await tester.pumpAndSettle();
    expect(find.text('Rejalashtirish'), findsOneWidget);

    final events = EventStore(db);
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
    final start = events.all.single.start;
    expect(start.hour, 10);

    // Mouse, as on a desktop (touch drags scroll the grid instead).
    await tester.drag(find.text('Rejalashtirish'), const Offset(0, kHourHeight), kind: PointerDeviceKind.mouse);
    await tester.pumpAndSettle();
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
    final moved = (await db.select(db.events).getSingle());
    expect(moved.start, start.add(const Duration(hours: 1)));

    final tile = find.ancestor(of: find.text('Rejalashtirish'), matching: find.byType(Container)).first;
    final bottom = tester.getBottomLeft(tile) + const Offset(20, -3);
    await tester.dragFrom(bottom, const Offset(0, kHourHeight / 2), kind: PointerDeviceKind.mouse);
    await tester.pumpAndSettle();
    final resized = (await db.select(db.events).getSingle());
    expect(resized.end.difference(resized.start), const Duration(minutes: 90));
    events.dispose();
  });

  testWidgets('week navigation', (tester) async {
    await _pump(tester, AppDatabase.memory());
    await _openCalendar(tester);
    final label = find.textContaining(RegExp(r'\d{4}$'));
    final before = tester.widget<Text>(label.first).data;
    await tester.tap(find.byTooltip('Keyingi hafta'));
    await tester.pumpAndSettle();
    expect(tester.widget<Text>(label.first).data, isNot(before));
    await tester.tap(find.text('Bugun'));
    await tester.pumpAndSettle();
    expect(tester.widget<Text>(label.first).data, before);
  });

  testWidgets('meeting from a chat message: one click, then the info panel link', (tester) async {
    final db = AppDatabase.memory();
    await _pump(tester, db);
    // Dilshod: "Payshanba soat 15:00 da demo qilsak bo‘ladimi?" is detected.
    expect(find.textContaining('Uchrashuv aniqlandi'), findsWidgets);
    await tester.tap(find.widgetWithText(FilledButton, 'Kalendarga').first);
    await tester.pumpAndSettle();
    expect(find.textContaining('Kalendarga qo‘shildi: Payshanba'), findsOneWidget);

    final saved = await db.select(db.events).getSingle();
    expect(saved.start.weekday, DateTime.thursday);
    expect(saved.start.hour, 15);
    expect(saved.chatId, 'dilshod');
    expect(saved.remindBefore, 30);

    // Info panel: "Uchrashuvlar 1" opens the calendar filtered by this chat.
    await tester.tap(find.text('Uchrashuvlar'));
    await tester.pumpAndSettle();
    expect(find.byType(CalendarScreen), findsOneWidget);
    expect(find.text('Faqat: Dilshod Karimov'), findsOneWidget);
    expect(find.text('Uchrashuv: Dilshod Karimov'), findsOneWidget);
  });

  testWidgets('"Kalendarga" without a detected meeting opens the editor', (tester) async {
    await _pump(tester, AppDatabase.memory());
    // Latest incoming message "Narxlarni PDF’da yuboring" has no time.
    await tester.tap(find.text('Kalendarga').first);
    await tester.pumpAndSettle();
    expect(find.text('Yangi uchrashuv'), findsOneWidget);
    expect(find.text('Chatdan'), findsOneWidget);
  });
}

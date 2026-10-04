// Tasks: the store (drift, in memory), the board and the chat integration.
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fokus/auth/mock_auth.dart';
import 'package:fokus/data/chat_source.dart';
import 'package:fokus/data/local_store.dart';
import 'package:fokus/data/mock_source.dart';
import 'package:fokus/data/models.dart';
import 'package:fokus/db/database.dart';
import 'package:fokus/main.dart';
import 'package:fokus/state/app_state.dart';
import 'package:fokus/state/settings.dart';
import 'package:fokus/tasks/task_store.dart';
import 'package:fokus/ui/rail.dart';
import 'package:fokus/ui/tasks/tasks_screen.dart';

import 'helpers/fonts.dart';

DateTime _today() {
  final n = DateTime.now();
  return DateTime(n.year, n.month, n.day);
}

/// Logged-in mock with a prepared database.
class _DbAuth extends MockAuth {
  _DbAuth(this.db) : super(loggedIn: true, delay: Duration.zero);

  final AppDatabase db;

  @override
  Future<ChatSession> openSession() async =>
      ChatSession(source: MockChatSource(), store: LocalStore.memory(), db: db, initialChatId: 'dilshod');
}

Future<AppDatabase> _seeded() async {
  final db = AppDatabase.memory();
  final store = TaskStore(db);
  await store.add(title: 'Narxlarni PDF’da yuborish', chatId: 'dilshod', chatTitle: 'Dilshod Karimov', due: _today());
  await store.add(title: 'Shartnomani ko‘rib chiqish', status: TaskStatus.inProgress, important: true);
  await store.add(title: 'Hisob-faktura', due: _today().subtract(const Duration(days: 2)));
  await store.add(title: 'Reliz', status: TaskStatus.done);
  store.dispose();
  return db;
}

Future<void> _pump(WidgetTester tester, AppDatabase db, {Size size = const Size(1440, 900), bool dark = false}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(FokusApp(settings: Settings.inMemory(dark ? ThemeMode.dark : ThemeMode.light), auth: _DbAuth(db)));
  await tester.pumpAndSettle();
}

Future<void> _openTasks(WidgetTester tester) async {
  // The badge sits over the icon; the tap still reaches the rail item.
  await tester.tap(find.descendant(of: find.byType(Rail), matching: find.byIcon(Icons.checklist)), warnIfMissed: false);
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(loadSegoeUi);

  group('TaskStore', () {
    late AppDatabase db;
    late TaskStore store;
    setUp(() async {
      db = AppDatabase.memory();
      store = TaskStore(db);
      await Future<void>.delayed(Duration.zero);
    });
    tearDown(() async {
      store.dispose();
      await db.close();
    });

    test('columns keep insertion order; moving inserts before a card', () async {
      final a = await store.add(title: 'A');
      final b = await store.add(title: 'B');
      final c = await store.add(title: 'C', status: TaskStatus.inProgress);
      expect(store.column(TaskStatus.planned).map((t) => t.title), ['A', 'B']);

      await store.move(c, TaskStatus.planned, beforeId: b);
      expect(store.column(TaskStatus.planned).map((t) => t.title), ['A', 'C', 'B']);
      await store.move(a, TaskStatus.planned);
      expect(store.column(TaskStatus.planned).map((t) => t.title), ['C', 'B', 'A']);
      await store.move(b, TaskStatus.planned, beforeId: c);
      expect(store.column(TaskStatus.planned).map((t) => t.title), ['B', 'C', 'A']);
    });

    test('done sets completedAt, reopening clears it', () async {
      final id = await store.add(title: 'X');
      await store.move(id, TaskStatus.done);
      expect(store.byId(id)!.completedAt, isNotNull);
      await store.move(id, TaskStatus.planned);
      expect(store.byId(id)!.completedAt, isNull);
    });

    test('edit, clear due, remove and restore', () async {
      final id = await store.add(title: 'Eski', due: _today());
      await store.edit(id, title: '  Yangi  ', note: 'izoh', important: true);
      var t = store.byId(id)!;
      expect(t.title, 'Yangi');
      expect(t.note, 'izoh');
      expect(t.important, isTrue);
      expect(t.due, _today());

      await store.edit(id, clearDue: true);
      expect(store.byId(id)!.due, isNull);

      t = store.byId(id)!;
      await store.remove(id);
      expect(store.byId(id), isNull);
      await store.restore(t);
      expect(store.byId(id)!.title, 'Yangi');
    });

    test('overdue, today, open counts and per-chat counts', () async {
      await store.add(title: 'today', due: _today(), chatId: '1');
      await store.add(title: 'late', due: _today().subtract(const Duration(days: 1)), chatId: '1');
      await store.add(title: 'later', due: _today().add(const Duration(days: 3)));
      final done = await store.add(title: 'old done', due: _today().subtract(const Duration(days: 5)), chatId: '1');
      await store.move(done, TaskStatus.done);
      expect(store.overdueCount, 1);
      expect(store.urgentCount, 2);
      expect(store.openCount, 3);
      expect(store.openForChat('1'), 2);
      expect(store.column(TaskStatus.planned, query: 'LAT').map((t) => t.title), ['late', 'later']);
      expect(store.column(TaskStatus.planned, chatId: '1').length, 2);
    });
  });

  test('task titles from messages', () async {
    final db = AppDatabase.memory();
    final s = AppState(source: MockChatSource(), store: LocalStore.memory(), tasks: TaskStore(db), initialChatId: 'dilshod');
    await s.taskFromMessage(const Message(id: 'm', text: 'Birinchi qator\nikkinchi qator', time: '10:00'));
    await s.taskFromMessage(Message(id: 'n', text: 'x' * 200, time: '10:00'));
    await s.taskFromMessage(const Message(id: 'f', text: '', time: '10:00', fileName: 'shartnoma.pdf'));
    final titles = s.tasks.all.map((t) => t.title).toList();
    expect(titles[0], 'Birinchi qator');
    expect(titles[1].length, 140);
    expect(titles[1].endsWith('…'), isTrue);
    expect(titles[2], 'shartnoma.pdf');
    expect(s.tasks.all.first.chatId, 'dilshod');
    expect(s.tasks.all.first.messageText, 'Birinchi qator\nikkinchi qator');
    s.dispose();
    await db.close();
  });

  for (final dark in [false, true]) {
    for (final size in const [Size(1440, 900), Size(800, 600), Size(420, 560)]) {
      testWidgets('board lays out at ${size.width.toInt()}x${size.height.toInt()} ${dark ? 'dark' : 'light'}', (tester) async {
        await _pump(tester, await _seeded(), size: size, dark: dark);
        await _openTasks(tester);
        expect(find.text('Vazifalar'), findsWidgets);
        expect(find.text('Narxlarni PDF’da yuborish'), findsOneWidget);
        expect(find.textContaining('muddati o‘tgan'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets('rail shows overdue + today count', (tester) async {
    await _pump(tester, await _seeded());
    final badge = find.descendant(of: find.byType(Rail), matching: find.text('2'));
    expect(badge, findsOneWidget);
  });

  testWidgets('create with the editor, quick add, complete with the circle', (tester) async {
    await _pump(tester, AppDatabase.memory());
    await _openTasks(tester);

    await tester.tap(find.text('Yangi vazifa'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).at(1), 'Taqdimot tayyorlash');
    await tester.tap(find.text('Ertaga'));
    await tester.tap(find.byTooltip('Muhim deb belgilash'));
    await tester.tap(find.text('Yaratish'));
    await tester.pumpAndSettle();
    expect(find.text('Taqdimot tayyorlash'), findsOneWidget);
    expect(find.text('Ertaga'), findsOneWidget);

    await tester.tap(find.text('Vazifa qo‘shish').at(1)); // "Jarayonda" column
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, 'Mijozga qo‘ng‘iroq');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    expect(find.text('Mijozga qo‘ng‘iroq'), findsOneWidget);

    await tester.tap(find.byTooltip('Bajarildi').first);
    await tester.pumpAndSettle();
    expect(find.byTooltip('Qayta ochish'), findsOneWidget);
  });

  testWidgets('drag a card to another column', (tester) async {
    await _pump(tester, await _seeded());
    await _openTasks(tester);
    final card = find.text('Hisob-faktura');
    final target = find.text('Kutilmoqda');
    final gesture = await tester.startGesture(tester.getCenter(card));
    await tester.pump(const Duration(milliseconds: 50));
    await gesture.moveTo(tester.getCenter(target) + const Offset(0, 120));
    await tester.pump(const Duration(milliseconds: 50));
    await gesture.up();
    await tester.pumpAndSettle();

    final columnOf = find.ancestor(of: find.text('Hisob-faktura'), matching: find.byWidgetPredicate((w) => w.runtimeType.toString() == '_Column'));
    final widget = tester.widget(columnOf) as dynamic;
    expect(widget.status, TaskStatus.waiting);
  });

  testWidgets('delete from the editor and undo', (tester) async {
    await _pump(tester, await _seeded());
    await _openTasks(tester);
    await tester.tap(find.text('Reliz'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, 'O‘chirish'));
    await tester.pumpAndSettle();
    expect(find.text('Reliz'), findsNothing);
    await tester.tap(find.text('Qaytarish'));
    await tester.pumpAndSettle();
    expect(find.text('Reliz'), findsOneWidget);
  });

  testWidgets('task from a chat message, info panel count and back to the chat', (tester) async {
    await _pump(tester, AppDatabase.memory());
    // Dilshod's chat is open; the quick action uses the latest incoming message.
    await tester.tap(find.text('Vazifa qilish'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Vazifa yaratildi'), findsOneWidget);

    // Info panel: "Vazifalar 1" opens the board filtered by this chat.
    final link = find.ancestor(of: find.text('Vazifalar').last, matching: find.byType(Row)).first;
    expect(find.descendant(of: link, matching: find.text('1')), findsOneWidget);
    await tester.tap(find.text('Vazifalar').last);
    await tester.pumpAndSettle();
    expect(find.byType(TasksScreen), findsOneWidget);
    expect(find.text('Faqat: Dilshod Karimov'), findsOneWidget);
    expect(find.descendant(of: find.byType(TasksScreen), matching: find.textContaining('Narxlarni PDF’da yuboring')), findsOneWidget);

    // The chat chip on the card goes back to the chat.
    await tester.tap(find.descendant(of: find.byType(TasksScreen), matching: find.text('Dilshod Karimov')).last);
    await tester.pumpAndSettle();
    expect(find.byType(TasksScreen), findsNothing);
    expect(find.text('Xabar yozing…'), findsOneWidget);
  });

  testWidgets('right click moves a card', (tester) async {
    await _pump(tester, await _seeded());
    await _openTasks(tester);
    await tester.tap(find.text('Hisob-faktura'), buttons: kSecondaryButton);
    await tester.pumpAndSettle();
    await tester.tap(find.text('→ Jarayonda'));
    await tester.pumpAndSettle();
    final widget = tester.widget(find.ancestor(
      of: find.text('Hisob-faktura'),
      matching: find.byWidgetPredicate((w) => w.runtimeType.toString() == '_Column'),
    )) as dynamic;
    expect(widget.status, TaskStatus.inProgress);
  });
}

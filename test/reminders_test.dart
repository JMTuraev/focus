// Reminders: what gets scheduled, keeping Windows in sync, clicks on
// notifications and the settings dialog.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fokus/auth/mock_auth.dart';
import 'package:fokus/calendar/event_store.dart';
import 'package:fokus/data/chat_source.dart';
import 'package:fokus/data/local_store.dart';
import 'package:fokus/data/mock_source.dart';
import 'package:fokus/db/database.dart';
import 'package:fokus/main.dart';
import 'package:fokus/reminders/reminder_service.dart';
import 'package:fokus/state/settings.dart';
import 'package:fokus/tasks/task_store.dart';
import 'package:fokus/ui/calendar/calendar_screen.dart';
import 'package:fokus/ui/tasks/tasks_screen.dart';

import 'helpers/fonts.dart';

class _DbAuth extends MockAuth {
  _DbAuth(this.db) : super(loggedIn: true, delay: Duration.zero);

  final AppDatabase db;

  @override
  Future<ChatSession> openSession() async =>
      ChatSession(source: MockChatSource(), store: LocalStore.memory(), db: db, initialChatId: 'dilshod');
}

void main() {
  setUpAll(loadSegoeUi);

  // Monday, 5 October 2026, 08:00.
  final now = DateTime(2026, 10, 5, 8);

  group('ReminderService', () {
    late AppDatabase db;
    late EventStore events;
    late TaskStore tasks;
    late Settings settings;
    late FakeNotifier notifier;
    late ReminderService service;

    setUp(() async {
      db = AppDatabase.memory();
      events = EventStore(db);
      tasks = TaskStore(db);
      settings = Settings.inMemory();
      notifier = FakeNotifier();
      service = ReminderService(notifier: notifier, events: events, tasks: tasks, settings: settings, clock: () => now);
      await Future<void>.delayed(Duration.zero);
    });
    tearDown(() async {
      service.dispose();
      events.dispose();
      tasks.dispose();
      await db.close();
    });

    test('meetings and tasks that are due get a reminder', () async {
      final meet = await events.add(
        title: 'Demo «Olimp»',
        start: DateTime(2026, 10, 8, 15),
        end: DateTime(2026, 10, 8, 16),
        remindBefore: 30,
        chatTitle: 'Dilshod Karimov',
      );
      await events.add(title: 'Eslatmasiz', start: DateTime(2026, 10, 8, 10), end: DateTime(2026, 10, 8, 11));
      await events.add(title: 'O‘tgan', start: DateTime(2026, 10, 5, 7), end: DateTime(2026, 10, 5, 7, 30), remindBefore: 10);
      await events.add(title: 'Juda uzoq', start: DateTime(2027, 3, 1, 10), end: DateTime(2027, 3, 1, 11), remindBefore: 10);
      final allDay = await events.add(title: 'Konferensiya', start: DateTime(2026, 10, 6), end: DateTime(2026, 10, 6), allDay: true, remindBefore: 0);
      final task = await tasks.add(title: 'Hisobot', due: DateTime(2026, 10, 7));
      final done = await tasks.add(title: 'Bajarilgan', due: DateTime(2026, 10, 7));
      await tasks.move(done, TaskStatus.done);

      final want = service.desired();
      expect(want.keys.toSet(), {
        ReminderService.eventBase + meet,
        ReminderService.eventBase + allDay,
        ReminderService.taskBase + task,
      });
      final m = want[ReminderService.eventBase + meet]!;
      expect(m.at, DateTime(2026, 10, 8, 14, 30));
      expect(m.title, 'Demo «Olimp»');
      expect(m.body, '8-okt, 15:00–16:00 · Dilshod Karimov');
      expect(m.payload, 'event:$meet');
      expect(want[ReminderService.eventBase + allDay]!.at, DateTime(2026, 10, 6, 9));
      final t = want[ReminderService.taskBase + task]!;
      expect(t.at, DateTime(2026, 10, 7, 9));
      expect(t.title, 'Vazifa: Hisobot');
      expect(t.payload, 'task:$task');

      settings.setTaskReminderHour(18);
      expect(service.desired()[ReminderService.taskBase + task]!.at, DateTime(2026, 10, 7, 18));

      settings.setRemindersEnabled(false);
      expect(service.desired(), isEmpty);
    });

    test('sync schedules, reschedules and cancels', () async {
      final id = await events.add(title: 'A', start: DateTime(2026, 10, 8, 15), end: DateTime(2026, 10, 8, 16), remindBefore: 10);
      final task = await tasks.add(title: 'T', due: DateTime(2026, 10, 9));
      await service.sync();
      expect(notifier.scheduledById[ReminderService.eventBase + id]!.at, DateTime(2026, 10, 8, 14, 50));
      expect(notifier.scheduledById.containsKey(ReminderService.taskBase + task), isTrue);

      await events.reschedule(id, DateTime(2026, 10, 9, 11), DateTime(2026, 10, 9, 12));
      await service.sync();
      expect(notifier.scheduledById[ReminderService.eventBase + id]!.at, DateTime(2026, 10, 9, 10, 50));

      await tasks.move(task, TaskStatus.done);
      await events.remove(id);
      await service.sync();
      expect(notifier.scheduledById, isEmpty);
    });

    test('after a restart old toasts of ours are cleaned up, others are left', () async {
      notifier.scheduledById[ReminderService.eventBase + 999] =
          PlannedReminder(at: DateTime(2026, 10, 10), title: 'eski', body: '', payload: 'event:999');
      notifier.scheduledById[1] = PlannedReminder(at: DateTime(2026, 10, 10), title: 'sinov', body: '', payload: '');
      await service.sync();
      expect(notifier.scheduledById.keys, [1]);
    });

    test('changes are picked up automatically', () async {
      service.start();
      await events.add(title: 'Avto', start: DateTime(2026, 10, 8, 15), end: DateTime(2026, 10, 8, 16), remindBefore: 60);
      await Future<void>.delayed(const Duration(milliseconds: 400));
      expect(notifier.scheduledById.values.single.title, 'Avto');
    });
  });

  Future<(FakeNotifier, AppDatabase)> pumpApp(WidgetTester tester, {String? launch}) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final db = AppDatabase.memory();
    final notifier = FakeNotifier()..launch = launch;
    await tester.pumpWidget(FokusApp(settings: Settings.inMemory(ThemeMode.light), auth: _DbAuth(db), notifier: notifier));
    await tester.pumpAndSettle();
    return (notifier, db);
  }

  testWidgets('clicking a meeting or task notification opens it', (tester) async {
    final (notifier, db) = await pumpApp(tester);
    final start = DateTime.now().add(const Duration(days: 3));
    final id = await EventStore(db).add(title: 'Qo‘ng‘iroq', start: start, end: start.add(const Duration(hours: 1)));
    await tester.pumpAndSettle();

    notifier.tap('event:$id');
    await tester.pumpAndSettle();
    expect(find.byType(CalendarScreen), findsOneWidget);

    notifier.tap('task:1');
    await tester.pumpAndSettle();
    expect(find.byType(TasksScreen), findsOneWidget);
  });

  testWidgets('a notification that started the app is opened once logged in', (tester) async {
    await pumpApp(tester, launch: 'task:7');
    expect(find.byType(TasksScreen), findsOneWidget);
  });

  testWidgets('settings dialog: theme, reminders, test notification', (tester) async {
    final (notifier, _) = await pumpApp(tester);
    await tester.tap(find.byTooltip('Sozlamalar'));
    await tester.pumpAndSettle();
    expect(find.text('Sozlamalar'), findsWidgets);

    await tester.tap(find.text('Tungi'));
    await tester.pumpAndSettle();
    expect(Theme.of(tester.element(find.text('Mavzu'))).brightness, Brightness.dark);

    await tester.tap(find.text('10:00'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sinab ko‘rish'));
    await tester.pumpAndSettle();
    expect(notifier.shown, ['Focus: Bildirishnomalar ishlayapti.']);

    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();
    expect(find.text('10:00'), findsNothing, reason: 'hour picker hidden when reminders are off');
    expect(tester.takeException(), isNull);
  });

  testWidgets('without a notifier the switch explains why it is off', (tester) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(FokusApp(settings: Settings.inMemory(ThemeMode.light), auth: _DbAuth(AppDatabase.memory())));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Sozlamalar'));
    await tester.pumpAndSettle();
    expect(find.textContaining('ishga tushmadi'), findsOneWidget);
  });
}

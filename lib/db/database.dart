import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:path_provider/path_provider.dart';

part 'database.g.dart';

/// Kanban columns. Stored by name, so the order can change safely.
enum TaskStatus {
  planned('Rejada'),
  inProgress('Jarayonda'),
  waiting('Kutilmoqda'),
  done('Bajarildi');

  const TaskStatus(this.label);
  final String label;
}

/// A to-do, optionally created from a chat message.
class Tasks extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text()();
  TextColumn get note => text().withDefault(const Constant(''))();
  TextColumn get status => textEnum<TaskStatus>()();
  BoolColumn get important => boolean().withDefault(const Constant(false))();

  /// Due day (local midnight); null = no deadline.
  DateTimeColumn get due => dateTime().nullable()();

  /// Order inside a column (smaller first).
  RealColumn get position => real().withDefault(const Constant(0))();

  /// Where the task came from (Telegram chat id, title and message).
  TextColumn get chatId => text().nullable()();
  TextColumn get chatTitle => text().nullable()();
  TextColumn get messageId => text().nullable()();
  TextColumn get messageText => text().nullable()();

  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get completedAt => dateTime().nullable()();
}

/// A calendar event (meeting), optionally created from a chat message.
class Events extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text()();
  TextColumn get note => text().withDefault(const Constant(''))();
  DateTimeColumn get start => dateTime()();
  DateTimeColumn get end => dateTime()();
  BoolColumn get allDay => boolean().withDefault(const Constant(false))();

  /// Minutes before [start] to remind; null = no reminder.
  IntColumn get remindBefore => integer().nullable()();

  TextColumn get chatId => text().nullable()();
  TextColumn get chatTitle => text().nullable()();
  TextColumn get messageId => text().nullable()();
  TextColumn get messageText => text().nullable()();

  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
}

/// Fokus' own local database (`fokus.sqlite` in the app support folder).
/// Telegram data stays in TDLib; this holds tasks, calendar events and,
/// later, notes and the data now kept in local_state.json.
@DriftDatabase(tables: [Tasks, Events])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.executor);

  factory AppDatabase.open() => AppDatabase(
        driftDatabase(
          name: 'fokus',
          native: const DriftNativeOptions(databaseDirectory: getApplicationSupportDirectory),
        ),
      );

  /// Not persisted: mock data and tests.
  factory AppDatabase.memory() => AppDatabase(NativeDatabase.memory());

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) => m.createAll(),
        onUpgrade: (m, from, to) async {
          // v2: calendar events.
          if (from < 2) await m.createTable(events);
        },
      );
}

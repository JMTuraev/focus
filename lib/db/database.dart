import 'dart:convert';

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

/// Note background. Stored by name.
enum NoteColor {
  none('Rangsiz'),
  yellow('Sariq'),
  green('Yashil'),
  blue('Ko‘k'),
  purple('Binafsha'),
  pink('Pushti'),
  orange('To‘q sariq');

  const NoteColor(this.label);
  final String label;
}

/// One line of a checklist note.
class NoteItem {
  const NoteItem(this.text, {this.done = false});

  final String text;
  final bool done;

  NoteItem copyWith({String? text, bool? done}) => NoteItem(text ?? this.text, done: done ?? this.done);

  @override
  bool operator ==(Object other) => other is NoteItem && other.text == text && other.done == done;

  @override
  int get hashCode => Object.hash(text, done);
}

/// Checklist items as JSON text: [{"t": "...", "d": true}].
class NoteItemsConverter extends TypeConverter<List<NoteItem>, String> {
  const NoteItemsConverter();

  @override
  List<NoteItem> fromSql(String fromDb) {
    try {
      return [
        for (final j in jsonDecode(fromDb) as List)
          NoteItem((j as Map)['t'] as String? ?? '', done: j['d'] == true),
      ];
    } catch (_) {
      return const [];
    }
  }

  @override
  String toSql(List<NoteItem> value) => jsonEncode([
        for (final i in value) {'t': i.text, if (i.done) 'd': true},
      ]);
}

/// A note: free text or a checklist, optionally saved from a chat message.
class Notes extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text().withDefault(const Constant(''))();
  TextColumn get body => text().withDefault(const Constant(''))();
  TextColumn get items => text().map(const NoteItemsConverter()).withDefault(const Constant('[]'))();
  BoolColumn get checklist => boolean().withDefault(const Constant(false))();
  TextColumn get color => textEnum<NoteColor>().withDefault(Constant(NoteColor.none.name))();
  BoolColumn get pinned => boolean().withDefault(const Constant(false))();

  TextColumn get chatId => text().nullable()();
  TextColumn get chatTitle => text().nullable()();
  TextColumn get messageId => text().nullable()();

  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
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
/// Telegram data stays in TDLib; this holds tasks, calendar events, notes
/// and, later, the data now kept in local_state.json.
@DriftDatabase(tables: [Tasks, Events, Notes])
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
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) => m.createAll(),
        onUpgrade: (m, from, to) async {
          // v2: calendar events.
          if (from < 2) await m.createTable(events);
          // v3: notes.
          if (from < 3) await m.createTable(notes);
        },
      );
}

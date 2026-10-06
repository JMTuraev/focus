import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:path_provider/path_provider.dart';

import '../l10n/l10n.dart';

part 'database.g.dart';

/// Kanban columns. Stored by name, so the order can change safely.
enum TaskStatus {
  planned,
  inProgress,
  waiting,
  done;

  /// Column title in the current UI language.
  String get label => S.current.tasks.statusLabels[index];
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
  none,
  yellow,
  green,
  blue,
  purple,
  pink,
  orange;

  /// Color name in the current UI language.
  String get label => S.current.notes.colorLabels[index];
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

/// The user's collections (to‘plamlar), in rail order.
@DataClassName('CollectionRow')
class Collections extends Table {
  TextColumn get id => text()();
  TextColumn get label => text()();
  TextColumn get icon => text().withDefault(const Constant('folder'))();
  IntColumn get position => integer().withDefault(const Constant(0))();

  /// One of `kCollectionColorKeys`; '' = accent.
  TextColumn get color => text().withDefault(const Constant(''))();

  @override
  Set<Column> get primaryKey => {id};
}

/// Which collection a chat is in ('' = unsorted on purpose).
@DataClassName('ChatCollectionRow')
class ChatCollections extends Table {
  TextColumn get chatId => text()();
  TextColumn get collectionId => text()();

  @override
  Set<Column> get primaryKey => {chatId};
}

/// Unread messages already seen in Focus, per chat (Telegram is not told).
@DataClassName('SeenCountRow')
class SeenCounts extends Table {
  TextColumn get chatId => text()();
  IntColumn get count => integer()();

  @override
  Set<Column> get primaryKey => {chatId};
}

/// Focus-only display names for files in messages ("rename in the app"):
/// the file in Telegram keeps its name, only Focus shows this one.
class FileNames extends Table {
  TextColumn get chatId => text()();
  TextColumn get messageId => text()();
  TextColumn get name => text()();

  @override
  Set<Column> get primaryKey => {chatId, messageId};
}

/// Focus-only marks on files: favorite and the user's own tags (JSON list).
/// [kind] is the `SavedKind` name.
@DataClassName('FileMarkRow')
class FileMarks extends Table {
  TextColumn get chatId => text()();
  TextColumn get messageId => text()();
  TextColumn get kind => text()();
  BoolColumn get favorite => boolean().withDefault(const Constant(false))();
  TextColumn get tags => text().withDefault(const Constant('[]'))();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {chatId, messageId};
}

/// Messages saved into "Fayllar", with a snapshot for the list.
@DataClassName('SavedItemRow')
class SavedItems extends Table {
  TextColumn get chatId => text()();
  TextColumn get messageId => text()();
  TextColumn get kind => text()();
  TextColumn get chatTitle => text()();
  TextColumn get body => text().withDefault(const Constant(''))();
  TextColumn get fileName => text().nullable()();
  IntColumn get size => integer().withDefault(const Constant(0))();
  DateTimeColumn get date => dateTime().nullable()();
  DateTimeColumn get savedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {chatId, messageId};
}

/// Small flags, e.g. that local_state.json was imported.
@DataClassName('KeyValueRow')
class KeyValues extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column> get primaryKey => {key};
}

/// Focus' own local database (`fokus.sqlite` in the app support folder).
/// Telegram data stays in TDLib; this holds tasks, calendar events, notes,
/// collections and the Focus-only "seen" counters.
@DriftDatabase(tables: [Tasks, Events, Notes, Collections, ChatCollections, SeenCounts, KeyValues, FileNames, FileMarks, SavedItems])
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
  int get schemaVersion => 8;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) => m.createAll(),
        onUpgrade: (m, from, to) async {
          // v2: calendar events.
          if (from < 2) await m.createTable(events);
          // v3: notes.
          if (from < 3) await m.createTable(notes);
          // v4: collections, chat assignments, seen counts (from local_state.json).
          if (from < 4) {
            await m.createTable(collections);
            await m.createTable(chatCollections);
            await m.createTable(seenCounts);
            await m.createTable(keyValues);
          }
          // v5: collection color (createTable above already has it).
          if (from >= 4 && from < 5) await m.addColumn(collections, collections.color);
          // v6: Focus-only file names.
          if (from < 6) await m.createTable(fileNames);
          // v7: favorites and tags on files.
          if (from < 7) await m.createTable(fileMarks);
          // v8: messages saved into "Fayllar".
          if (from < 8) await m.createTable(savedItems);
        },
      );
}

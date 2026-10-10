// LocalStore on the database: persistence, the one-time import of
// local_state.json and the v3 -> v4 migration.
import 'dart:convert';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fokus/data/local_store.dart';
import 'package:fokus/data/models.dart';
import 'package:fokus/db/database.dart';
import 'package:sqlite3/sqlite3.dart';

void main() {
  late Directory dir;
  late File dbFile;
  late File json;
  setUp(() {
    dir = Directory.systemTemp.createTempSync('fokus_local');
    dbFile = File('${dir.path}${Platform.pathSeparator}fokus.sqlite');
    json = File('${dir.path}${Platform.pathSeparator}local_state.json');
  });
  tearDown(() => dir.deleteSync(recursive: true));

  AppDatabase openDb() => AppDatabase(NativeDatabase(dbFile));

  test('per-chat drafts survive restart, preserve whitespace and clear independently', () async {
    var db = openDb();
    final a = await LocalStore.openDb(db, legacy: json);
    a.setDraft('42', '  Shartnoma\nertaga 😀  ');
    a.setDraft('43', 'Boshqa mijoz');
    a.setDraft('44', 'Tozalash');
    a.setDraft('44', '');
    await a.flush();
    await db.close();

    db = openDb();
    final b = await LocalStore.openDb(db, legacy: json);
    expect(b.draftOf('42'), '  Shartnoma\nertaga 😀  ');
    expect(b.draftOf('43'), 'Boshqa mijoz');
    expect(b.draftOf('44'), '');
    b.setDraft('42', '');
    final clearedVersion = b.draftVersion('42');
    await b.flush();
    await b.reload();
    expect(b.draftVersion('42'), greaterThan(clearedVersion), reason: 'reload invalidates pending sends for cleared drafts too');
    expect(b.draftOf('42'), '');
    expect(b.draftOf('43'), 'Boshqa mijoz');
    expect(await (db.select(db.keyValues)..where((t) => t.key.equals('chatDraft:42'))).get(), isEmpty);
    await db.close();
  });

  test('reply drafts survive restart, clear independently and reject another chat', () async {
    var db = openDb();
    final a = await LocalStore.openDb(db);
    const reply = ReplyInfo(chatId: '42', messageId: '99', author: 'Mijoz 😀', text: 'Savol\nIkkinchi qator');
    a.setReplyDraft('42', reply);
    a.setDraft('42', 'Javob');
    expect(() => a.setReplyDraft('43', reply), throwsArgumentError);
    await a.flush(); await db.close();
    db = openDb();
    final b = await LocalStore.openDb(db);
    expect(b.replyDraftOf('42')!.text, reply.text);
    expect(b.replyDraftOf('43'), isNull);
    b.setReplyDraft('42', null);
    await b.flush(); await b.reload();
    expect(b.replyDraftOf('42'), isNull);
    expect(b.draftOf('42'), 'Javob');
    expect(await (db.select(db.keyValues)..where((t) => t.key.equals('chatReplyDraft:42'))).get(), isEmpty);
    await db.close();
  });

  test('collections, assignments and seen counts survive a restart', () async {
    var db = openDb();
    final a = await LocalStore.openDb(db, legacy: json);
    expect(a.collections.map((c) => c.id), kDefaultCollections.map((c) => c.id));

    final created = a.addCollection('  Yetkazib beruvchilar ', 'truck', colorKey: 'orange');
    a.setCollection('42', created.id);
    a.setCollection('43', 'oila');
    a.setSeen('42', 3);
    a.setSeen('44', 2);
    a.setSeen('44', 0);
    a.updateCollection('ish', label: 'Ish joyi', iconKey: 'bolt', colorKey: 'green');
    a.setFileName('42', '7', '  Shartnoma 2026.pdf ');
    a.setFileName('42', '8', 'x');
    a.setFileName('42', '8', '');
    a.setMark(FileMark(chatId: '42', messageId: '7', kind: 'documents', favorite: true, tags: const ['Shartnoma', 'muhim'], updatedAt: DateTime(2026, 10, 4)));
    a.setMark(FileMark(chatId: '42', messageId: '9', kind: 'photos', tags: const ['shartnoma'], updatedAt: DateTime(2026, 10, 5)));
    a.setMark(FileMark(chatId: '42', messageId: '10', kind: 'documents', favorite: true, updatedAt: DateTime(2026, 10, 3)));
    a.setMark(FileMark(chatId: '42', messageId: '10', kind: 'documents', updatedAt: DateTime(2026, 10, 3)));
    a.addSaved(SavedItem(chatId: '42', messageId: '7', kind: SavedKind.documents, chatTitle: 'Dilshod', fileName: 'a.pdf', size: 10, date: DateTime(2026, 10, 1), savedAt: DateTime(2026, 10, 4)));
    a.addSaved(SavedItem(chatId: '43', messageId: '3', kind: SavedKind.text, chatTitle: 'Oila', text: 'Kalit qo‘shnida', savedAt: DateTime(2026, 10, 2)));
    a.addSaved(SavedItem(chatId: '44', messageId: '1', kind: SavedKind.photos, chatTitle: 'X', savedAt: DateTime(2026, 10, 2)));
    a.setMark(FileMark(chatId: '44', messageId: '1', kind: 'photos', favorite: true, updatedAt: DateTime(2026, 10, 2)));
    a.setFileName('44', '1', 'rasm');
    a.removeSaved('44', '1');
    a.moveCollection(a.collections.length - 1, 0);
    a.deleteCollection('oila');
    await a.flush();
    await db.close();

    db = openDb();
    final b = await LocalStore.openDb(db, legacy: json);
    expect(b.collections.first.label, 'Yetkazib beruvchilar');
    expect(b.collections.first.colorKey, 'orange');
    expect(b.fileName('42', '7'), 'Shartnoma 2026.pdf');
    expect(b.fileName('42', '8'), isNull, reason: 'cleared with an empty name');
    final mark = b.markOf('42', '7')!;
    expect(mark.favorite, isTrue);
    expect(mark.tags, ['Shartnoma', 'muhim']);
    expect(b.markOf('42', '10'), isNull, reason: 'an empty mark is deleted');
    expect(b.marks.map((m) => m.messageId), ['9', '7'], reason: 'newest change first');
    expect(b.tagCounts, [('Shartnoma', 2), ('muhim', 1)], reason: 'tags match without case');
    expect(b.savedItems.map((i) => i.key), ['43:3', '42:7'], reason: 'newest message first (date, else saved time)');
    final doc = b.savedOf('42', '7')!;
    expect((doc.kind, doc.fileName, doc.size, doc.date), (SavedKind.documents, 'a.pdf', 10, DateTime(2026, 10, 1)));
    expect(b.savedOf('43', '3')!.text, 'Kalit qo‘shnida');
    expect(b.savedOf('44', '1'), isNull);
    expect(b.markOf('44', '1'), isNull, reason: 'removing takes the marks too');
    expect(b.fileName('44', '1'), isNull, reason: 'and the Focus-only name');
    expect(b.collectionById('ish')!.colorKey, 'green');
    expect(b.collections.first.iconKey, 'truck');
    expect(b.collectionById('ish')!.label, 'Ish joyi');
    expect(b.collectionById('oila'), isNull);
    expect(b.collectionOf('42'), created.id);
    expect(b.collectionOf('43'), '', reason: 'chats of a deleted collection become unsorted');
    expect(b.seenOf('42'), 3);
    expect(b.seenOf('44'), 0);
    await db.close();
  });

  test('local_state.json is imported once and kept as .bak', () async {
    json.writeAsStringSync(jsonEncode({
      'collectionList': [
        {'id': 'ish', 'label': 'Ish', 'icon': 'work'},
        {'id': 'c1', 'label': 'Mijozlar 2026', 'icon': 'star'},
      ],
      'collections': {'111': 'c1', '222': ''},
      'seen': {'111': 5},
    }));
    var db = openDb();
    final s = await LocalStore.openDb(db, legacy: json);
    expect(s.collections.map((c) => c.label), ['Ish', 'Mijozlar 2026']);
    expect(s.collectionOf('111'), 'c1');
    expect(s.collectionOf('222'), '');
    expect(s.seenOf('111'), 5);
    expect(json.existsSync(), isFalse);
    expect(File('${json.path}.bak').existsSync(), isTrue);

    // A later run does not import again (even if a file reappears).
    s.deleteCollection('c1');
    await s.flush();
    await db.close();
    json.writeAsStringSync(jsonEncode({'collectionList': [{'id': 'x', 'label': 'X', 'icon': 'flag'}]}));
    db = openDb();
    final again = await LocalStore.openDb(db, legacy: json);
    expect(again.collections.map((c) => c.id), ['ish']);
    await db.close();
  });

  test('no json: defaults once; deleting every collection is remembered', () async {
    var db = openDb();
    final s = await LocalStore.openDb(db, legacy: json);
    for (final c in List.of(s.collections)) {
      s.deleteCollection(c.id);
    }
    await s.flush();
    await db.close();
    db = openDb();
    expect((await LocalStore.openDb(db, legacy: json)).collections, isEmpty);
    await db.close();
  });

  test('a broken json falls back to defaults', () async {
    json.writeAsStringSync('{not json');
    final db = openDb();
    final s = await LocalStore.openDb(db, legacy: json);
    expect(s.collections.length, kDefaultCollections.length);
    await db.close();
  });

  test('a v3 database (tasks, events, notes) is upgraded to v4', () async {
    final probe = AppDatabase.memory();
    final create = <String>[
      for (final t in ['tasks', 'events', 'notes'])
        (await probe.customSelect("SELECT sql FROM sqlite_master WHERE name = '$t'").getSingle()).read<String>('sql'),
    ];
    await probe.close();
    final raw = sqlite3.open(dbFile.path);
    for (final s in create) {
      raw.execute(s);
    }
    raw
      ..execute('INSERT INTO notes (title, body, items, checklist, color, pinned, created_at, updated_at) '
          "VALUES ('Eski eslatma', '', '[]', 0, 'none', 0, 0, 0)")
      ..execute('PRAGMA user_version = 3');
    raw.close();

    final db = openDb();
    final s = await LocalStore.openDb(db, legacy: json);
    expect(s.collections.length, kDefaultCollections.length);
    expect((await db.select(db.notes).get()).single.title, 'Eski eslatma');
    await db.close();
  });

  test('a v4 database (collections without color) is upgraded to v5', () async {
    final probe = AppDatabase.memory();
    final create = <String>[
      for (final t in ['tasks', 'events', 'notes', 'chat_collections', 'seen_counts', 'key_values'])
        (await probe.customSelect("SELECT sql FROM sqlite_master WHERE name = '$t'").getSingle()).read<String>('sql'),
    ];
    await probe.close();
    final raw = sqlite3.open(dbFile.path);
    for (final s in create) {
      raw.execute(s);
    }
    raw
      ..execute('CREATE TABLE collections (id TEXT NOT NULL, label TEXT NOT NULL, '
          "icon TEXT NOT NULL DEFAULT 'folder', position INTEGER NOT NULL DEFAULT 0, PRIMARY KEY (id))")
      ..execute("INSERT INTO collections (id, label, icon, position) VALUES ('ish', 'Ish', 'work', 0)")
      ..execute("INSERT INTO key_values (key, value) VALUES ('localStateImported', '1')")
      ..execute('PRAGMA user_version = 4');
    raw.close();

    final db = openDb();
    final s = await LocalStore.openDb(db, legacy: json);
    expect(s.collections.map((c) => c.id), ['ish']);
    expect(s.collections.single.colorKey, '');
    s.updateCollection('ish', label: 'Ish', iconKey: 'work', colorKey: 'red');
    await s.flush();
    expect((await db.select(db.collections).get()).single.color, 'red');
    await db.close();
  });
}

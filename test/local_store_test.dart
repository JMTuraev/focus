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

  test('collections, assignments and seen counts survive a restart', () async {
    var db = openDb();
    final a = await LocalStore.openDb(db, legacy: json);
    expect(a.collections.map((c) => c.id), kDefaultCollections.map((c) => c.id));

    final created = a.addCollection('  Yetkazib beruvchilar ', 'truck');
    a.setCollection('42', created.id);
    a.setCollection('43', 'oila');
    a.setSeen('42', 3);
    a.setSeen('44', 2);
    a.setSeen('44', 0);
    a.updateCollection('ish', label: 'Ish joyi', iconKey: 'bolt');
    a.moveCollection(a.collections.length - 1, 0);
    a.deleteCollection('oila');
    await a.flush();
    await db.close();

    db = openDb();
    final b = await LocalStore.openDb(db, legacy: json);
    expect(b.collections.first.label, 'Yetkazib beruvchilar');
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
}

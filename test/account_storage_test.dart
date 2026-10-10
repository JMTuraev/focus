import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:fokus/backup/backup_crypto.dart';
import 'package:fokus/backup/backup_key_store.dart';
import 'package:fokus/data/account_storage.dart';
import 'package:fokus/data/local_store.dart';
import 'package:fokus/db/database.dart';
import 'package:fokus/tasks/task_store.dart';
import 'package:fokus/data/models.dart';
import 'package:sqlite3/sqlite3.dart';

void main() {
  late Directory root;
  setUp(() => root = Directory.systemTemp.createTempSync('focus_accounts_test'));
  tearDown(() => root.deleteSync(recursive: true));

  test('tasks, drafts, saved metadata and backup settings stay in their account after restart', () async {
    final a = AccountStorage(root, '11');
    final dbA = await a.open();
    final tasksA = TaskStore(dbA);
    await tasksA.add(title: 'Account A only');
    tasksA.dispose();
    final storeA = await LocalStore.openDb(dbA);
    storeA.setDraft('999', 'A draft for a shared chat');
    storeA.setReplyDraft('999', const ReplyInfo(chatId: '999', messageId: '55', author: 'A customer', text: 'A question'));
    await storeA.flush();
    await dbA.into(dbA.keyValues).insert(KeyValuesCompanion.insert(key: 'backupAuto', value: '1'));
    await dbA.close();

    final b = AccountStorage(root, '22');
    final dbB = await b.open();
    final storeB = await LocalStore.openDb(dbB);
    expect(await dbB.select(dbB.tasks).get(), isEmpty);
    expect(storeB.draftOf('999'), '');
    expect(storeB.replyDraftOf('999'), isNull);
    expect(await (dbB.select(dbB.keyValues)..where((t) => t.key.equals('backupAuto'))).get(), isEmpty);
    storeB.setDraft('999', 'B draft');
    await storeB.flush();
    await dbB.close();

    final againA = await AccountStorage(root, '11').open();
    expect((await againA.select(againA.tasks).get()).single.title, 'Account A only');
    final restoredA = await LocalStore.openDb(againA);
    expect(restoredA.draftOf('999'), 'A draft for a shared chat');
    expect(restoredA.replyDraftOf('999')!.messageId, '55');
    await againA.close();
    final againB = await AccountStorage(root, '22').open();
    expect((await LocalStore.openDb(againB)).draftOf('999'), 'B draft');
    await againB.close();
  });

  test('DPAPI backup keys never fall back to another account or the shared key', () async {
    final key = await BackupCrypto.deriveKey('local synthetic password', params: const KdfParams(memoryKiB: 1024, iterations: 1));
    final legacyKeys = DpapiBackupKeyStore(directory: root);
    await legacyKeys.save(key);
    final a = AccountStorage(root, '11');
    final b = AccountStorage(root, '22');
    final keysA = DpapiBackupKeyStore(directory: a.directory);
    final keysB = DpapiBackupKeyStore(directory: b.directory);
    expect(await keysA.load(), isNull);
    expect(await keysB.load(), isNull);
    await keysA.save(key);
    expect((await keysA.load())!.key, key.key);
    expect(await keysB.load(), isNull);
    await keysB.clear();
    expect((await keysA.load())!.key, key.key);
    expect((await legacyKeys.load())!.key, key.key);
  });

  test('legacy import is explicit, keeps source intact and disables automatic uploads', () async {
    final legacy = AppDatabase.inDirectory(root);
    final tasks = TaskStore(legacy);
    await tasks.add(title: 'Old owner data');
    tasks.dispose();
    final oldStore = await LocalStore.openDb(legacy);
    oldStore.setDraft('99', 'Preserved old draft');
    await oldStore.flush();
    await legacy.into(legacy.keyValues).insert(KeyValuesCompanion.insert(key: 'backupAuto', value: '1'));
    await legacy.close();
    final originalBytes = File('${root.path}/fokus.sqlite').readAsBytesSync();
    File('${root.path}/backup.key').writeAsBytesSync([7, 8, 9]);

    final a = AccountStorage(root, '11');
    final db = await a.open();
    expect(await a.offerLegacyImport, isTrue);
    expect(await db.select(db.tasks).get(), isEmpty);
    await a.importLegacy(db);
    expect((await db.select(db.tasks).get()).single.title, 'Old owner data');
    expect((await LocalStore.openDb(db)).draftOf('99'), 'Preserved old draft');
    expect((await (db.select(db.keyValues)..where((t) => t.key.equals('backupAuto'))).getSingle()).value, '0');
    expect(File('${root.path}/fokus.sqlite').readAsBytesSync(), originalBytes);
    expect(a.backupKeyFile.readAsBytesSync(), [7, 8, 9]);
    expect(File('${root.path}/backup.key').readAsBytesSync(), [7, 8, 9]);
    await db.close();

    final b = AccountStorage(root, '22');
    final dbB = await b.open();
    expect(await b.offerLegacyImport, isFalse);
    await expectLater(b.importLegacy(dbB), throwsStateError);
    expect(await dbB.select(dbB.tasks).get(), isEmpty);
    expect(await b.backupKeyFile.exists(), isFalse);
    await dbB.close();
  });

  test('declining legacy import preserves data without assigning it to that account', () async {
    File('${root.path}/local_state.json').writeAsStringSync(jsonEncode({
      'collections': {'99': 'ish'}
    }));
    final a = AccountStorage(root, '11');
    final db = await a.open();
    expect(await a.offerLegacyImport, isTrue);
    await a.keepLegacySeparate();
    expect(await a.offerLegacyImport, isFalse);
    await db.close();
    expect(File('${root.path}/local_state.json').existsSync(), isTrue);
    final b = AccountStorage(root, '22');
    final dbB = await b.open();
    await LocalStore.openDb(dbB); // already initialized with defaults
    expect(await b.offerLegacyImport, isTrue);
    await b.importLegacy(dbB);
    expect((await LocalStore.openDb(dbB)).collectionOf('99'), 'ish');
    expect(File('${root.path}/local_state.json').existsSync(), isTrue);
    await dbB.close();
  });

  test('an existing account database is never overwritten by legacy import', () async {
    final first = await AccountStorage(root, '11').open();
    await first.customSelect('SELECT 1').get();
    await first.close();
    File('${root.path}/local_state.json').writeAsStringSync('{}');
    final existing = AccountStorage(root, '11');
    final db = await existing.open();
    expect(await existing.offerLegacyImport, isFalse);
    await expectLater(existing.importLegacy(db), throwsStateError);
    await db.close();
  });

  test('an interrupted legacy decision is offered again after restart', () async {
    File('${root.path}/local_state.json').writeAsStringSync('{}');
    final first = await AccountStorage(root, '11').open();
    await LocalStore.openDb(first);
    await first.close();
    final retry = AccountStorage(root, '11');
    final db = await retry.open();
    expect(await retry.offerLegacyImport, isTrue);
    await retry.keepLegacySeparate();
    expect(await retry.offerLegacyImport, isFalse);
    await db.close();
  });

  test('a damaged legacy JSON fails without claiming ownership and remains retryable', () async {
    final original = File('${root.path}/local_state.json')..writeAsStringSync('{not json');
    final a = AccountStorage(root, '11');
    final db = await a.open();
    await LocalStore.openDb(db);
    await expectLater(a.importLegacy(db), throwsFormatException);
    expect(original.readAsStringSync(), '{not json');
    expect(File('${root.path}/legacy-account-owner.json').existsSync(), isFalse);
    expect(await a.offerLegacyImport, isTrue);
    original.writeAsStringSync(jsonEncode({
      'collections': {'99': 'ish'}
    }));
    await a.importLegacy(db);
    expect((await LocalStore.openDb(db)).collectionOf('99'), 'ish');
    await db.close();
  });

  test('account directories reject missing identity and path traversal', () {
    for (final id in ['', '0', '-1', '../11', '11/22', 'name']) {
      expect(() => AccountStorage(root, id), throwsArgumentError);
    }
  });

  test('legacy import includes committed WAL data without modifying its source', () async {
    final legacy = AppDatabase.inDirectory(root);
    await LocalStore.openDb(legacy);
    await legacy.close();
    final path = '${root.path}/fokus.sqlite';
    final writer = sqlite3.open(path);
    try {
      writer.execute('PRAGMA journal_mode=WAL');
      writer.execute("INSERT INTO key_values (key, value) VALUES ('chatDraft:99', 'committed in WAL')");
      expect(File('$path-wal').lengthSync(), greaterThan(0));
      final before = File(path).readAsBytesSync();
      final a = AccountStorage(root, '11');
      final db = await a.open();
      try {
        await a.importLegacy(db);
        expect((await LocalStore.openDb(db)).draftOf('99'), 'committed in WAL');
        expect(File(path).readAsBytesSync(), before);
        expect(writer.select("SELECT value FROM key_values WHERE key='chatDraft:99'").single['value'], 'committed in WAL');
      } finally {
        await db.close();
      }
    } finally {
      writer.close();
    }
  });

  test('notification links reject another account and old unscoped payloads', () {
    expect(AccountStorage.notificationFor('11', 'account:11:task:2'), 'task:2');
    expect(AccountStorage.notificationFor('22', 'account:11:task:2'), isNull);
    expect(AccountStorage.notificationFor('11', 'task:2'), isNull);
    expect(AccountStorage.notificationFor(null, 'task:2'), 'task:2', reason: 'mock sessions preserve their payloads');
  });
}

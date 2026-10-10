import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:drift/drift.dart' show InsertMode;
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3/sqlite3.dart';

import '../backup/snapshot.dart';
import '../db/database.dart';
import 'local_store.dart';

/// Account-owned data never falls back to the old shared database or key.
class AccountStorage {
  static String? notificationFor(String? accountId, String payload) {
    if (accountId == null) return payload;
    final prefix = 'account:$accountId:';
    return payload.startsWith(prefix) ? payload.substring(prefix.length) : null;
  }

  AccountStorage(this.root, this.accountId) {
    if (!RegExp(r'^[1-9][0-9]*$').hasMatch(accountId)) {
      throw ArgumentError.value(accountId, 'accountId');
    }
  }

  final Directory root;
  final String accountId;
  Directory get directory => Directory('${root.path}/accounts/$accountId');
  File get databaseFile => File('${directory.path}/fokus.sqlite');
  File get backupKeyFile => File('${directory.path}/backup.key');
  File get legacyDatabase => File('${root.path}/fokus.sqlite');
  File get _owner => File('${root.path}/legacy-account-owner.json');
  File get _reviewed => File('${directory.path}/legacy-reviewed');
  File get _pending => File('${directory.path}/legacy-pending');
  bool _newAccount = false;

  static Future<AccountStorage> forAccount(String id) async => AccountStorage(await getApplicationSupportDirectory(), id);

  Future<AppDatabase> open() async {
    _newAccount = !await databaseFile.exists();
    await directory.create(recursive: true);
    if (_newAccount && !await _owner.exists() && (await legacyDatabase.exists() || await File('${root.path}/local_state.json').exists())) {
      await _pending.writeAsString('awaiting owner choice', flush: true);
    }
    return AppDatabase.inDirectory(directory);
  }

  /// An unowned legacy database must only be imported by an explicit choice.
  Future<bool> get offerLegacyImport async =>
      (_newAccount || await _pending.exists()) &&
      !await _reviewed.exists() &&
      !await _owner.exists() &&
      (await legacyDatabase.exists() || await File('${root.path}/local_state.json').exists());

  Future<void> keepLegacySeparate() async => _reviewed.writeAsString('kept separate', flush: true);

  /// Copies a consistent SQLite snapshot, including committed WAL contents.
  /// The old database, JSON and DPAPI key are kept intact for rollback.
  Future<void> importLegacy(AppDatabase target) async {
    if (!await offerLegacyImport) throw StateError('Legacy import is not available');
    if (await legacyDatabase.exists()) {
      final temp = await Directory.systemTemp.createTemp('focus_legacy_snapshot');
      try {
        final copy = File('${temp.path}/legacy.sqlite');
        final original = sqlite3.open(legacyDatabase.path, mode: OpenMode.readOnly);
        try {
          original.execute('VACUUM INTO ?', [copy.path]);
        } finally {
          original.close();
        }
        await Snapshot.restore(target, Uint8List.fromList(gzip.encode(await copy.readAsBytes())));
      } finally {
        await temp.delete(recursive: true);
      }
    } else {
      final copy = await File('${root.path}/local_state.json').copy('${directory.path}/local_state.json');
      await (target.delete(target.keyValues)..where((t) => t.key.equals('localStateImported'))).go();
      // Re-import into the fresh account store after its defaults were loaded.
      await LocalStore.openDb(target, legacy: copy, strictLegacy: true);
    }
    // A migration must not silently turn on network uploads.
    await target.into(target.keyValues).insert(
          KeyValuesCompanion.insert(key: 'backupAuto', value: '0'),
          mode: InsertMode.insertOrReplace,
        );
    final oldKey = File('${root.path}/backup.key');
    if (await oldKey.exists()) await oldKey.copy(backupKeyFile.path);
    await _owner.writeAsString(jsonEncode({'accountId': accountId}), flush: true);
    await _reviewed.writeAsString('imported', flush: true);
  }
}

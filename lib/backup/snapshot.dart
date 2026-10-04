import 'dart:io';
import 'dart:typed_data';

import 'package:drift/native.dart';
import 'package:sqlite3/sqlite3.dart';

import '../db/database.dart';
import 'backup_crypto.dart';

/// Copies of the local database for backups.
class Snapshot {
  /// A consistent, compressed copy of [db] (VACUUM INTO a temp file).
  static Future<Uint8List> capture(AppDatabase db) async {
    final dir = await Directory.systemTemp.createTemp('fokus_snap');
    try {
      final file = File('${dir.path}${Platform.pathSeparator}snapshot.sqlite');
      await db.customStatement('VACUUM INTO ?', [file.path]);
      return Uint8List.fromList(gzip.encode(await file.readAsBytes()));
    } finally {
      await dir.delete(recursive: true);
    }
  }

  /// Replaces every table of [db] with the contents of [compressed].
  ///
  /// The backup is first opened as its own database, which runs the normal
  /// migrations, so a backup from an older version fits the current schema.
  /// The copy then happens in one transaction: either all of it or nothing.
  static Future<void> restore(AppDatabase db, Uint8List compressed) async {
    final List<int> raw;
    try {
      raw = gzip.decode(compressed);
    } catch (_) {
      throw BackupException('Zaxira fayli buzilgan.');
    }
    final dir = await Directory.systemTemp.createTemp('fokus_restore');
    try {
      final file = File('${dir.path}${Platform.pathSeparator}restore.sqlite');
      await file.writeAsBytes(raw, flush: true);

      final version = await _userVersion(file);
      if (version > db.schemaVersion) {
        throw BackupException('Bu zaxira nusxasi Fokus’ning yangiroq versiyasida yaratilgan. Ilovani yangilang.');
      }
      // Bring the copy up to the current schema.
      final copy = AppDatabase(NativeDatabase(file));
      try {
        await copy.customSelect('SELECT 1').get();
      } finally {
        await copy.close();
      }

      await db.customStatement('ATTACH DATABASE ? AS bak', [file.path]);
      try {
        await db.transaction(() async {
          for (final table in db.allTables) {
            final name = table.actualTableName;
            final cols = [for (final c in table.$columns) '"${c.name}"'].join(', ');
            await db.customStatement('DELETE FROM main."$name"');
            await db.customStatement('INSERT INTO main."$name" ($cols) SELECT $cols FROM bak."$name"');
          }
        });
      } finally {
        await db.customStatement('DETACH DATABASE bak');
      }
      db.markTablesUpdated(db.allTables);
    } on BackupException {
      rethrow;
    } catch (e) {
      throw BackupException('Zaxira nusxasini tiklab bo‘lmadi: $e');
    } finally {
      await dir.delete(recursive: true);
    }
  }

  /// Read-only, with plain sqlite3: opening it through drift could rewrite
  /// the version before we look at it.
  static Future<int> _userVersion(File file) async {
    try {
      final raw = sqlite3.open(file.path, mode: OpenMode.readOnly);
      try {
        return raw.select('PRAGMA user_version').first.values.first as int;
      } finally {
        raw.close();
      }
    } catch (_) {
      throw BackupException('Zaxira fayli buzilgan.');
    }
  }
}

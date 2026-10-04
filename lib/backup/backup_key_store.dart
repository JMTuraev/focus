import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';

import '../tdlib/db_key.dart' show Dpapi;
import 'backup_crypto.dart';

/// Where the key derived from the backup password is kept on this PC, so
/// backups do not ask for the password every time. Restoring on another PC
/// needs the password itself.
abstract class BackupKeyStore {
  Future<BackupKey?> load();
  Future<void> save(BackupKey key);
  Future<void> clear();
}

/// `backup.key` in the app support folder, encrypted with Windows DPAPI for
/// the current user (not inside fokus.sqlite, which is what gets backed up).
class DpapiBackupKeyStore implements BackupKeyStore {
  static const _entropy = 'fokus-backup-key-v1';

  Future<File> _file() async {
    final dir = await getApplicationSupportDirectory();
    return File('${dir.path}${Platform.pathSeparator}backup.key');
  }

  @override
  Future<BackupKey?> load() async {
    try {
      final f = await _file();
      if (!await f.exists()) return null;
      final plain = Dpapi.unprotect(await f.readAsBytes(), entropy: _entropy);
      final j = jsonDecode(utf8.decode(plain)) as Map<String, dynamic>;
      return BackupKey(
        base64Decode(j['key'] as String),
        base64Decode(j['salt'] as String),
        KdfParams.fromJson(j['kdf'] as Map<String, dynamic>),
      );
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> save(BackupKey key) async {
    final f = await _file();
    await f.parent.create(recursive: true);
    final plain = Uint8List.fromList(utf8.encode(jsonEncode({
      'key': base64Encode(key.key),
      'salt': base64Encode(key.salt),
      'kdf': key.params.toJson(),
    })));
    await f.writeAsBytes(Dpapi.protect(plain, entropy: _entropy), flush: true);
  }

  @override
  Future<void> clear() async {
    final f = await _file();
    if (await f.exists()) await f.delete();
  }
}

/// Test / mock store.
class MemoryBackupKeyStore implements BackupKeyStore {
  BackupKey? key;

  @override
  Future<BackupKey?> load() async => key;

  @override
  Future<void> save(BackupKey key) async => this.key = key;

  @override
  Future<void> clear() async => key = null;
}

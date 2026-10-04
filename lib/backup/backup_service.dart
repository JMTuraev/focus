import 'dart:async';

import 'package:drift/drift.dart' show InsertMode;
import 'package:flutter/foundation.dart';

import '../data/format.dart';
import '../data/meeting_parser.dart';
import '../db/database.dart';
import 'backup_crypto.dart';
import 'backup_key_store.dart';
import 'backup_transport.dart';
import 'snapshot.dart';

/// The backup was made with another password than the one on this PC.
class NeedPasswordException extends BackupException {
  NeedPasswordException() : super('Bu nusxa boshqa parol bilan shifrlangan. Parolni kiriting.');
}

/// Encrypted backups of fokus.sqlite to the user's Saved Messages.
///
/// The key comes from the backup password (Argon2id) and is kept on this PC
/// with DPAPI, so backups need no password; restoring on another PC does.
class BackupService extends ChangeNotifier {
  BackupService({
    required this.db,
    required this.transport,
    required this.keys,
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  final AppDatabase db;
  final BackupTransport transport;
  final BackupKeyStore keys;
  final DateTime Function() _clock;

  static const tag = '#fokus_backup';
  static const minPasswordLength = 8;
  static const _lastKey = 'backupLastAt';
  static const _autoKey = 'backupAuto';
  static const autoEvery = Duration(hours: 24);

  /// Argon2id settings for new passwords (tests use lighter ones).
  @visibleForTesting
  static KdfParams kdf = const KdfParams();

  BackupKey? _key;
  bool loaded = false;
  bool busy = false;

  /// Upload progress 0..1 while [busy], or null while preparing.
  double? progress;
  String? status;
  String? lastError;
  DateTime? lastBackupAt;
  bool autoDaily = false;
  Timer? _timer;

  bool get hasPassword => _key != null;

  Future<void> init() async {
    _key = await keys.load();
    lastBackupAt = DateTime.tryParse(await _get(_lastKey) ?? '');
    autoDaily = await _get(_autoKey) == '1';
    loaded = true;
    notifyListeners();
  }

  Future<String?> _get(String key) async =>
      (await (db.select(db.keyValues)..where((t) => t.key.equals(key))).getSingleOrNull())?.value;

  Future<void> _set(String key, String value) =>
      db.into(db.keyValues).insert(KeyValuesCompanion.insert(key: key, value: value), mode: InsertMode.insertOrReplace);

  /// Sets (or changes) the backup password. Old backups keep their password.
  Future<void> setPassword(String password) async {
    if (password.length < minPasswordLength) {
      throw BackupException('Parol kamida $minPasswordLength ta belgidan iborat bo‘lsin.');
    }
    final key = await BackupCrypto.deriveKey(password, params: kdf);
    await keys.save(key);
    _key = key;
    notifyListeners();
  }

  Future<void> setAutoDaily(bool v) async {
    autoDaily = v;
    await _set(_autoKey, v ? '1' : '0');
    notifyListeners();
    if (v) unawaited(maybeAutoBackup());
  }

  static String fileName(DateTime t) =>
      'fokus-backup-${t.year}-${Fmt.two(t.month)}-${Fmt.two(t.day)}_${Fmt.two(t.hour)}${Fmt.two(t.minute)}.fokusbak';

  /// Encrypts the database and uploads it. Throws [BackupException].
  Future<void> backupNow() async {
    final key = _key;
    if (key == null) throw BackupException('Avval zaxira parolini o‘rnating.');
    if (busy) return;
    busy = true;
    progress = null;
    status = 'Tayyorlanmoqda…';
    lastError = null;
    notifyListeners();
    try {
      final plain = await Snapshot.capture(db);
      final data = await BackupCrypto.encrypt(plain, key);
      final now = _clock();
      status = 'Saved Messages’ga yuklanmoqda…';
      notifyListeners();
      await transport.upload(
        data,
        fileName: fileName(now),
        caption: '$tag Focus zaxira nusxasi · ${MeetingParser.label(now)}\n'
            'Shifrlangan: faqat backup parolingiz bilan ochiladi.',
        progress: (p) {
          progress = p;
          notifyListeners();
        },
      );
      lastBackupAt = now;
      await _set(_lastKey, now.toIso8601String());
    } on BackupException catch (e) {
      lastError = e.message;
      rethrow;
    } catch (e) {
      lastError = 'Zaxira nusxasini saqlab bo‘lmadi: $e';
      throw BackupException(lastError!);
    } finally {
      busy = false;
      progress = null;
      status = null;
      notifyListeners();
    }
  }

  Future<List<BackupEntry>> list() => transport.list();

  /// Replaces the local data with [entry]. Without [password] the key on
  /// this PC is used; throws [NeedPasswordException] if it does not fit.
  Future<void> restore(BackupEntry entry, {String? password}) async {
    if (busy) return;
    busy = true;
    status = 'Yuklab olinmoqda…';
    progress = null;
    notifyListeners();
    try {
      final data = await transport.download(entry);
      status = 'Tiklanmoqda…';
      notifyListeners();
      final Uint8List plain;
      if (password != null) {
        plain = await BackupCrypto.decryptWithPassword(data, password);
      } else {
        final (salt, params) = BackupCrypto.readHeader(data);
        final key = _key;
        if (key == null || !listEquals(key.salt, salt) || key.params != params) throw NeedPasswordException();
        plain = await BackupCrypto.decrypt(data, key);
      }
      await Snapshot.restore(db, plain);
      // Settings of this PC win over the ones inside the backup.
      if (lastBackupAt != null) await _set(_lastKey, lastBackupAt!.toIso8601String());
      await _set(_autoKey, autoDaily ? '1' : '0');
    } finally {
      busy = false;
      status = null;
      notifyListeners();
    }
  }

  /// Daily automatic backup while Focus runs (checked hourly).
  void startAuto() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(hours: 1), (_) => maybeAutoBackup());
    unawaited(maybeAutoBackup());
  }

  Future<void> maybeAutoBackup() async {
    if (!autoDaily || !hasPassword || busy) return;
    final last = lastBackupAt;
    if (last != null && _clock().difference(last) < autoEvery) return;
    try {
      await backupNow();
    } catch (e) {
      debugPrint('auto backup: $e');
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

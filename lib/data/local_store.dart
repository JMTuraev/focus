import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

/// Fokus-only data about chats, kept on this PC in `local_state.json`:
/// - which collection a chat belongs to;
/// - how many unread messages the user has already seen in Fokus.
///
/// Fokus never calls viewMessages, so Telegram's unread counters stay as they
/// are; the "seen" numbers here only hide the badge inside Fokus.
/// Phase 2 moves this into the SQLite (drift) database.
class LocalStore {
  LocalStore._(this._file, this._collections, this._seen);

  /// Not persisted (mock data and tests).
  LocalStore.memory() : this._(null, {}, {});

  final File? _file;
  final Map<String, String> _collections;
  final Map<String, int> _seen;
  Timer? _saveTimer;

  static Future<LocalStore> open() async {
    File? file;
    final collections = <String, String>{};
    final seen = <String, int>{};
    try {
      final dir = await getApplicationSupportDirectory();
      file = File('${dir.path}${Platform.pathSeparator}local_state.json');
      if (await file.exists()) {
        final json = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
        (json['collections'] as Map<String, dynamic>? ?? {}).forEach((k, v) => collections[k] = v as String);
        (json['seen'] as Map<String, dynamic>? ?? {}).forEach((k, v) => seen[k] = v as int);
      }
    } catch (_) {
      // A broken file is not fatal: start empty.
    }
    return LocalStore._(file, collections, seen);
  }

  String? collectionOf(String chatId) => _collections[chatId];

  void setCollection(String chatId, String collectionId) {
    _collections[chatId] = collectionId;
    _scheduleSave();
  }

  /// Unread messages already seen in Fokus for [chatId].
  int seenOf(String chatId) => _seen[chatId] ?? 0;

  void setSeen(String chatId, int count) {
    if (_seen[chatId] == count) return;
    if (count == 0) {
      _seen.remove(chatId);
    } else {
      _seen[chatId] = count;
    }
    _scheduleSave();
  }

  void _scheduleSave() {
    if (_file == null) return;
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(milliseconds: 400), _save);
  }

  Future<void> _save() async {
    try {
      await _file!.parent.create(recursive: true);
      await _file.writeAsString(jsonEncode({'collections': _collections, 'seen': _seen}));
    } catch (_) {
      // Best effort.
    }
  }

  Future<void> flush() async {
    if (_saveTimer?.isActive ?? false) {
      _saveTimer!.cancel();
      await _save();
    }
  }
}

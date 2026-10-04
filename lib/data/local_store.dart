import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import 'models.dart';

/// Fokus-only data about chats, kept on this PC in `local_state.json`:
/// - the user's collections (name, icon, order);
/// - which collection a chat belongs to;
/// - how many unread messages the user has already seen in Fokus.
///
/// Fokus never calls viewMessages, so Telegram's unread counters stay as they
/// are; the "seen" numbers here only hide the badge inside Fokus.
/// Phase 2 moves this into the SQLite (drift) database.
class LocalStore {
  LocalStore._(this._file, this._defs, this._assigned, this._seen);

  /// Not persisted (mock data and tests); starts with the default collections.
  LocalStore.memory() : this._(null, List.of(kDefaultCollections), {}, {});

  final File? _file;
  final List<Collection> _defs;
  final Map<String, String> _assigned;
  final Map<String, int> _seen;
  Timer? _saveTimer;

  static Future<LocalStore> open() async {
    final dir = await getApplicationSupportDirectory();
    return openAt(File('${dir.path}${Platform.pathSeparator}local_state.json'));
  }

  @visibleForTesting
  static Future<LocalStore> openAt(File file) async {
    var defs = List.of(kDefaultCollections);
    final assigned = <String, String>{};
    final seen = <String, int>{};
    try {
      if (await file.exists()) {
        final json = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
        final list = json['collectionList'] as List?;
        if (list != null) defs = [for (final j in list) Collection.fromJson(j as Map<String, dynamic>)];
        (json['collections'] as Map<String, dynamic>? ?? {}).forEach((k, v) => assigned[k] = v as String);
        (json['seen'] as Map<String, dynamic>? ?? {}).forEach((k, v) => seen[k] = v as int);
      }
    } catch (_) {
      // A broken file is not fatal: start with defaults.
    }
    return LocalStore._(file, defs, assigned, seen);
  }

  // ---- collections ----

  List<Collection> get collections => List.unmodifiable(_defs);

  Collection? collectionById(String id) {
    for (final c in _defs) {
      if (c.id == id) return c;
    }
    return null;
  }

  Collection addCollection(String label, String iconKey) {
    final c = Collection('c${DateTime.now().microsecondsSinceEpoch}', label.trim(), iconKey);
    _defs.add(c);
    _scheduleSave();
    return c;
  }

  void updateCollection(String id, {required String label, required String iconKey}) {
    final i = _defs.indexWhere((c) => c.id == id);
    if (i < 0) return;
    _defs[i] = Collection(id, label.trim(), iconKey);
    _scheduleSave();
  }

  /// Removes a collection; its chats become unsorted.
  void deleteCollection(String id) {
    _defs.removeWhere((c) => c.id == id);
    _assigned.updateAll((_, v) => v == id ? '' : v);
    _scheduleSave();
  }

  /// Moves the collection at [from] to position [to] (rail order).
  void moveCollection(int from, int to) {
    if (from < 0 || from >= _defs.length) return;
    final c = _defs.removeAt(from);
    _defs.insert(to.clamp(0, _defs.length), c);
    _scheduleSave();
  }

  // ---- chats ----

  /// The collection chosen for [chatId]: null = never chosen, '' = unsorted.
  String? collectionOf(String chatId) => _assigned[chatId];

  void setCollection(String chatId, String collectionId) {
    _assigned[chatId] = collectionId;
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

  // ---- saving ----

  void _scheduleSave() {
    if (_file == null) return;
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(milliseconds: 400), _save);
  }

  Future<void> _save() async {
    try {
      await _file!.parent.create(recursive: true);
      await _file.writeAsString(jsonEncode({
        'collectionList': [for (final c in _defs) c.toJson()],
        'collections': _assigned,
        'seen': _seen,
      }));
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

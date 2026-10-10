import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' show Expression, InsertMode, OrderingTerm, StringExpressionOperators, Value;
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import '../db/database.dart';
import 'models.dart';

/// Focus-only data about chats, kept in the local database (`fokus.sqlite`):
/// - the user's collections (name, icon, order);
/// - which collection a chat belongs to;
/// - how many unread messages the user has already seen in Focus.
///
/// Focus never calls viewMessages, so Telegram's unread counters stay as they
/// are; the "seen" numbers here only hide the badge inside Focus.
///
/// Everything is held in memory for synchronous reads; every change is
/// written to the database in order (see [flush]). Until phase 2 this lived
/// in `local_state.json`; that file is imported once and kept as `.bak`.
class LocalStore {
  LocalStore._(this._db, this._defs, this._assigned, this._seen, [Map<String, String>? names])
      : _fileNames = names ?? {},
        _marks = {},
        _saved = {};

  /// Not persisted (mock data and tests); starts with the default collections.
  LocalStore.memory() : this._(null, List.of(kDefaultCollections), {}, {});

  final AppDatabase? _db;
  final List<Collection> _defs;
  final Map<String, String> _assigned;
  final Map<String, int> _seen;

  /// Focus-only file names by "chatId:messageId".
  final Map<String, String> _fileNames;

  /// Favorites and tags by "chatId:messageId".
  final Map<String, FileMark> _marks;

  /// Saved items ("Fayllar") by "chatId:messageId".
  final Map<String, SavedItem> _saved;
  final Map<String, String> _drafts = {};
  final Map<String, ReplyInfo> _replyDrafts = {};
  final Map<String, int> _draftVersions = {};
  Future<void> _writes = Future.value();

  static const _importedKey = 'localStateImported';
  static const _draftPrefix = 'chatDraft:';
  static const _replyDraftPrefix = 'chatReplyDraft:';

  /// Opens the store on [db], importing `local_state.json` the first time.
  static Future<LocalStore> open(AppDatabase db) async {
    File? legacy;
    try {
      final dir = await getApplicationSupportDirectory();
      legacy = File('${dir.path}${Platform.pathSeparator}local_state.json');
    } catch (_) {}
    return openDb(db, legacy: legacy);
  }

  static Future<LocalStore> openDb(AppDatabase db, {File? legacy, bool strictLegacy = false}) async {
    final imported = await (db.select(db.keyValues)..where((t) => t.key.equals(_importedKey))).getSingleOrNull();
    if (imported == null) await _import(db, legacy, strict: strictLegacy);
    final store = LocalStore._(db, [], {}, {});
    await store.reload();
    return store;
  }

  /// Re-reads everything from the database (also after a backup restore).
  Future<void> reload() async {
    final db = _db;
    if (db == null) return;
    await flush();
    final drafts = {
      for (final r in await (db.select(db.keyValues)..where((t) => t.key.like('$_draftPrefix%'))).get())
        r.key.substring(_draftPrefix.length): r.value,
    };
    // Invalidate pending sends when a backup replaces local drafts.
    for (final id in {..._draftVersions.keys, ..._drafts.keys, ...drafts.keys}) {
      _draftVersions[id] = draftVersion(id) + 1;
    }
    _drafts
      ..clear()
      ..addAll(drafts);
    _replyDrafts.clear();
    for (final r in await (db.select(db.keyValues)..where((t) => t.key.like('$_replyDraftPrefix%'))).get()) {
      try {
        final value = jsonDecode(r.value) as Map<String, dynamic>;
        final id = r.key.substring(_replyDraftPrefix.length);
        if (value['chatId'] != id || value['messageId'] is! String || (value['messageId'] as String).isEmpty) continue;
        _replyDrafts[id] = ReplyInfo(
            chatId: value['chatId'] as String,
            messageId: value['messageId'] as String,
            author: value['author'] as String,
            text: value['text'] as String);
        _draftVersions[id] = draftVersion(id) + 1;
      } catch (_) {/* A damaged reply draft must not prevent opening local data. */}
    }
    final defs = [
      for (final r in await (db.select(db.collections)..orderBy([(t) => OrderingTerm.asc(t.position)])).get())
        Collection(r.id, r.label, r.icon, r.color),
    ];
    final assigned = {for (final r in await db.select(db.chatCollections).get()) r.chatId: r.collectionId};
    final seen = {for (final r in await db.select(db.seenCounts).get()) r.chatId: r.count};
    final names = {for (final r in await db.select(db.fileNames).get()) '${r.chatId}:${r.messageId}': r.name};
    final marks = {
      for (final r in await db.select(db.fileMarks).get())
        '${r.chatId}:${r.messageId}': FileMark(
          chatId: r.chatId,
          messageId: r.messageId,
          kind: r.kind,
          favorite: r.favorite,
          tags: _decodeTags(r.tags),
          updatedAt: r.updatedAt,
        ),
    };
    _defs
      ..clear()
      ..addAll(defs);
    _assigned
      ..clear()
      ..addAll(assigned);
    _seen
      ..clear()
      ..addAll(seen);
    _fileNames
      ..clear()
      ..addAll(names);
    final saved = {
      for (final r in await db.select(db.savedItems).get())
        '${r.chatId}:${r.messageId}': SavedItem(
          chatId: r.chatId,
          messageId: r.messageId,
          kind: SavedKind.values.asNameMap()[r.kind] ?? SavedKind.text,
          chatTitle: r.chatTitle,
          text: r.body,
          fileName: r.fileName,
          size: r.size,
          date: r.date,
          savedAt: r.savedAt,
        ),
    };
    _marks
      ..clear()
      ..addAll(marks);
    _saved
      ..clear()
      ..addAll(saved);
  }

  // ---- saved items ("Fayllar") ----

  /// Newest message first.
  List<SavedItem> get savedItems => _saved.values.toList()..sort((a, b) => b.when.compareTo(a.when));

  SavedItem? savedOf(String chatId, String messageId) => _saved['$chatId:$messageId'];

  void addSaved(SavedItem item) {
    _saved[item.key] = item;
    _write((db) => db.into(db.savedItems).insert(
        SavedItemsCompanion.insert(
          chatId: item.chatId,
          messageId: item.messageId,
          kind: item.kind.name,
          chatTitle: item.chatTitle,
          body: Value(item.text),
          fileName: Value(item.fileName),
          size: Value(item.size),
          date: Value(item.date),
          savedAt: item.savedAt,
        ),
        mode: InsertMode.insertOrReplace));
  }

  /// Takes an item out of "Fayllar" with its marks and Focus-only name.
  void removeSaved(String chatId, String messageId) {
    if (_saved.remove('$chatId:$messageId') == null) return;
    _write((db) => (db.delete(db.savedItems)..where((t) => Expression.and([t.chatId.equals(chatId), t.messageId.equals(messageId)]))).go());
    final mark = _marks['$chatId:$messageId'];
    if (mark != null) {
      setMark(FileMark(chatId: chatId, messageId: messageId, kind: mark.kind, updatedAt: DateTime.now()));
    }
    setFileName(chatId, messageId, '');
  }

  static List<String> _decodeTags(String json) {
    try {
      return [for (final t in jsonDecode(json) as List) '$t'];
    } catch (_) {
      return const [];
    }
  }

  // ---- file marks (favorites, tags) ----

  FileMark? markOf(String chatId, String messageId) => _marks['$chatId:$messageId'];

  /// Every mark, newest change first.
  List<FileMark> get marks => _marks.values.toList()..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

  /// Tags in use with how many files carry each, most used first.
  List<(String, int)> get tagCounts {
    final counts = <String, int>{};
    final shown = <String, String>{};
    for (final m in _marks.values) {
      for (final t in m.tags) {
        final k = t.toLowerCase();
        counts[k] = (counts[k] ?? 0) + 1;
        shown.putIfAbsent(k, () => t);
      }
    }
    final list = [for (final e in counts.entries) (shown[e.key]!, e.value)];
    list.sort((a, b) => b.$2 != a.$2 ? b.$2.compareTo(a.$2) : a.$1.toLowerCase().compareTo(b.$1.toLowerCase()));
    return list;
  }

  /// Writes [mark]; an empty one (no favorite, no tags) is deleted.
  void setMark(FileMark mark) {
    final key = '${mark.chatId}:${mark.messageId}';
    if (mark.isEmpty) {
      if (_marks.remove(key) == null) return;
      _write((db) =>
          (db.delete(db.fileMarks)..where((t) => Expression.and([t.chatId.equals(mark.chatId), t.messageId.equals(mark.messageId)]))).go());
      return;
    }
    _marks[key] = mark;
    _write((db) => db.into(db.fileMarks).insert(
        FileMarksCompanion.insert(
          chatId: mark.chatId,
          messageId: mark.messageId,
          kind: mark.kind,
          favorite: Value(mark.favorite),
          tags: Value(jsonEncode(mark.tags)),
          updatedAt: mark.updatedAt,
        ),
        mode: InsertMode.insertOrReplace));
  }

  // ---- file names ----

  /// The name Focus shows for a file, or null to use Telegram's.
  String? fileName(String chatId, String messageId) => _fileNames['$chatId:$messageId'];

  /// Renames a file in Focus only; an empty [name] goes back to Telegram's.
  void setFileName(String chatId, String messageId, String name) {
    final key = '$chatId:$messageId';
    final n = name.trim();
    if (n.isEmpty) {
      if (_fileNames.remove(key) == null) return;
      _write(
          (db) => (db.delete(db.fileNames)..where((t) => Expression.and([t.chatId.equals(chatId), t.messageId.equals(messageId)]))).go());
      return;
    }
    if (_fileNames[key] == n) return;
    _fileNames[key] = n;
    _write((db) => db
        .into(db.fileNames)
        .insert(FileNamesCompanion.insert(chatId: chatId, messageId: messageId, name: n), mode: InsertMode.insertOrReplace));
  }

  /// First start on the database: take collections, assignments and seen
  /// counts from local_state.json if there is one, otherwise the defaults.
  static Future<void> _import(AppDatabase db, File? legacy, {bool strict = false}) async {
    var defs = List.of(kDefaultCollections);
    final assigned = <String, String>{};
    final seen = <String, int>{};
    var fromFile = false;
    try {
      if (legacy != null && await legacy.exists()) {
        final json = jsonDecode(await legacy.readAsString()) as Map<String, dynamic>;
        final list = json['collectionList'] as List?;
        if (list != null) defs = [for (final j in list) Collection.fromJson(j as Map<String, dynamic>)];
        (json['collections'] as Map<String, dynamic>? ?? {}).forEach((k, v) => assigned[k] = v as String);
        (json['seen'] as Map<String, dynamic>? ?? {}).forEach((k, v) => seen[k] = v as int);
        fromFile = true;
      }
    } catch (e) {
      if (strict) rethrow;
      debugPrint('local_state.json import: $e');
    }

    await db.transaction(() async {
      await db.batch((b) {
        b.insertAll(
          db.collections,
          [
            for (var i = 0; i < defs.length; i++)
              CollectionsCompanion.insert(
                  id: defs[i].id, label: defs[i].label, icon: Value(defs[i].iconKey), color: Value(defs[i].colorKey), position: Value(i)),
          ],
          mode: InsertMode.insertOrReplace,
        );
        b.insertAll(
          db.chatCollections,
          [for (final e in assigned.entries) ChatCollectionsCompanion.insert(chatId: e.key, collectionId: e.value)],
          mode: InsertMode.insertOrReplace,
        );
        b.insertAll(
          db.seenCounts,
          [for (final e in seen.entries) SeenCountsCompanion.insert(chatId: e.key, count: e.value)],
          mode: InsertMode.insertOrReplace,
        );
        b.insert(db.keyValues, KeyValuesCompanion.insert(key: _importedKey, value: fromFile ? 'json' : 'defaults'),
            mode: InsertMode.insertOrReplace);
      });
    });

    // Keep the old file as a backup instead of deleting it.
    if (fromFile) {
      try {
        await legacy!.rename('${legacy.path}.bak');
      } catch (e) {
        debugPrint('local_state.json rename: $e');
      }
    }
  }

  /// Queues a database write after the previous ones.
  void _write(Future<void> Function(AppDatabase db) op) {
    final db = _db;
    if (db == null) return;
    _writes = _writes.then((_) => op(db)).catchError((Object e) => debugPrint('LocalStore write: $e'));
  }

  // ---- local drafts ----

  /// Drafts stay in the local store and are never synced to Telegram.
  String draftOf(String chatId) => _drafts[chatId] ?? '';
  ReplyInfo? replyDraftOf(String chatId) => _replyDrafts[chatId];

  void setReplyDraft(String chatId, ReplyInfo? reply) {
    if (reply != null && reply.chatId != chatId) throw ArgumentError('Reply drafts must belong to the same chat');
    if (identical(_replyDrafts[chatId], reply)) return;
    _draftVersions[chatId] = draftVersion(chatId) + 1;
    if (reply == null) {
      _replyDrafts.remove(chatId);
      _write((db) => (db.delete(db.keyValues)..where((t) => t.key.equals('$_replyDraftPrefix$chatId'))).go());
    } else {
      _replyDrafts[chatId] = reply;
      _write((db) => db.into(db.keyValues).insert(
          KeyValuesCompanion.insert(
              key: '$_replyDraftPrefix$chatId',
              value: jsonEncode({'chatId': reply.chatId, 'messageId': reply.messageId, 'author': reply.author, 'text': reply.text})),
          mode: InsertMode.insertOrReplace));
    }
  }

  /// Changes even when the user types and then clears back to the same text.
  int draftVersion(String chatId) => _draftVersions[chatId] ?? 0;

  void setDraft(String chatId, String text) {
    if (draftOf(chatId) == text) return;
    _draftVersions[chatId] = draftVersion(chatId) + 1;
    if (text.isEmpty) {
      _drafts.remove(chatId);
      _write((db) => (db.delete(db.keyValues)..where((t) => t.key.equals('$_draftPrefix$chatId'))).go());
    } else {
      _drafts[chatId] = text;
      _write((db) => db.into(db.keyValues).insert(
            KeyValuesCompanion.insert(key: '$_draftPrefix$chatId', value: text),
            mode: InsertMode.insertOrReplace,
          ));
    }
  }

  // ---- collections ----

  List<Collection> get collections => List.unmodifiable(_defs);

  Collection? collectionById(String id) {
    for (final c in _defs) {
      if (c.id == id) return c;
    }
    return null;
  }

  Collection addCollection(String label, String iconKey, {String colorKey = ''}) {
    final c = Collection('c${DateTime.now().microsecondsSinceEpoch}', label.trim(), iconKey, colorKey);
    _defs.add(c);
    final position = _defs.length - 1;
    _write((db) => db.into(db.collections).insert(CollectionsCompanion.insert(
        id: c.id, label: c.label, icon: Value(c.iconKey), color: Value(c.colorKey), position: Value(position))));
    return c;
  }

  void updateCollection(String id, {required String label, required String iconKey, String colorKey = ''}) {
    final i = _defs.indexWhere((c) => c.id == id);
    if (i < 0) return;
    _defs[i] = Collection(id, label.trim(), iconKey, colorKey);
    final c = _defs[i];
    _write((db) => (db.update(db.collections)..where((t) => t.id.equals(id)))
        .write(CollectionsCompanion(label: Value(c.label), icon: Value(c.iconKey), color: Value(c.colorKey))));
  }

  /// Removes a collection; its chats become unsorted.
  void deleteCollection(String id) {
    _defs.removeWhere((c) => c.id == id);
    _assigned.updateAll((_, v) => v == id ? '' : v);
    _write((db) => db.transaction(() async {
          await (db.delete(db.collections)..where((t) => t.id.equals(id))).go();
          await (db.update(db.chatCollections)..where((t) => t.collectionId.equals(id)))
              .write(const ChatCollectionsCompanion(collectionId: Value('')));
        }));
    _savePositions();
  }

  /// Moves the collection at [from] to position [to] (rail order).
  void moveCollection(int from, int to) {
    if (from < 0 || from >= _defs.length) return;
    final c = _defs.removeAt(from);
    _defs.insert(to.clamp(0, _defs.length), c);
    _savePositions();
  }

  void _savePositions() {
    final order = [for (final c in _defs) c.id];
    _write((db) => db.batch((b) {
          for (var i = 0; i < order.length; i++) {
            b.update(db.collections, CollectionsCompanion(position: Value(i)), where: (t) => t.id.equals(order[i]));
          }
        }));
  }

  // ---- chats ----

  /// The collection chosen for [chatId]: null = never chosen, '' = unsorted.
  String? collectionOf(String chatId) => _assigned[chatId];

  void setCollection(String chatId, String collectionId) {
    if (_assigned[chatId] == collectionId) return;
    _assigned[chatId] = collectionId;
    _write((db) => db
        .into(db.chatCollections)
        .insert(ChatCollectionsCompanion.insert(chatId: chatId, collectionId: collectionId), mode: InsertMode.insertOrReplace));
  }

  /// Unread messages already seen in Focus for [chatId].
  int seenOf(String chatId) => _seen[chatId] ?? 0;

  void setSeen(String chatId, int count) {
    if ((_seen[chatId] ?? 0) == count) return;
    if (count == 0) {
      _seen.remove(chatId);
      _write((db) => (db.delete(db.seenCounts)..where((t) => t.chatId.equals(chatId))).go());
    } else {
      _seen[chatId] = count;
      _write((db) =>
          db.into(db.seenCounts).insert(SeenCountsCompanion.insert(chatId: chatId, count: count), mode: InsertMode.insertOrReplace));
    }
  }

  /// Waits until every change so far is in the database.
  Future<void> flush() => _writes;
}

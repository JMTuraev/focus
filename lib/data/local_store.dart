import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' show InsertMode, OrderingTerm, Value;
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
  LocalStore._(this._db, this._defs, this._assigned, this._seen);

  /// Not persisted (mock data and tests); starts with the default collections.
  LocalStore.memory() : this._(null, List.of(kDefaultCollections), {}, {});

  final AppDatabase? _db;
  final List<Collection> _defs;
  final Map<String, String> _assigned;
  final Map<String, int> _seen;
  Future<void> _writes = Future.value();

  static const _importedKey = 'localStateImported';

  /// Opens the store on [db], importing `local_state.json` the first time.
  static Future<LocalStore> open(AppDatabase db) async {
    File? legacy;
    try {
      final dir = await getApplicationSupportDirectory();
      legacy = File('${dir.path}${Platform.pathSeparator}local_state.json');
    } catch (_) {}
    return openDb(db, legacy: legacy);
  }

  @visibleForTesting
  static Future<LocalStore> openDb(AppDatabase db, {File? legacy}) async {
    final imported = await (db.select(db.keyValues)..where((t) => t.key.equals(_importedKey))).getSingleOrNull();
    if (imported == null) await _import(db, legacy);
    final store = LocalStore._(db, [], {}, {});
    await store.reload();
    return store;
  }

  /// Re-reads everything from the database (also after a backup restore).
  Future<void> reload() async {
    final db = _db;
    if (db == null) return;
    await flush();
    final defs = [
      for (final r in await (db.select(db.collections)..orderBy([(t) => OrderingTerm.asc(t.position)])).get())
        Collection(r.id, r.label, r.icon),
    ];
    final assigned = {for (final r in await db.select(db.chatCollections).get()) r.chatId: r.collectionId};
    final seen = {for (final r in await db.select(db.seenCounts).get()) r.chatId: r.count};
    _defs
      ..clear()
      ..addAll(defs);
    _assigned
      ..clear()
      ..addAll(assigned);
    _seen
      ..clear()
      ..addAll(seen);
  }

  /// First start on the database: take collections, assignments and seen
  /// counts from local_state.json if there is one, otherwise the defaults.
  static Future<void> _import(AppDatabase db, File? legacy) async {
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
      debugPrint('local_state.json import: $e');
    }

    await db.transaction(() async {
      await db.batch((b) {
        b.insertAll(
          db.collections,
          [
            for (var i = 0; i < defs.length; i++)
              CollectionsCompanion.insert(id: defs[i].id, label: defs[i].label, icon: Value(defs[i].iconKey), position: Value(i)),
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
    final position = _defs.length - 1;
    _write((db) => db.into(db.collections).insert(
          CollectionsCompanion.insert(id: c.id, label: c.label, icon: Value(c.iconKey), position: Value(position)),
        ));
    return c;
  }

  void updateCollection(String id, {required String label, required String iconKey}) {
    final i = _defs.indexWhere((c) => c.id == id);
    if (i < 0) return;
    _defs[i] = Collection(id, label.trim(), iconKey);
    final c = _defs[i];
    _write((db) => (db.update(db.collections)..where((t) => t.id.equals(id)))
        .write(CollectionsCompanion(label: Value(c.label), icon: Value(c.iconKey))));
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
      _write((db) => db
          .into(db.seenCounts)
          .insert(SeenCountsCompanion.insert(chatId: chatId, count: count), mode: InsertMode.insertOrReplace));
    }
  }

  /// Waits until every change so far is in the database.
  Future<void> flush() => _writes;
}

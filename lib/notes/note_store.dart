import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';

import '../db/database.dart';

/// Which notes the notes screen shows.
enum NoteFilter {
  all('Hammasi'),
  fromChats('Chatdan saqlangan'),
  checklists('Ro‘yxatlar');

  const NoteFilter(this.label);
  final String label;
}

/// Notes from the local database, kept in memory (pinned first, then the
/// most recently edited) and reloaded after every write.
class NoteStore extends ChangeNotifier {
  NoteStore(this.db) {
    _reload();
  }

  final AppDatabase db;
  bool _disposed = false;
  List<Note> _all = const [];
  bool loaded = false;

  List<Note> get all => _all;

  Note? byId(int id) {
    for (final n in _all) {
      if (n.id == id) return n;
    }
    return null;
  }

  static bool isEmpty({String title = '', String body = '', List<NoteItem> items = const []}) =>
      title.trim().isEmpty && body.trim().isEmpty && items.every((i) => i.text.trim().isEmpty);

  List<Note> filtered({NoteFilter filter = NoteFilter.all, String query = '', String? chatId}) {
    final q = query.trim().toLowerCase();
    return _all.where((n) {
      if (chatId != null && n.chatId != chatId) return false;
      if (filter == NoteFilter.fromChats && n.chatId == null) return false;
      if (filter == NoteFilter.checklists && !n.checklist) return false;
      if (q.isEmpty) return true;
      return n.title.toLowerCase().contains(q) ||
          n.body.toLowerCase().contains(q) ||
          n.items.any((i) => i.text.toLowerCase().contains(q)) ||
          (n.chatTitle ?? '').toLowerCase().contains(q);
    }).toList();
  }

  int countForChat(String chatId) => _all.where((n) => n.chatId == chatId).length;

  Future<int> add({
    String title = '',
    String body = '',
    List<NoteItem> items = const [],
    bool checklist = false,
    NoteColor color = NoteColor.none,
    bool pinned = false,
    String? chatId,
    String? chatTitle,
    String? messageId,
  }) async {
    final now = DateTime.now();
    final id = await db.into(db.notes).insert(NotesCompanion.insert(
          title: Value(title.trim()),
          body: Value(body.trim()),
          items: Value(_clean(items)),
          checklist: Value(checklist),
          color: Value(color),
          pinned: Value(pinned),
          chatId: Value(chatId),
          chatTitle: Value(chatTitle),
          messageId: Value(messageId),
          createdAt: now,
          updatedAt: now,
        ));
    await _reload();
    return id;
  }

  static List<NoteItem> _clean(List<NoteItem> items) =>
      [for (final i in items) if (i.text.trim().isNotEmpty) i.copyWith(text: i.text.trim())];

  Future<void> edit(
    int id, {
    String? title,
    String? body,
    List<NoteItem>? items,
    bool? checklist,
    NoteColor? color,
    bool? pinned,
  }) async {
    await (db.update(db.notes)..where((t) => t.id.equals(id))).write(NotesCompanion(
      title: title == null ? const Value.absent() : Value(title.trim()),
      body: body == null ? const Value.absent() : Value(body.trim()),
      items: items == null ? const Value.absent() : Value(_clean(items)),
      checklist: checklist == null ? const Value.absent() : Value(checklist),
      color: color == null ? const Value.absent() : Value(color),
      pinned: pinned == null ? const Value.absent() : Value(pinned),
      updatedAt: Value(DateTime.now()),
    ));
    await _reload();
  }

  /// Ticks or unticks one checklist line (from the card, without the editor).
  Future<void> toggleItem(int id, int index) async {
    final n = byId(id);
    if (n == null || index < 0 || index >= n.items.length) return;
    final items = [...n.items];
    items[index] = items[index].copyWith(done: !items[index].done);
    await edit(id, items: items);
  }

  /// Text ↔ checklist: lines become items and items become lines.
  static (String, List<NoteItem>) convert({required bool toChecklist, required String body, required List<NoteItem> items}) {
    if (toChecklist) {
      return ('', [for (final l in body.split('\n')) if (l.trim().isNotEmpty) NoteItem(l.trim())]);
    }
    return (items.map((i) => i.text).join('\n'), const []);
  }

  Future<void> remove(int id) async {
    await (db.delete(db.notes)..where((t) => t.id.equals(id))).go();
    await _reload();
  }

  Future<void> restore(Note n) async {
    await db.into(db.notes).insert(n, mode: InsertMode.insertOrReplace);
    await _reload();
  }

  /// Re-reads everything (after a backup was restored).
  Future<void> reload() => _reload();

  Future<void> _reload() async {
    final rows = await (db.select(db.notes)
          ..orderBy([
            (t) => OrderingTerm.desc(t.pinned),
            (t) => OrderingTerm.desc(t.updatedAt),
            (t) => OrderingTerm.desc(t.id),
          ]))
        .get();
    if (_disposed) return;
    _all = rows;
    loaded = true;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}

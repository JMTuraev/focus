import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';

import '../db/database.dart';

/// Calendar events from the local database, kept in memory (sorted by start)
/// and reloaded after every write, like TaskStore.
class EventStore extends ChangeNotifier {
  EventStore(this.db) {
    _reload();
  }

  final AppDatabase db;
  bool _disposed = false;
  List<Event> _all = const [];
  bool loaded = false;

  List<Event> get all => _all;

  Event? byId(int id) {
    for (final e in _all) {
      if (e.id == id) return e;
    }
    return null;
  }

  static DateTime day(DateTime d) => DateTime(d.year, d.month, d.day);

  /// Events that overlap [from, to), optionally only of one chat.
  List<Event> between(DateTime from, DateTime to, {String? chatId}) => _all
      .where((e) => e.start.isBefore(to) && e.end.isAfter(from) && (chatId == null || e.chatId == chatId))
      .toList();

  /// Events of one calendar day (all-day events included).
  List<Event> onDay(DateTime d, {String? chatId}) {
    final from = day(d);
    return between(from, from.add(const Duration(days: 1)), chatId: chatId);
  }

  /// Upcoming (not yet ended) events of [chatId].
  List<Event> upcomingForChat(String chatId, {DateTime? now}) {
    final n = now ?? DateTime.now();
    return _all.where((e) => e.chatId == chatId && e.end.isAfter(n)).toList();
  }

  /// Events still ahead today (rail badge).
  int remainingToday({DateTime? now}) {
    final n = now ?? DateTime.now();
    final end = day(n).add(const Duration(days: 1));
    return _all.where((e) => !e.allDay && e.start.isAfter(n) && e.start.isBefore(end)).length;
  }

  Future<int> add({
    required String title,
    required DateTime start,
    required DateTime end,
    bool allDay = false,
    String note = '',
    int? remindBefore,
    String? chatId,
    String? chatTitle,
    String? messageId,
    String? messageText,
  }) async {
    final now = DateTime.now();
    final (s, e) = _normalize(start, end, allDay);
    final id = await db.into(db.events).insert(EventsCompanion.insert(
          title: title.trim(),
          start: s,
          end: e,
          allDay: Value(allDay),
          note: Value(note.trim()),
          remindBefore: Value(remindBefore),
          chatId: Value(chatId),
          chatTitle: Value(chatTitle),
          messageId: Value(messageId),
          messageText: Value(messageText),
          createdAt: now,
          updatedAt: now,
        ));
    await _reload();
    return id;
  }

  /// All-day events span whole days; others last at least 15 minutes.
  static (DateTime, DateTime) _normalize(DateTime start, DateTime end, bool allDay) {
    if (allDay) {
      final s = day(start);
      var e = day(end);
      if (!e.isAfter(s)) e = s.add(const Duration(days: 1));
      return (s, e);
    }
    if (end.difference(start) < const Duration(minutes: 15)) {
      return (start, start.add(const Duration(minutes: 15)));
    }
    return (start, end);
  }

  Future<void> edit(
    int id, {
    required String title,
    required DateTime start,
    required DateTime end,
    required bool allDay,
    required String note,
    required int? remindBefore,
  }) async {
    final (s, e) = _normalize(start, end, allDay);
    await (db.update(db.events)..where((t) => t.id.equals(id))).write(EventsCompanion(
      title: Value(title.trim()),
      start: Value(s),
      end: Value(e),
      allDay: Value(allDay),
      note: Value(note.trim()),
      remindBefore: Value(remindBefore),
      updatedAt: Value(DateTime.now()),
    ));
    await _reload();
  }

  /// Moves or resizes an event (drag in the week view).
  Future<void> reschedule(int id, DateTime start, DateTime end) async {
    final ev = byId(id);
    final (s, e) = _normalize(start, end, ev?.allDay ?? false);
    await (db.update(db.events)..where((t) => t.id.equals(id))).write(EventsCompanion(
      start: Value(s),
      end: Value(e),
      updatedAt: Value(DateTime.now()),
    ));
    await _reload();
  }

  Future<void> remove(int id) async {
    await (db.delete(db.events)..where((t) => t.id.equals(id))).go();
    await _reload();
  }

  Future<void> restore(Event e) async {
    await db.into(db.events).insert(e, mode: InsertMode.insertOrReplace);
    await _reload();
  }

  /// Re-reads everything (after a backup was restored).
  Future<void> reload() => _reload();

  Future<void> _reload() async {
    final rows = await (db.select(db.events)..orderBy([(t) => OrderingTerm.asc(t.start), (t) => OrderingTerm.asc(t.id)])).get();
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

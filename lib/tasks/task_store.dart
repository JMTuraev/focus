
import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';

import '../db/database.dart';

/// Tasks from the local database, kept in memory so widgets can read them
/// synchronously. Every write goes through this class and reloads the list
/// (no drift stream: simpler, and no stray timers in widget tests).
class TaskStore extends ChangeNotifier {
  TaskStore(this.db) {
    _reload();
  }

  final AppDatabase db;
  bool _disposed = false;
  List<Task> _all = const [];
  bool loaded = false;

  List<Task> get all => _all;

  Task? byId(int id) {
    for (final t in _all) {
      if (t.id == id) return t;
    }
    return null;
  }

  static DateTime _day(DateTime d) => DateTime(d.year, d.month, d.day);

  /// Tasks in one column, filtered by chat and a search text.
  List<Task> column(TaskStatus status, {String? chatId, String query = ''}) {
    final q = query.trim().toLowerCase();
    return _all.where((t) {
      if (t.status != status) return false;
      if (chatId != null && t.chatId != chatId) return false;
      if (q.isNotEmpty &&
          !t.title.toLowerCase().contains(q) &&
          !t.note.toLowerCase().contains(q) &&
          !(t.chatTitle ?? '').toLowerCase().contains(q)) {
        return false;
      }
      return true;
    }).toList();
  }

  bool isOverdue(Task t, {DateTime? now}) =>
      t.status != TaskStatus.done && t.due != null && t.due!.isBefore(_day(now ?? DateTime.now()));

  bool isDueToday(Task t, {DateTime? now}) =>
      t.status != TaskStatus.done && t.due != null && _day(t.due!) == _day(now ?? DateTime.now());

  int get openCount => _all.where((t) => t.status != TaskStatus.done).length;
  int get overdueCount => _all.where(isOverdue).length;

  /// Open tasks that need attention: overdue or due today (rail badge).
  int get urgentCount => _all.where((t) => isOverdue(t) || isDueToday(t)).length;

  /// Open tasks linked to [chatId].
  int openForChat(String chatId) => _all.where((t) => t.chatId == chatId && t.status != TaskStatus.done).length;

  double _endOf(TaskStatus s) {
    var max = 0.0;
    for (final t in _all) {
      if (t.status == s && t.position > max) max = t.position;
    }
    return max + 1;
  }

  Future<int> add({
    required String title,
    TaskStatus status = TaskStatus.planned,
    String note = '',
    DateTime? due,
    bool important = false,
    String? chatId,
    String? chatTitle,
    String? messageId,
    String? messageText,
  }) async {
    final now = DateTime.now();
    final id = await db.into(db.tasks).insert(TasksCompanion.insert(
          title: title.trim(),
          status: status,
          note: Value(note.trim()),
          due: Value(due == null ? null : _day(due)),
          important: Value(important),
          position: Value(_endOf(status)),
          chatId: Value(chatId),
          chatTitle: Value(chatTitle),
          messageId: Value(messageId),
          messageText: Value(messageText),
          createdAt: now,
          updatedAt: now,
          completedAt: Value(status == TaskStatus.done ? now : null),
        ));
    await _reload();
    return id;
  }

  /// Puts a deleted task back (undo).
  Future<void> restore(Task t) async {
    await db.into(db.tasks).insert(t, mode: InsertMode.insertOrReplace);
    await _reload();
  }

  Future<void> edit(
    int id, {
    String? title,
    String? note,
    bool? important,
    DateTime? due,
    bool clearDue = false,
  }) async {
    await (db.update(db.tasks)..where((t) => t.id.equals(id))).write(TasksCompanion(
      title: title == null ? const Value.absent() : Value(title.trim()),
      note: note == null ? const Value.absent() : Value(note.trim()),
      important: important == null ? const Value.absent() : Value(important),
      due: clearDue ? const Value(null) : (due == null ? const Value.absent() : Value(_day(due))),
      updatedAt: Value(DateTime.now()),
    ));
    await _reload();
  }

  /// Moves a task to [to], before [beforeId] or at the end of the column.
  Future<void> move(int id, TaskStatus to, {int? beforeId}) async {
    final column = _all.where((t) => t.status == to && t.id != id).toList();
    double position;
    final i = beforeId == null ? -1 : column.indexWhere((t) => t.id == beforeId);
    if (i < 0) {
      position = column.isEmpty ? 1 : column.last.position + 1;
    } else {
      final before = column[i].position;
      final prev = i == 0 ? before - 1 : column[i - 1].position;
      position = (prev + before) / 2;
    }
    final now = DateTime.now();
    final task = byId(id);
    final wasDone = task?.status == TaskStatus.done;
    await (db.update(db.tasks)..where((t) => t.id.equals(id))).write(TasksCompanion(
      status: Value(to),
      position: Value(position),
      updatedAt: Value(now),
      completedAt: to == TaskStatus.done ? Value(wasDone ? task!.completedAt : now) : const Value(null),
    ));
    await _reload();
  }

  Future<void> remove(int id) async {
    await (db.delete(db.tasks)..where((t) => t.id.equals(id))).go();
    await _reload();
  }

  /// Re-reads everything (after a backup was restored).
  Future<void> reload() => _reload();

  Future<void> _reload() async {
    final rows = await (db.select(db.tasks)
          ..orderBy([(t) => OrderingTerm.asc(t.position), (t) => OrderingTerm.asc(t.id)]))
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

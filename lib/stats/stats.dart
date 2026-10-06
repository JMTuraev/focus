import '../data/models.dart';
import '../db/database.dart';
import '../state/app_state.dart';

/// Chats of one collection (or unsorted when [collection] is null).
class CollectionStat {
  const CollectionStat({required this.collection, required this.chats, required this.unread});

  final Collection? collection;
  final int chats;
  final int unread;
}

/// One day of the activity chart.
class DayStat {
  const DayStat(this.day, this.count);

  final DateTime day;
  final int count;
}

/// A chat that waits for our reply, and for how long (null without a date).
class WaitingStat {
  const WaitingStat(this.chat, this.since);

  final Chat chat;
  final Duration? since;
}

/// Numbers for the "Statistika" module, computed from what Focus already
/// holds in memory: chats from TDLib, tasks, meetings and notes from the
/// local database. Nothing is requested from Telegram.
class Stats {
  Stats._({
    required this.chats,
    required this.unreadChats,
    required this.waiting,
    required this.activeToday,
    required this.openTasks,
    required this.overdueTasks,
    required this.doneTasks,
    required this.meetingsThisWeek,
    required this.notes,
    required this.byCollection,
    required this.byType,
    required this.activeByDay,
    required this.longestWaiting,
    required this.tasksByColumn,
  });

  final int chats;
  final int unreadChats;
  final int waiting;
  final int activeToday;
  final int openTasks;
  final int overdueTasks;
  final int doneTasks;
  final int meetingsThisWeek;
  final int notes;

  /// Largest first; the unsorted entry (collection null) comes last.
  final List<CollectionStat> byCollection;
  final Map<ChatType, int> byType;

  /// The last 7 days, oldest first.
  final List<DayStat> activeByDay;

  /// Up to 5 chats, longest wait first.
  final List<WaitingStat> longestWaiting;
  final Map<TaskStatus, int> tasksByColumn;

  static Stats compute(AppState s, {DateTime? now}) {
    final n = now ?? DateTime.now();
    final today = DateTime(n.year, n.month, n.day);
    final chats = s.source.chats;

    final unread = chats.where((c) => s.unreadOf(c) > 0).length;
    final waitingChats = chats.where(s.waitingOf).toList();
    final activeToday = chats.where((c) => c.lastAt != null && !c.lastAt!.isBefore(today)).length;

    final byCollection = <CollectionStat>[];
    for (final col in s.collections) {
      final inCol = chats.where((c) => s.collectionOf(c) == col.id).toList();
      byCollection.add(CollectionStat(
        collection: col,
        chats: inCol.length,
        unread: inCol.where((c) => s.unreadOf(c) > 0).length,
      ));
    }
    byCollection.sort((a, b) => b.chats.compareTo(a.chats));
    final unsorted = chats.where((c) => s.collectionOf(c).isEmpty).toList();
    if (unsorted.isNotEmpty) {
      byCollection.add(CollectionStat(
        collection: null,
        chats: unsorted.length,
        unread: unsorted.where((c) => s.unreadOf(c) > 0).length,
      ));
    }

    final byType = <ChatType, int>{for (final t in ChatType.values) t: 0};
    for (final c in chats) {
      byType[ChatType.of(c)] = byType[ChatType.of(c)]! + 1;
    }

    final days = [for (var i = 6; i >= 0; i--) today.subtract(Duration(days: i))];
    final activeByDay = [
      for (final d in days)
        DayStat(d, chats.where((c) {
          final at = c.lastAt;
          return at != null && at.year == d.year && at.month == d.month && at.day == d.day;
        }).length),
    ];

    waitingChats.sort((a, b) {
      final x = a.lastAt, y = b.lastAt;
      if (x == null && y == null) return 0;
      if (x == null) return 1;
      if (y == null) return -1;
      return x.compareTo(y);
    });
    final longest = [
      for (final c in waitingChats.take(5)) WaitingStat(c, c.lastAt == null ? null : n.difference(c.lastAt!)),
    ];

    final tasks = s.tasks.all;
    final byColumn = <TaskStatus, int>{for (final st in TaskStatus.values) st: 0};
    for (final t in tasks) {
      byColumn[t.status] = byColumn[t.status]! + 1;
    }

    final weekStart = today.subtract(Duration(days: today.weekday - 1));
    final weekEnd = weekStart.add(const Duration(days: 7));
    final meetings = s.events.all.where((e) => !e.start.isBefore(weekStart) && e.start.isBefore(weekEnd)).length;

    return Stats._(
      chats: chats.length,
      unreadChats: unread,
      waiting: waitingChats.length,
      activeToday: activeToday,
      openTasks: s.tasks.openCount,
      overdueTasks: s.tasks.overdueCount,
      doneTasks: byColumn[TaskStatus.done]!,
      meetingsThisWeek: meetings,
      notes: s.notes.all.length,
      byCollection: byCollection,
      byType: byType,
      activeByDay: activeByDay,
      longestWaiting: longest,
      tasksByColumn: byColumn,
    );
  }
}

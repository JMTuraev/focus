import 'dart:async';

import 'package:flutter/foundation.dart';

import '../calendar/event_store.dart';
import '../data/format.dart';
import '../db/database.dart';
import '../l10n/l10n.dart';
import '../state/settings.dart';
import '../tasks/task_store.dart';
import 'notifier.dart';

/// One notification Focus wants Windows to show.
@immutable
class PlannedReminder {
  const PlannedReminder({required this.at, required this.title, required this.body, required this.payload});

  final DateTime at;
  final String title;
  final String body;
  final String payload;

  @override
  bool operator ==(Object other) =>
      other is PlannedReminder && other.at == at && other.title == title && other.body == body && other.payload == payload;

  @override
  int get hashCode => Object.hash(at, title, body, payload);
}

/// Keeps Windows' scheduled notifications in line with meetings and tasks:
/// - a meeting with a reminder: [Event.remindBefore] minutes before it starts
///   (all-day meetings: at [Settings.taskReminderHour] that day);
/// - an open task with a due date: at [Settings.taskReminderHour] that day.
/// Edits, moves and deletes reschedule or cancel; nothing is lost if Focus
/// is closed, because Windows keeps scheduled toasts.
class ReminderService {
  ReminderService({
    required this.notifier,
    required this.events,
    required this.tasks,
    required this.settings,
    this.accountId,
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  final Notifier notifier;
  final EventStore events;
  final TaskStore tasks;
  final Settings settings;
  final String? accountId;
  String _payload(String value) => accountId == null ? value : 'account:$accountId:$value';
  bool _disposed = false;
  final DateTime Function() _clock;

  static const eventBase = 100000000;
  static const taskBase = 200000000;

  /// Reminders further ahead are scheduled later (Windows keeps a limited
  /// number of scheduled toasts per app).
  static const horizon = Duration(days: 60);

  Map<int, PlannedReminder> _scheduled = {};
  bool _first = true;
  Timer? _debounce;
  Future<void>? _running;

  Map<int, PlannedReminder> get scheduled => Map.unmodifiable(_scheduled);

  void start() {
    events.addListener(_changed);
    tasks.addListener(_changed);
    settings.addListener(_changed);
    _changed();
  }

  void dispose() {
    _disposed = true;
    _debounce?.cancel();
    events.removeListener(_changed);
    tasks.removeListener(_changed);
    settings.removeListener(_changed);
  }

  Future<void> cancelScheduled() async {
    await _running;
    for (final id in await notifier.pendingIds()) {
      if (_ours(id)) await notifier.cancel(id);
    }
    _scheduled = {};
  }

  void _changed() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), sync);
  }

  static bool _ours(int id) => id >= eventBase && id < taskBase + eventBase;

  /// What should be scheduled right now.
  Map<int, PlannedReminder> desired() {
    if (!settings.remindersEnabled) return {};
    final now = _clock();
    final until = now.add(horizon);
    final hour = Duration(hours: settings.taskReminderHour);
    final out = <int, PlannedReminder>{};
    // Texts in the current UI language; a language change notifies
    // [settings], which reschedules everything.
    final s = S.current.calendar;

    for (final e in events.all) {
      final before = e.remindBefore;
      if (before == null) continue;
      final at = e.allDay ? EventStore.day(e.start).add(hour) : e.start.subtract(Duration(minutes: before));
      if (!at.isAfter(now) || at.isAfter(until)) continue;
      final when = e.allDay ? s.reminderAllDay(Fmt.dueLabel(e.start)) : '${Fmt.dueLabel(e.start)}, ${Fmt.hm(e.start)}–${Fmt.hm(e.end)}';
      out[eventBase + e.id] = PlannedReminder(
        at: at,
        title: e.title,
        body: [when, if (e.chatTitle != null) e.chatTitle!].join(' · '),
        payload: _payload('event:${e.id}'),
      );
    }

    for (final t in tasks.all) {
      final due = t.due;
      if (due == null || t.status == TaskStatus.done) continue;
      final at = EventStore.day(due).add(hour);
      if (!at.isAfter(now) || at.isAfter(until)) continue;
      out[taskBase + t.id] = PlannedReminder(
        at: at,
        title: s.taskReminderTitle(t.title),
        body: [s.taskReminderDue(Fmt.dueLabel(due)), if (t.chatTitle != null) t.chatTitle!].join(' · '),
        payload: _payload('task:${t.id}'),
      );
    }
    return out;
  }

  /// Brings the scheduled notifications in line with [desired].
  Future<void> sync() => _running = (_running ?? Future.value()).then((_) => _sync());

  Future<void> _sync() async {
    if (_disposed) return;
    final want = desired();
    try {
      if (_first) {
        // After a restart we do not know what an earlier run scheduled:
        // drop our old toasts that are no longer wanted, then (re)schedule.
        _first = false;
        for (final id in await notifier.pendingIds()) {
          if (_ours(id) && !want.containsKey(id)) await notifier.cancel(id);
        }
        _scheduled = {};
      }
      for (final id in _scheduled.keys.where((id) => !want.containsKey(id)).toList()) {
        await notifier.cancel(id);
      }
      for (final entry in want.entries) {
        if (_scheduled[entry.key] == entry.value) continue;
        await notifier.cancel(entry.key);
        final r = entry.value;
        await notifier.schedule(id: entry.key, at: r.at, title: r.title, body: r.body, payload: r.payload);
      }
      _scheduled = want;
    } catch (e) {
      debugPrint('reminders sync: $e');
    }
  }
}

/// Test double: records what would be shown.
class FakeNotifier implements Notifier {
  final scheduledById = <int, PlannedReminder>{};
  final shown = <String>[];

  /// Payloads of [shown], in order.
  final shownPayloads = <String>[];
  final _taps = StreamController<String>.broadcast();
  String? launch;

  void tap(String payload) => _taps.add(payload);

  @override
  Stream<String> get taps => _taps.stream;

  @override
  Future<String?> launchPayload() async => launch;

  @override
  Future<void> schedule({required int id, required DateTime at, required String title, required String body, required String payload}) async {
    scheduledById[id] = PlannedReminder(at: at, title: title, body: body, payload: payload);
  }

  @override
  Future<void> show({required int id, required String title, required String body, String payload = ''}) async {
    shown.add('$title: $body');
    shownPayloads.add(payload);
  }

  @override
  Future<void> cancel(int id) async => scheduledById.remove(id);

  @override
  Future<Set<int>> pendingIds() async => scheduledById.keys.toSet();
}

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../calendar/event_store.dart';
import '../../data/format.dart';
import '../../db/database.dart';
import '../../l10n/l10n.dart';
import '../../state/app_state.dart';
import '../../theme.dart';
import '../tasks/task_editor.dart';
import 'event_editor.dart';

/// Pixels per hour in the grid.
const double kHourHeight = 56;
const double _gutter = 56;

/// Week (7 days) or day (1 day) grid: day headers, an all-day row (events
/// and tasks due that day), and hours with events you can click, drag to
/// another time or day, and stretch by the bottom edge.
class TimeGrid extends StatefulWidget {
  const TimeGrid({super.key, required this.state, required this.start, required this.days});

  final AppState state;

  /// First day shown (local midnight).
  final DateTime start;
  final int days;

  @override
  State<TimeGrid> createState() => _TimeGridState();
}

class _TimeGridState extends State<TimeGrid> {
  late final ScrollController _scroll = ScrollController(initialScrollOffset: _initialOffset());
  Timer? _clock;

  double _initialOffset() {
    final now = DateTime.now();
    final end = widget.start.add(Duration(days: widget.days));
    final hour = now.isAfter(widget.start) && now.isBefore(end) ? math.max(0, now.hour - 1) : 7.5;
    return hour * kHourHeight;
  }

  @override
  void initState() {
    super.initState();
    // Moves the "now" line once a minute.
    _clock = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _clock?.cancel();
    _scroll.dispose();
    super.dispose();
  }

  List<DateTime> get _dayList => [for (var i = 0; i < widget.days; i++) widget.start.add(Duration(days: i))];

  @override
  Widget build(BuildContext context) {
    final c = context.fc;
    final s = widget.state;
    final days = _dayList;
    return LayoutBuilder(
      builder: (context, box) {
        // Inner width: the 1 px border on both sides is not available.
        final colW = (box.maxWidth - 2 - _gutter) / widget.days;
        return Container(
          decoration: BoxDecoration(color: c.panel, borderRadius: BorderRadius.circular(12), border: Border.all(color: c.border)),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _headers(c, days, colW),
              _AllDayRow(state: s, days: days, colW: colW),
              Divider(height: 1, color: c.border),
              Expanded(
                child: SingleChildScrollView(
                  controller: _scroll,
                  child: SizedBox(
                    height: 24 * kHourHeight,
                    child: Stack(
                      children: [
                        for (var h = 0; h < 24; h++) _hourLine(c, h),
                        for (var i = 0; i < days.length; i++)
                          Positioned(
                            left: _gutter + i * colW,
                            top: 0,
                            width: colW,
                            height: 24 * kHourHeight,
                            child: _DayColumn(state: s, day: days[i], dayIndex: i, days: widget.days, colW: colW),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _headers(FokusColors c, List<DateTime> days, double colW) {
    final today = EventStore.day(DateTime.now());
    return SizedBox(
      height: 52,
      child: Row(
        children: [
          const SizedBox(width: _gutter),
          for (final d in days)
            SizedBox(
              width: colW,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(Fmt.weekdayShort(d.weekday), style: TextStyle(fontSize: 12, color: d == today ? c.accentText : c.text2)),
                  const SizedBox(height: 2),
                  Container(
                    width: 28,
                    height: 28,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(color: d == today ? c.accentStrong : Colors.transparent, shape: BoxShape.circle),
                    child: Text(
                      '${d.day}',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: d == today ? Colors.white : c.text),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _hourLine(FokusColors c, int h) {
    return Positioned(
      top: h * kHourHeight,
      left: 0,
      right: 0,
      height: kHourHeight,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: _gutter,
            child: h == 0
                ? null
                : Transform.translate(
                    offset: const Offset(0, -8),
                    child: Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Text('${Fmt.two(h)}:00', textAlign: TextAlign.right, style: TextStyle(fontSize: 11.5, color: c.text2)),
                    ),
                  ),
          ),
          Expanded(child: Container(height: 1, color: h == 0 ? Colors.transparent : c.border)),
        ],
      ),
    );
  }
}

/// Events and tasks without a time: shown above the hours.
class _AllDayRow extends StatelessWidget {
  const _AllDayRow({required this.state, required this.days, required this.colW});

  final AppState state;
  final List<DateTime> days;
  final double colW;

  static const _maxShown = 3;

  @override
  Widget build(BuildContext context) {
    final c = context.fc;
    final chatId = state.eventChatFilter;
    final perDay = [
      for (final d in days)
        <Object>[
          ...state.events.onDay(d, chatId: chatId).where((e) => e.allDay),
          ...state.tasks.all.where((t) =>
              t.status != TaskStatus.done &&
              t.due != null &&
              EventStore.day(t.due!) == d &&
              (chatId == null || t.chatId == chatId)),
        ],
    ];
    final rows = perDay.fold<int>(0, (m, l) => math.max(m, math.min(l.length, _maxShown + (l.length > _maxShown ? 1 : 0))));
    if (rows == 0) return const SizedBox(height: 4);
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: _gutter,
            child: Padding(
              padding: const EdgeInsets.only(right: 8, top: 4),
              child: Text(context.s.calendar.allDay, textAlign: TextAlign.right, style: TextStyle(fontSize: 10.5, color: c.text2)),
            ),
          ),
          for (final items in perDay)
            SizedBox(
              width: colW,
              child: Column(
                children: [
                  for (final item in items.take(_maxShown)) _AllDayChip(state: state, item: item),
                  if (items.length > _maxShown)
                    Text(context.s.calendar.moreCount(items.length - _maxShown), style: TextStyle(fontSize: 11, color: c.text2)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _AllDayChip extends StatelessWidget {
  const _AllDayChip({required this.state, required this.item});

  final AppState state;
  final Object item;

  @override
  Widget build(BuildContext context) {
    final c = context.fc;
    final isTask = item is Task;
    final title = isTask ? (item as Task).title : (item as Event).title;
    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 2, 2, 0),
      child: Material(
        color: isTask ? c.qaBg : c.accentSoft,
        borderRadius: BorderRadius.circular(6),
        child: InkWell(
          borderRadius: BorderRadius.circular(6),
          onTap: () => isTask
              ? showTaskEditor(context, state, task: item as Task)
              : showEventEditor(context, state, event: item as Event),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            child: Row(
              children: [
                Icon(isTask ? Icons.check_box_outline_blank : Icons.event, size: 13, color: isTask ? c.qaFg : c.accentText),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: isTask ? c.qaFg : c.accentText)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// An event placed in a day column: vertical position and overlap lane.
class _Placed {
  _Placed(this.event, this.from, this.to);

  final Event event;

  /// Minutes from the day's midnight, clipped to the day.
  final int from;
  final int to;
  int lane = 0;
  int lanes = 1;
}

/// Overlapping events share the column side by side (like Google/Outlook).
@visibleForTesting
List<({Event event, int lane, int lanes})> layoutDay(List<Event> events, DateTime day) {
  final dayEnd = day.add(const Duration(days: 1));
  final placed = [
    for (final e in events.where((e) => !e.allDay))
      _Placed(
        e,
        e.start.isBefore(day) ? 0 : e.start.difference(day).inMinutes,
        e.end.isAfter(dayEnd) ? 24 * 60 : e.end.difference(day).inMinutes,
      ),
  ]..sort((a, b) => a.from != b.from ? a.from.compareTo(b.from) : b.to.compareTo(a.to));

  final cluster = <_Placed>[];
  final laneEnds = <int>[];
  var clusterEnd = -1;
  void close() {
    for (final p in cluster) {
      p.lanes = laneEnds.length;
    }
    cluster.clear();
    laneEnds.clear();
  }

  for (final p in placed) {
    if (p.from >= clusterEnd) close();
    var lane = laneEnds.indexWhere((end) => end <= p.from);
    if (lane < 0) {
      lane = laneEnds.length;
      laneEnds.add(p.to);
    } else {
      laneEnds[lane] = p.to;
    }
    p.lane = lane;
    cluster.add(p);
    clusterEnd = math.max(clusterEnd, p.to);
  }
  close();
  return [for (final p in placed) (event: p.event, lane: p.lane, lanes: p.lanes)];
}

class _DayColumn extends StatelessWidget {
  const _DayColumn({required this.state, required this.day, required this.dayIndex, required this.days, required this.colW});

  final AppState state;
  final DateTime day;
  final int dayIndex;
  final int days;
  final double colW;

  @override
  Widget build(BuildContext context) {
    final c = context.fc;
    final events = state.events.onDay(day, chatId: state.eventChatFilter);
    final placed = layoutDay(events, day);
    final now = DateTime.now();
    final isToday = EventStore.day(now) == day;
    const pad = 3.0;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Click on an empty slot: new event at that half hour.
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapUp: (d) {
              final minutes = (d.localPosition.dy / kHourHeight * 60 ~/ 30) * 30;
              final start = day.add(Duration(minutes: minutes));
              showEventEditor(context, state, start: start, end: start.add(const Duration(hours: 1)));
            },
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: isToday ? c.accentSoft.withValues(alpha: 0.25) : Colors.transparent,
                border: Border(left: BorderSide(color: c.border)),
              ),
            ),
          ),
        ),
        for (final p in placed)
          _EventTile(
            key: ValueKey(p.event.id),
            state: state,
            event: p.event,
            day: day,
            dayIndex: dayIndex,
            days: days,
            colW: colW,
            left: pad + p.lane * (colW - pad * 2) / p.lanes,
            width: (colW - pad * 2) / p.lanes - 2,
          ),
        if (isToday)
          Positioned(
            top: (now.hour * 60 + now.minute) * kHourHeight / 60 - 1,
            left: 0,
            right: 0,
            child: IgnorePointer(
              child: Row(
                children: [
                  Container(width: 8, height: 8, decoration: BoxDecoration(color: c.danger, shape: BoxShape.circle)),
                  Expanded(child: Container(height: 2, color: c.danger)),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

/// One event in the grid. Drag to move (snaps to 15 minutes and to days),
/// drag the bottom edge to change the length, click to edit.
class _EventTile extends StatefulWidget {
  const _EventTile({
    super.key,
    required this.state,
    required this.event,
    required this.day,
    required this.dayIndex,
    required this.days,
    required this.colW,
    required this.left,
    required this.width,
  });

  final AppState state;
  final Event event;
  final DateTime day;
  final int dayIndex;
  final int days;
  final double colW;
  final double left;
  final double width;

  @override
  State<_EventTile> createState() => _EventTileState();
}

class _EventTileState extends State<_EventTile> {
  Offset _drag = Offset.zero;
  double _resize = 0;

  // Pointer positions where the drag began (DragStartBehavior.down, so the
  // distance moved before the gesture was recognized is not lost).
  Offset _dragFrom = Offset.zero;
  double _resizeFrom = 0;

  static int _snap(double minutes) => (minutes / 15).round() * 15;

  int get _moveMinutes => _snap(_drag.dy / kHourHeight * 60);

  int get _moveDays => (_drag.dx / widget.colW).round().clamp(-widget.dayIndex, widget.days - 1 - widget.dayIndex);

  int get _resizeMinutes => _snap(_resize / kHourHeight * 60);

  Future<void> _commitMove() async {
    final e = widget.event;
    final delta = Duration(days: _moveDays, minutes: _moveMinutes);
    setState(() => _drag = Offset.zero);
    if (delta != Duration.zero) await widget.state.events.reschedule(e.id, e.start.add(delta), e.end.add(delta));
  }

  Future<void> _commitResize() async {
    final e = widget.event;
    final minutes = _resizeMinutes;
    setState(() => _resize = 0);
    if (minutes == 0) return;
    var end = e.end.add(Duration(minutes: minutes));
    if (end.difference(e.start).inMinutes < 15) end = e.start.add(const Duration(minutes: 15));
    await widget.state.events.reschedule(e.id, e.start, end);
  }

  Future<void> _menu(Offset pos) async {
    final c = context.fc;
    final overlay = Overlay.of(context).context.findRenderObject()! as RenderBox;
    final e = widget.event;
    final s = context.s;
    final choice = await showMenu<String>(
      context: context,
      color: c.panel,
      position: RelativeRect.fromRect(pos & const Size(1, 1), Offset.zero & overlay.size),
      items: [
        PopupMenuItem(value: 'edit', height: 38, child: Text(s.common.edit, style: TextStyle(color: c.text))),
        if (e.chatId != null) PopupMenuItem(value: 'chat', height: 38, child: Text(s.calendar.openChat, style: TextStyle(color: c.text))),
        PopupMenuItem(value: 'delete', height: 38, child: Text(s.common.delete, style: TextStyle(color: c.danger))),
      ],
    );
    if (!mounted) return;
    switch (choice) {
      case 'edit':
        await showEventEditor(context, widget.state, event: e);
      case 'chat':
        widget.state.openEventChat(e);
      case 'delete':
        await deleteEventWithUndo(context, widget.state, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.fc;
    final e = widget.event;
    final dayEnd = widget.day.add(const Duration(days: 1));
    final from = e.start.isBefore(widget.day) ? 0 : e.start.difference(widget.day).inMinutes;
    final to = e.end.isAfter(dayEnd) ? 24 * 60 : e.end.difference(widget.day).inMinutes;
    final top = from * kHourHeight / 60 + _moveMinutes * kHourHeight / 60;
    final height = math.max(18.0, (to - from + _resizeMinutes) * kHourHeight / 60 - 2);
    final moving = _drag != Offset.zero || _resize != 0;
    final start = e.start.add(Duration(days: _moveDays, minutes: _moveMinutes));
    final end = e.end.add(Duration(days: _moveDays, minutes: _moveMinutes + _resizeMinutes));
    final compact = height < 40;
    return Positioned(
      top: top,
      left: widget.left + _moveDays * widget.colW,
      width: widget.width,
      height: height,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: () => showEventEditor(context, widget.state, event: e),
          onSecondaryTapDown: (d) => _menu(d.globalPosition),
          dragStartBehavior: DragStartBehavior.down,
          onPanStart: (d) => _dragFrom = d.globalPosition,
          onPanUpdate: (d) => setState(() => _drag = d.globalPosition - _dragFrom),
          onPanEnd: (_) => _commitMove(),
          onPanCancel: () => setState(() => _drag = Offset.zero),
          child: Opacity(
            opacity: moving ? 0.85 : 1,
            child: Container(
              decoration: BoxDecoration(
                color: Color.alphaBlend(c.accent.withValues(alpha: 0.22), c.panel),
                borderRadius: BorderRadius.circular(6),
                border: Border(left: BorderSide(color: c.accent, width: 3)),
                boxShadow: moving ? [BoxShadow(color: c.bubbleShadow, blurRadius: 8, offset: const Offset(0, 2))] : null,
              ),
              child: Stack(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(6, 3, 4, 3),
                    child: ClipRect(
                      child: compact
                          ? Text('${Fmt.hm(start)} ${e.title}',
                              maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: c.text))
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(e.title,
                                    maxLines: math.max(1, (height - 22) ~/ 16),
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: c.text, height: 1.25)),
                                Text('${Fmt.hm(start)}–${Fmt.hm(end)}',
                                    maxLines: 1, style: TextStyle(fontSize: 11.5, color: c.textSoft)),
                              ],
                            ),
                    ),
                  ),
                  // Bottom edge: drag to change the length.
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    height: 7,
                    child: MouseRegion(
                      cursor: SystemMouseCursors.resizeUpDown,
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        dragStartBehavior: DragStartBehavior.down,
                        onVerticalDragStart: (d) => _resizeFrom = d.globalPosition.dy,
                        onVerticalDragUpdate: (d) => setState(() => _resize = d.globalPosition.dy - _resizeFrom),
                        onVerticalDragEnd: (_) => _commitResize(),
                        onVerticalDragCancel: () => setState(() => _resize = 0),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

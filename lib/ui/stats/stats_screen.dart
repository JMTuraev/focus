import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../data/format.dart';
import '../../db/database.dart';
import '../../l10n/l10n.dart';
import '../../state/app_state.dart';
import '../../stats/stats.dart';
import '../../theme.dart';
import '../common.dart';

/// "Statistika": numbers about the chats and Focus work, computed locally
/// ([Stats.compute]). Stat tiles on top, then bars by collection, chat
/// types, active chats per day, the longest-waiting chats and tasks by
/// column. Colors: a collection keeps its own color; magnitudes use the
/// accent in one hue (lighter = all, darker = unread); text in text tokens.
class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key, required this.state});

  final AppState state;

  @override
  Widget build(BuildContext context) {
    final c = context.fc;
    final t = context.s.stats;
    final st = Stats.compute(state);
    return Container(
      color: c.bg,
      child: LayoutBuilder(
        builder: (context, box) {
          final pad = box.maxWidth < 600 ? 16.0 : 28.0;
          final twoColumns = box.maxWidth >= 900;
          final sections = <Widget>[
            _Section(
              title: t.byCollection,
              hint: t.byCollectionHint,
              child: _CollectionBars(stats: st, state: state),
            ),
            _Section(title: t.byType, child: _TypeBars(stats: st)),
            _Section(title: t.activeByDay, hint: t.activeByDayHint, child: _DayColumns(stats: st)),
            _Section(
              title: t.longestWaiting,
              hint: t.longestWaitingHint,
              child: _WaitingList(stats: st, state: state),
            ),
            _Section(title: t.tasksByColumn, child: _TaskBars(stats: st)),
          ];
          return ListView(
            padding: EdgeInsets.fromLTRB(pad, 24, pad, 24),
            children: [
              Text(t.title, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: c.text)),
              const SizedBox(height: 4),
              Text(t.intro, style: TextStyle(fontSize: 13.5, color: c.text2)),
              const SizedBox(height: 16),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _Tile(label: t.chats, value: st.chats),
                  _Tile(label: t.unreadChats, value: st.unreadChats, accent: st.unreadChats > 0),
                  _Tile(label: t.waitingReplies, value: st.waiting, dot: true),
                  _Tile(label: t.activeToday, value: st.activeToday),
                  _Tile(label: t.openTasks, value: st.openTasks),
                  _Tile(label: t.overdueTasks, value: st.overdueTasks, danger: st.overdueTasks > 0),
                  _Tile(label: t.doneTasks, value: st.doneTasks),
                  _Tile(label: t.meetingsThisWeek, value: st.meetingsThisWeek),
                  _Tile(label: t.notes, value: st.notes),
                ],
              ),
              const SizedBox(height: 18),
              if (twoColumns)
                for (var i = 0; i < sections.length; i += 2)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: sections[i]),
                        const SizedBox(width: 12),
                        Expanded(child: i + 1 < sections.length ? sections[i + 1] : const SizedBox()),
                      ],
                    ),
                  )
              else
                for (final s in sections) Padding(padding: const EdgeInsets.only(bottom: 12), child: s),
            ],
          );
        },
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({required this.label, required this.value, this.accent = false, this.danger = false, this.dot = false});

  final String label;
  final int value;
  final bool accent;
  final bool danger;
  final bool dot;

  @override
  Widget build(BuildContext context) {
    final c = context.fc;
    final color = danger ? c.danger : (accent ? c.accentText : c.text);
    return Container(
      width: 150,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: c.panel,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: c.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (dot && value > 0) ...[const WaitingDot(), const SizedBox(width: 6)],
              Text(Fmt.count(value), style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: color, height: 1.1)),
            ],
          ),
          const SizedBox(height: 4),
          Text(label, maxLines: 2, style: TextStyle(fontSize: 12.5, color: c.text2)),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child, this.hint});

  final String title;
  final String? hint;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final c = context.fc;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: c.panel,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: c.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: c.text)),
          if (hint != null) ...[
            const SizedBox(height: 2),
            Text(hint!, style: TextStyle(fontSize: 12.5, color: c.text2)),
          ],
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

/// One horizontal bar: label, a thin bar scaled to [max], the value in text
/// color. [part] (0..value) is drawn darker inside the bar.
class _Bar extends StatelessWidget {
  const _Bar({
    required this.label,
    required this.value,
    required this.max,
    required this.color,
    required this.valueText,
    this.part = 0,
    this.icon,
    this.onTap,
  });

  final String label;
  final int value;
  final int max;
  final Color color;
  final String valueText;
  final int part;
  final IconData? icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.fc;
    final frac = max == 0 ? 0.0 : value / max;
    final partFrac = value == 0 ? 0.0 : part / value;
    return Tap(
      onTap: onTap,
      radius: 8,
      hover: onTap == null ? Colors.transparent : c.hover,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 4),
        child: Row(
          children: [
            if (icon != null) ...[Icon(icon, size: 16, color: color), const SizedBox(width: 6)],
            SizedBox(
              width: 104,
              child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 13, color: c.text)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: LayoutBuilder(
                builder: (context, box) {
                  final w = math.max(0.0, box.maxWidth * frac);
                  return SizedBox(
                    height: 12,
                    child: Stack(
                      children: [
                        Container(
                          decoration: BoxDecoration(color: c.bg, borderRadius: BorderRadius.circular(4)),
                        ),
                        if (w > 0)
                          Container(
                            width: math.max(w, 4),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.35),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        if (w > 0 && partFrac > 0)
                          Container(
                            width: math.max(w * partFrac, 4),
                            decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4)),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 10),
            SizedBox(
              width: 156,
              child: Text(valueText,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.right,
                  style: TextStyle(fontSize: 12.5, color: c.text2)),
            ),
          ],
        ),
      ),
    );
  }
}

class _CollectionBars extends StatelessWidget {
  const _CollectionBars({required this.stats, required this.state});

  final Stats stats;
  final AppState state;

  @override
  Widget build(BuildContext context) {
    final c = context.fc;
    final t = context.s.stats;
    final max = stats.byCollection.fold(0, (m, s) => math.max(m, s.chats));
    if (stats.byCollection.isEmpty) return Text(t.noWaiting, style: TextStyle(color: c.text2, fontSize: 13));
    return Column(
      children: [
        for (final s in stats.byCollection)
          _Bar(
            label: s.collection?.label ?? t.unsorted,
            icon: s.collection?.icon ?? Icons.inbox_outlined,
            value: s.chats,
            part: s.unread,
            max: max,
            color: s.collection == null ? c.text2 : c.collectionColor(s.collection!.colorKey),
            valueText: s.unread > 0 ? '${t.chatsShort(s.chats)} · ${t.unreadShort(s.unread)}' : t.chatsShort(s.chats),
            onTap: s.collection == null ? null : () => state.pickCollection(s.collection!.id),
          ),
      ],
    );
  }
}

class _TypeBars extends StatelessWidget {
  const _TypeBars({required this.stats});

  final Stats stats;

  @override
  Widget build(BuildContext context) {
    final c = context.fc;
    final t = context.s.stats;
    final max = stats.byType.values.fold(0, math.max);
    return Column(
      children: [
        for (final e in stats.byType.entries)
          _Bar(
            label: e.key.label,
            icon: switch (e.key) {
              ChatType.private => Icons.person_outline,
              ChatType.group => Icons.groups_outlined,
              ChatType.channel => Icons.campaign_outlined,
              ChatType.bot => Icons.smart_toy_outlined,
            },
            value: e.value,
            part: e.value,
            max: max,
            color: c.accent,
            valueText: t.chatsShort(e.value),
          ),
      ],
    );
  }
}

/// Seven thin columns, one per day, value above each, weekday below.
class _DayColumns extends StatelessWidget {
  const _DayColumns({required this.stats});

  final Stats stats;

  @override
  Widget build(BuildContext context) {
    final c = context.fc;
    final max = stats.activeByDay.fold(0, (m, d) => math.max(m, d.count));
    final today = DateTime.now();
    return SizedBox(
      height: 120,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (final d in stats.activeByDay)
            Expanded(
              child: Tooltip(
                message: '${Fmt.dayLabel(d.day)} · ${d.count}',
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text('${d.count}', style: TextStyle(fontSize: 11.5, color: c.text2)),
                    const SizedBox(height: 4),
                    Container(
                      height: max == 0 ? 4 : math.max(4.0, 70 * d.count / max),
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(
                        color: Fmt.sameDay(d.day, today) ? c.accent : c.accent.withValues(alpha: 0.45),
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(Fmt.weekdayShort(d.day.weekday),
                        style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: Fmt.sameDay(d.day, today) ? FontWeight.w700 : FontWeight.w400,
                            color: c.text2)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _WaitingList extends StatelessWidget {
  const _WaitingList({required this.stats, required this.state});

  final Stats stats;
  final AppState state;

  @override
  Widget build(BuildContext context) {
    final c = context.fc;
    final t = context.s.stats;
    if (stats.longestWaiting.isEmpty) return Text(t.noWaiting, style: TextStyle(color: c.text2, fontSize: 13));
    return Column(
      children: [
        for (final w in stats.longestWaiting)
          Tap(
            onTap: () => state.jumpToChat(w.chat.id),
            radius: 8,
            hover: c.hover,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 4),
              child: Row(
                children: [
                  ChatAvatar(w.chat, size: 32, showOnline: false),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(w.chat.name,
                        maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 13.5, color: c.text)),
                  ),
                  const SizedBox(width: 8),
                  const WaitingDot(),
                  if (w.since != null) ...[
                    const SizedBox(width: 6),
                    Text(t.waitingFor(w.since!), style: TextStyle(fontSize: 12.5, color: c.text2)),
                  ],
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _TaskBars extends StatelessWidget {
  const _TaskBars({required this.stats});

  final Stats stats;

  @override
  Widget build(BuildContext context) {
    final c = context.fc;
    final max = stats.tasksByColumn.values.fold(0, math.max);
    return Column(
      children: [
        for (final e in stats.tasksByColumn.entries)
          _Bar(
            label: e.key.label,
            value: e.value,
            part: e.value,
            max: max,
            color: e.key == TaskStatus.done ? c.online : c.accent,
            valueText: '${e.value}',
          ),
      ],
    );
  }
}

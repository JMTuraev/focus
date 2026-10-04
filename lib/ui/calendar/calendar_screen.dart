import 'package:flutter/material.dart';

import '../../calendar/event_store.dart';
import '../../data/format.dart';
import '../../data/meeting_parser.dart';
import '../../state/app_state.dart';
import '../../theme.dart';
import '../common.dart';
import 'event_editor.dart';
import 'time_grid.dart';

/// Calendar: a week on wide windows (or a day if chosen), a day on narrow
/// ones. Events come from the local database; tasks with a due date show
/// in the all-day row.
class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key, required this.state});

  final AppState state;

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  bool _dayView = false;

  AppState get s => widget.state;

  static DateTime _monday(DateTime d) => EventStore.day(d).subtract(Duration(days: d.weekday - 1));

  String _range(DateTime start, int days) {
    if (days == 1) {
      return '${MeetingParser.weekdayNames[start.weekday - 1]}, ${start.day} ${Fmt.monthName(start.month)} ${start.year}';
    }
    final end = start.add(Duration(days: days - 1));
    if (start.month == end.month) return '${start.day}–${end.day} ${Fmt.monthName(end.month)} ${end.year}';
    final sameYear = start.year == end.year;
    return '${start.day} ${Fmt.monthName(start.month)}${sameYear ? '' : ' ${start.year}'} – '
        '${end.day} ${Fmt.monthName(end.month)} ${end.year}';
  }

  @override
  Widget build(BuildContext context) {
    final c = context.fc;
    return ListenableBuilder(
      listenable: Listenable.merge([s.events, s.tasks]),
      builder: (context, _) => LayoutBuilder(
        builder: (context, box) {
          final narrow = box.maxWidth < 700;
          final days = narrow || _dayView ? 1 : 7;
          final start = days == 7 ? _monday(s.calendarFocus) : s.calendarFocus;
          final pad = box.maxWidth < 600 ? 12.0 : 24.0;
          return Container(
            color: c.bg,
            padding: EdgeInsets.fromLTRB(pad, 20, pad, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _header(c, start, days, narrow),
                if (s.eventChatFilter != null) _chatFilterChip(c),
                const SizedBox(height: 12),
                Expanded(
                  child: TimeGrid(key: ValueKey('$start/$days'), state: s, start: start, days: days),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _header(FokusColors c, DateTime start, int days, bool narrow) {
    void shift(int n) => s.setCalendarFocus(s.calendarFocus.add(Duration(days: n * days)));
    final today = EventStore.day(DateTime.now());
    final remaining = s.events.remainingToday();
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 12,
      runSpacing: 10,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Kalendar', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: c.text)),
            Text(
              remaining > 0 ? '${_range(start, days)} · bugun yana $remaining ta uchrashuv' : _range(start, days),
              style: TextStyle(fontSize: 13, color: c.text2),
            ),
          ],
        ),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            IconButton(
              tooltip: days == 7 ? 'Oldingi hafta' : 'Oldingi kun',
              onPressed: () => shift(-1),
              icon: Icon(Icons.chevron_left, color: c.icon),
            ),
            OutlinedButton(
              onPressed: s.calendarFocus == today ? null : () => s.setCalendarFocus(today),
              style: OutlinedButton.styleFrom(foregroundColor: c.accentText, side: BorderSide(color: c.chipBorder)),
              child: const Text('Bugun'),
            ),
            IconButton(
              tooltip: days == 7 ? 'Keyingi hafta' : 'Keyingi kun',
              onPressed: () => shift(1),
              icon: Icon(Icons.chevron_right, color: c.icon),
            ),
            if (!narrow)
              SegmentedButton<bool>(
                showSelectedIcon: false,
                segments: const [
                  ButtonSegment(value: false, label: Text('Hafta')),
                  ButtonSegment(value: true, label: Text('Kun')),
                ],
                selected: {_dayView},
                onSelectionChanged: (v) => setState(() => _dayView = v.first),
                style: ButtonStyle(
                  foregroundColor: WidgetStateProperty.resolveWith((st) => st.contains(WidgetState.selected) ? Colors.white : c.textSoft),
                  backgroundColor: WidgetStateProperty.resolveWith((st) => st.contains(WidgetState.selected) ? c.accentStrong : c.panel),
                  side: WidgetStatePropertyAll(BorderSide(color: c.chipBorder)),
                ),
              ),
            FilledButton.icon(
              onPressed: () {
                final base = s.calendarFocus;
                final n = DateTime.now();
                final startAt = base == today
                    ? DateTime(n.year, n.month, n.day, n.hour + 1)
                    : DateTime(base.year, base.month, base.day, 10);
                showEventEditor(context, s, start: startAt);
              },
              icon: const Icon(Icons.add, size: 18),
              label: Text(narrow ? 'Yangi' : 'Yangi uchrashuv'),
              style: FilledButton.styleFrom(backgroundColor: c.accentStrong, foregroundColor: Colors.white),
            ),
          ],
        ),
      ],
    );
  }

  Widget _chatFilterChip(FokusColors c) {
    final id = s.eventChatFilter!;
    final chat = s.source.chatById(id);
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Align(
        alignment: Alignment.centerLeft,
        child: InputChip(
          avatar: chat == null ? null : ChatAvatar(chat, size: 22, showOnline: false),
          label: Text('Faqat: ${chat?.name ?? 'chat'}', style: TextStyle(color: c.text, fontWeight: FontWeight.w600)),
          backgroundColor: c.accentSoft,
          side: BorderSide.none,
          deleteIcon: Icon(Icons.close, size: 16, color: c.icon),
          deleteButtonTooltipMessage: 'Filtrni olib tashlash',
          onDeleted: s.clearEventChatFilter,
        ),
      ),
    );
  }
}

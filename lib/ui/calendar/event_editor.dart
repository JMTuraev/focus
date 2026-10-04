import 'package:flutter/material.dart';

import '../../data/format.dart';
import '../../data/meeting_parser.dart';
import '../../db/database.dart';
import '../../state/app_state.dart';
import '../../theme.dart';
import '../common.dart';
import '../source_box.dart';

/// Reminder choices (minutes before the start).
const kReminderChoices = <int?, String>{null: 'Yo‘q', 10: '10 daqiqa', 30: '30 daqiqa', 60: '1 soat', 1440: '1 kun'};

/// Create an event (prefilled from a click in the grid or a chat message),
/// or edit [event].
Future<void> showEventEditor(
  BuildContext context,
  AppState state, {
  Event? event,
  DateTime? start,
  DateTime? end,
  bool allDay = false,
  String title = '',
  String? chatId,
  String? chatTitle,
  String? messageId,
  String? messageText,
}) {
  final s = event?.start ?? start ?? _nextHour();
  return showDialog<void>(
    context: context,
    builder: (_) => _EventEditor(
      state: state,
      event: event,
      start: s,
      end: event?.end ?? end ?? s.add(const Duration(hours: 1)),
      allDay: event?.allDay ?? allDay,
      title: event?.title ?? title,
      chatId: event?.chatId ?? chatId,
      chatTitle: event?.chatTitle ?? chatTitle,
      messageId: event?.messageId ?? messageId,
      messageText: event?.messageText ?? messageText,
    ),
  );
}

DateTime _nextHour() {
  final n = DateTime.now();
  return DateTime(n.year, n.month, n.day, n.hour + 1);
}

/// Deletes [e] and offers to put it back.
Future<void> deleteEventWithUndo(BuildContext context, AppState state, Event e) async {
  await state.events.remove(e.id);
  if (!context.mounted) return;
  showToast(
    context,
    (w) => SnackBar(
      width: w < 480 ? w : 480,
      content: Text('Uchrashuv o‘chirildi: “${e.title}”', maxLines: 1, overflow: TextOverflow.ellipsis),
      action: SnackBarAction(label: 'Qaytarish', onPressed: () => state.events.restore(e)),
    ),
  );
}

class _EventEditor extends StatefulWidget {
  const _EventEditor({
    required this.state,
    required this.start,
    required this.end,
    required this.allDay,
    required this.title,
    this.event,
    this.chatId,
    this.chatTitle,
    this.messageId,
    this.messageText,
  });

  final AppState state;
  final Event? event;
  final DateTime start;
  final DateTime end;
  final bool allDay;
  final String title;
  final String? chatId;
  final String? chatTitle;
  final String? messageId;
  final String? messageText;

  @override
  State<_EventEditor> createState() => _EventEditorState();
}

class _EventEditorState extends State<_EventEditor> {
  late final _title = TextEditingController(text: widget.title);
  late final _note = TextEditingController(text: widget.event?.note ?? '');
  late DateTime _day = DateTime(widget.start.year, widget.start.month, widget.start.day);
  late TimeOfDay _from = TimeOfDay.fromDateTime(widget.start);
  late TimeOfDay _to = TimeOfDay.fromDateTime(widget.end);
  late bool _allDay = widget.allDay;
  late int? _remind = widget.event == null ? 30 : widget.event!.remindBefore;
  String? _error;

  @override
  void dispose() {
    _title.dispose();
    _note.dispose();
    super.dispose();
  }

  DateTime _at(TimeOfDay t) => DateTime(_day.year, _day.month, _day.day, t.hour, t.minute);

  int get _minutes => _at(_to).difference(_at(_from)).inMinutes;

  Future<void> _pickDay() async {
    final d = await showDatePicker(context: context, initialDate: _day, firstDate: DateTime(2020), lastDate: DateTime(2100));
    if (d != null) setState(() => _day = d);
  }

  Future<void> _pickTime(bool start) async {
    final t = await showTimePicker(
      context: context,
      initialTime: start ? _from : _to,
      builder: (context, child) =>
          MediaQuery(data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true), child: child!),
    );
    if (t == null) return;
    setState(() {
      if (start) {
        final keep = _minutes;
        _from = t;
        final end = _at(t).add(Duration(minutes: keep > 0 ? keep : 60));
        _to = TimeOfDay.fromDateTime(end);
      } else {
        _to = t;
      }
      _error = null;
    });
  }

  void _duration(int minutes) => setState(() {
        _to = TimeOfDay.fromDateTime(_at(_from).add(Duration(minutes: minutes)));
        _error = null;
      });

  Future<void> _save() async {
    final title = _title.text.trim();
    if (title.isEmpty) {
      setState(() => _error = 'Uchrashuv nomini kiriting.');
      return;
    }
    if (!_allDay && _minutes <= 0) {
      setState(() => _error = 'Tugash vaqti boshlanishdan keyin bo‘lishi kerak.');
      return;
    }
    final start = _allDay ? _day : _at(_from);
    final end = _allDay ? _day.add(const Duration(days: 1)) : _at(_to);
    final events = widget.state.events;
    final e = widget.event;
    if (e == null) {
      await events.add(
        title: title,
        start: start,
        end: end,
        allDay: _allDay,
        note: _note.text,
        remindBefore: _remind,
        chatId: widget.chatId,
        chatTitle: widget.chatTitle,
        messageId: widget.messageId,
        messageText: widget.messageText,
      );
    } else {
      await events.edit(e.id, title: title, start: start, end: end, allDay: _allDay, note: _note.text, remindBefore: _remind);
    }
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.fc;
    final e = widget.event;
    OutlineInputBorder border(Color color, [double w = 1]) =>
        OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: color, width: w));
    InputDecoration deco(String hint) => InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: c.text2),
          filled: true,
          fillColor: c.bg,
          isDense: true,
          border: border(c.chipBorder),
          enabledBorder: border(c.chipBorder),
          focusedBorder: border(c.accent, 2),
        );
    Widget label(String t) => Padding(
          padding: const EdgeInsets.only(top: 14, bottom: 6),
          child: Text(t, style: TextStyle(color: c.text2, fontSize: 12.5, fontWeight: FontWeight.w700)),
        );
    Widget chip(String text, bool selected, VoidCallback onTap, {IconData? icon}) => ChoiceChip(
          avatar: icon == null ? null : Icon(icon, size: 16, color: selected ? Colors.white : c.icon),
          label: Text(text),
          selected: selected,
          onSelected: (_) => onTap(),
          showCheckmark: false,
          labelStyle: TextStyle(color: selected ? Colors.white : c.textSoft, fontWeight: FontWeight.w600, fontSize: 13),
          selectedColor: c.accentStrong,
          backgroundColor: c.panel,
          side: BorderSide(color: selected ? c.accentStrong : c.chipBorder),
        );
    String hm(TimeOfDay t) => '${Fmt.two(t.hour)}:${Fmt.two(t.minute)}';

    return AlertDialog(
      backgroundColor: c.panel,
      title: Text(e == null ? 'Yangi uchrashuv' : 'Uchrashuv', style: TextStyle(color: c.text, fontSize: 18, fontWeight: FontWeight.w700)),
      content: SizedBox(
        width: 440,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _title,
                autofocus: e == null && widget.title.isEmpty,
                style: TextStyle(color: c.text, fontSize: 15, fontWeight: FontWeight.w600),
                onChanged: (_) {
                  if (_error != null) setState(() => _error = null);
                },
                decoration: deco('Nima? Masalan: Demo, «Olimp» bilan'),
              ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(_error!, style: TextStyle(color: c.danger, fontSize: 13)),
                ),
              label('Qachon'),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  chip('${MeetingParser.weekdayNames[_day.weekday - 1]}, ${Fmt.dueLabel(_day)}', false, _pickDay,
                      icon: Icons.event_outlined),
                  if (!_allDay) ...[
                    chip(hm(_from), false, () => _pickTime(true), icon: Icons.schedule),
                    Text('—', style: TextStyle(color: c.text2)),
                    chip(hm(_to), false, () => _pickTime(false)),
                  ],
                  FilterChip(
                    label: const Text('Kun bo‘yi'),
                    selected: _allDay,
                    onSelected: (v) => setState(() => _allDay = v),
                    labelStyle: TextStyle(color: c.textSoft, fontWeight: FontWeight.w600, fontSize: 13),
                    selectedColor: c.accentSoft,
                    checkmarkColor: c.accentText,
                    backgroundColor: c.panel,
                    side: BorderSide(color: c.chipBorder),
                  ),
                ],
              ),
              if (!_allDay) ...[
                label('Davomiyligi'),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final m in const [30, 60, 90, 120])
                      chip(m < 60 ? '$m daqiqa' : (m % 60 == 0 ? '${m ~/ 60} soat' : '${m ~/ 60},5 soat'), _minutes == m,
                          () => _duration(m)),
                  ],
                ),
              ],
              label('Eslatma'),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final r in kReminderChoices.entries) chip(r.value, _remind == r.key, () => setState(() => _remind = r.key)),
                ],
              ),
              label('Izoh'),
              TextField(
                controller: _note,
                minLines: 2,
                maxLines: 6,
                style: TextStyle(color: c.text, fontSize: 14),
                decoration: deco('Manzil, havola yoki qo‘shimcha ma’lumot'),
              ),
              if (widget.chatId != null) ...[
                label('Chatdan'),
                ChatSourceBox(
                  state: widget.state,
                  chatId: widget.chatId!,
                  chatTitle: widget.chatTitle,
                  messageText: widget.messageText,
                  onOpenChat: () {
                    widget.state.module = Module.chats;
                    widget.state.openChat(widget.chatId!);
                  },
                ),
              ],
            ],
          ),
        ),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      actions: [
        if (e != null)
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              deleteEventWithUndo(context, widget.state, e);
            },
            style: TextButton.styleFrom(foregroundColor: c.danger),
            child: const Text('O‘chirish'),
          ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          style: TextButton.styleFrom(foregroundColor: c.text2),
          child: const Text('Bekor qilish'),
        ),
        FilledButton(
          onPressed: _save,
          style: FilledButton.styleFrom(backgroundColor: c.accentStrong, foregroundColor: Colors.white),
          child: Text(e == null ? 'Qo‘shish' : 'Saqlash'),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';

import '../../data/format.dart';
import '../../db/database.dart';
import '../../state/app_state.dart';
import '../../theme.dart';
import '../common.dart';

/// Create a task (in [status]) or edit [task].
Future<void> showTaskEditor(BuildContext context, AppState state, {Task? task, TaskStatus status = TaskStatus.planned}) {
  return showDialog<void>(
    context: context,
    builder: (_) => _TaskEditor(state: state, task: task, status: task?.status ?? status),
  );
}

/// Deletes [task] and offers to put it back.
Future<void> deleteTaskWithUndo(BuildContext context, AppState state, Task task) async {
  await state.tasks.remove(task.id);
  if (!context.mounted) return;
  showToast(
    context,
    (w) => SnackBar(
      width: w < 480 ? w : 480,
      content: Text('Vazifa o‘chirildi: “${task.title}”', maxLines: 1, overflow: TextOverflow.ellipsis),
      action: SnackBarAction(label: 'Qaytarish', onPressed: () => state.tasks.restore(task)),
    ),
  );
}

class _TaskEditor extends StatefulWidget {
  const _TaskEditor({required this.state, required this.status, this.task});

  final AppState state;
  final Task? task;
  final TaskStatus status;

  @override
  State<_TaskEditor> createState() => _TaskEditorState();
}

class _TaskEditorState extends State<_TaskEditor> {
  late final _title = TextEditingController(text: widget.task?.title ?? '');
  late final _note = TextEditingController(text: widget.task?.note ?? '');
  late TaskStatus _status = widget.status;
  late DateTime? _due = widget.task?.due;
  late bool _important = widget.task?.important ?? false;
  String? _error;

  @override
  void dispose() {
    _title.dispose();
    _note.dispose();
    super.dispose();
  }

  static DateTime _today() {
    final n = DateTime.now();
    return DateTime(n.year, n.month, n.day);
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _due ?? _today(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _due = picked);
  }

  Future<void> _save() async {
    final title = _title.text.trim();
    if (title.isEmpty) {
      setState(() => _error = 'Vazifa nomini kiriting.');
      return;
    }
    final tasks = widget.state.tasks;
    final task = widget.task;
    if (task == null) {
      await tasks.add(title: title, note: _note.text, status: _status, due: _due, important: _important);
    } else {
      await tasks.edit(task.id, title: title, note: _note.text, important: _important, due: _due, clearDue: _due == null);
      if (_status != task.status) await tasks.move(task.id, _status);
    }
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.fc;
    final task = widget.task;
    final today = _today();
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
    Widget choice(String text, bool selected, VoidCallback onTap) => ChoiceChip(
          label: Text(text),
          selected: selected,
          onSelected: (_) => onTap(),
          showCheckmark: false,
          labelStyle: TextStyle(color: selected ? Colors.white : c.textSoft, fontWeight: FontWeight.w600, fontSize: 13),
          selectedColor: c.accentStrong,
          backgroundColor: c.panel,
          side: BorderSide(color: selected ? c.accentStrong : c.chipBorder),
        );

    final dueIsPreset = _due == null ||
        _due == today ||
        _due == today.add(const Duration(days: 1)) ||
        _due == today.add(const Duration(days: 7));

    return AlertDialog(
      backgroundColor: c.panel,
      titlePadding: const EdgeInsets.fromLTRB(24, 20, 12, 0),
      title: Row(
        children: [
          Expanded(
            child: Text(task == null ? 'Yangi vazifa' : 'Vazifa',
                style: TextStyle(color: c.text, fontSize: 18, fontWeight: FontWeight.w700)),
          ),
          IconButton(
            tooltip: _important ? 'Muhim emas' : 'Muhim deb belgilash',
            onPressed: () => setState(() => _important = !_important),
            icon: Icon(_important ? Icons.star_rounded : Icons.star_outline_rounded,
                color: _important ? c.waiting : c.icon),
          ),
        ],
      ),
      content: SizedBox(
        width: 440,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _title,
                autofocus: task == null,
                minLines: 1,
                maxLines: 3,
                style: TextStyle(color: c.text, fontSize: 15, fontWeight: FontWeight.w600),
                onChanged: (_) {
                  if (_error != null) setState(() => _error = null);
                },
                decoration: deco('Nima qilish kerak?').copyWith(errorText: _error),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _note,
                minLines: 2,
                maxLines: 6,
                style: TextStyle(color: c.text, fontSize: 14),
                decoration: deco('Izoh (ixtiyoriy)'),
              ),
              label('Holat'),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final s in TaskStatus.values) choice(s.label, _status == s, () => setState(() => _status = s)),
                ],
              ),
              label('Muddat'),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  choice('Muddatsiz', _due == null, () => setState(() => _due = null)),
                  choice('Bugun', _due == today, () => setState(() => _due = today)),
                  choice('Ertaga', _due == today.add(const Duration(days: 1)),
                      () => setState(() => _due = today.add(const Duration(days: 1)))),
                  choice('Bir haftadan keyin', _due == today.add(const Duration(days: 7)),
                      () => setState(() => _due = today.add(const Duration(days: 7)))),
                  choice(dueIsPreset ? 'Sana tanlash…' : Fmt.dueLabel(_due!), !dueIsPreset, _pickDate),
                ],
              ),
              if (task?.chatId != null) ...[
                label('Chatdan'),
                _SourceBox(state: widget.state, task: task!),
              ],
            ],
          ),
        ),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      actions: [
        if (task != null)
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              deleteTaskWithUndo(context, widget.state, task);
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
          child: Text(task == null ? 'Yaratish' : 'Saqlash'),
        ),
      ],
    );
  }
}

/// The chat and message a task was made from, with a way back to the chat.
class _SourceBox extends StatelessWidget {
  const _SourceBox({required this.state, required this.task});

  final AppState state;
  final Task task;

  @override
  Widget build(BuildContext context) {
    final c = context.fc;
    final chat = state.source.chatById(task.chatId!);
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: c.bg, borderRadius: BorderRadius.circular(10)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (chat != null) ChatAvatar(chat, size: 26, showOnline: false) else Icon(Icons.chat_bubble_outline, size: 20, color: c.icon),
              const SizedBox(width: 8),
              Expanded(
                child: Text(chat?.name ?? task.chatTitle ?? 'Chat',
                    maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: c.text, fontWeight: FontWeight.w600)),
              ),
              if (chat != null)
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    state.openTaskChat(task);
                  },
                  style: TextButton.styleFrom(foregroundColor: c.accentText),
                  child: const Text('Chatni ochish'),
                ),
            ],
          ),
          if ((task.messageText ?? '').isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(task.messageText!,
                  maxLines: 4, overflow: TextOverflow.ellipsis, style: TextStyle(color: c.textSoft, fontSize: 13.5, height: 1.35)),
            ),
        ],
      ),
    );
  }
}

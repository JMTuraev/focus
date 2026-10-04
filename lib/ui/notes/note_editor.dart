import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../db/database.dart';
import '../../notes/note_store.dart';
import '../../state/app_state.dart';
import '../../theme.dart';
import '../common.dart';
import '../source_box.dart';

/// Opens [note] (or a new text note / checklist). Changes are saved when
/// the editor closes, however it is closed; an empty new note is dropped.
Future<void> showNoteEditor(BuildContext context, AppState state, {Note? note, bool checklist = false}) {
  return showDialog<void>(
    context: context,
    builder: (_) => _NoteEditor(state: state, note: note, checklist: note?.checklist ?? checklist),
  );
}

/// Deletes [n] and offers to put it back.
Future<void> deleteNoteWithUndo(BuildContext context, AppState state, Note n) async {
  await state.notes.remove(n.id);
  if (!context.mounted) return;
  final what = n.title.isNotEmpty
      ? n.title
      : n.body.isNotEmpty
          ? n.body
          : (n.items.isNotEmpty ? n.items.first.text : 'ro‘yxat');
  showToast(
    context,
    (w) => SnackBar(
      width: w < 480 ? w : 480,
      content: Text('Eslatma o‘chirildi: “$what”', maxLines: 1, overflow: TextOverflow.ellipsis),
      action: SnackBarAction(label: 'Qaytarish', onPressed: () => state.notes.restore(n)),
    ),
  );
}

class _ItemRow {
  _ItemRow(String text, this.done) : ctrl = TextEditingController(text: text);

  final TextEditingController ctrl;
  final FocusNode focus = FocusNode();
  bool done;

  void dispose() {
    ctrl.dispose();
    focus.dispose();
  }
}

class _NoteEditor extends StatefulWidget {
  const _NoteEditor({required this.state, required this.checklist, this.note});

  final AppState state;
  final Note? note;
  final bool checklist;

  @override
  State<_NoteEditor> createState() => _NoteEditorState();
}

class _NoteEditorState extends State<_NoteEditor> {
  late final _title = TextEditingController(text: widget.note?.title ?? '');
  late final _body = TextEditingController(text: widget.note?.body ?? '');
  late final List<_ItemRow> _items = [
    for (final i in widget.note?.items ?? const <NoteItem>[]) _ItemRow(i.text, i.done)
  ];
  late bool _checklist = widget.checklist;
  late NoteColor _color = widget.note?.color ?? NoteColor.none;
  late bool _pinned = widget.note?.pinned ?? false;
  bool _deleted = false;

  @override
  void initState() {
    super.initState();
    if (_checklist && _items.isEmpty) _items.add(_ItemRow('', false));
  }

  List<NoteItem> get _currentItems => [for (final r in _items) NoteItem(r.ctrl.text, done: r.done)];

  /// Saves on close. Runs from dispose, so it must not touch the context.
  void _persist() {
    if (_deleted) return;
    final store = widget.state.notes;
    final title = _title.text;
    final body = _checklist ? '' : _body.text;
    final items = _checklist ? _currentItems : const <NoteItem>[];
    final n = widget.note;
    if (n == null) {
      if (NoteStore.isEmpty(title: title, body: body, items: items)) return;
      store.add(title: title, body: body, items: items, checklist: _checklist, color: _color, pinned: _pinned);
      return;
    }
    final changed = title.trim() != n.title ||
        body.trim() != n.body ||
        _checklist != n.checklist ||
        _color != n.color ||
        _pinned != n.pinned ||
        !_sameItems(items, n.items);
    if (changed) {
      store.edit(n.id, title: title, body: body, items: items, checklist: _checklist, color: _color, pinned: _pinned);
    }
  }

  static bool _sameItems(List<NoteItem> a, List<NoteItem> b) {
    final clean = [
      for (final i in a)
        if (i.text.trim().isNotEmpty) NoteItem(i.text.trim(), done: i.done)
    ];
    if (clean.length != b.length) return false;
    for (var i = 0; i < clean.length; i++) {
      if (clean[i] != b[i]) return false;
    }
    return true;
  }

  @override
  void dispose() {
    _persist();
    _title.dispose();
    _body.dispose();
    for (final r in _items) {
      r.dispose();
    }
    super.dispose();
  }

  void _toggleChecklist() {
    setState(() {
      final (body, items) = NoteStore.convert(toChecklist: !_checklist, body: _body.text, items: _currentItems);
      for (final r in _items) {
        r.dispose();
      }
      _items
        ..clear()
        ..addAll([for (final i in items) _ItemRow(i.text, i.done)]);
      if (!_checklist && _items.isEmpty) _items.add(_ItemRow('', false));
      _body.text = body;
      _checklist = !_checklist;
    });
  }

  void _addItem({int? after}) {
    final row = _ItemRow('', false);
    setState(() => _items.insert(after == null ? _items.length : after + 1, row));
    WidgetsBinding.instance.addPostFrameCallback((_) => row.focus.requestFocus());
  }

  void _removeItem(int i) {
    final row = _items[i];
    setState(() => _items.removeAt(i));
    row.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.fc;
    final n = widget.note;
    final bg = c.noteColors[_color.index];
    final plain = InputDecoration(
      isDense: true,
      border: InputBorder.none,
      hintStyle: TextStyle(color: c.text2),
    );
    return Dialog(
      backgroundColor: bg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520, maxHeight: 640),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      controller: _title,
                      autofocus: n == null && !_checklist,
                      style: TextStyle(color: c.text, fontSize: 17, fontWeight: FontWeight.w700),
                      decoration: plain.copyWith(hintText: 'Sarlavha'),
                    ),
                    const SizedBox(height: 6),
                    if (!_checklist)
                      TextField(
                        controller: _body,
                        minLines: 4,
                        maxLines: null,
                        style: TextStyle(color: c.text, fontSize: 14.5, height: 1.4),
                        decoration: plain.copyWith(hintText: 'Eslatma…'),
                      )
                    else ...[
                      for (var i = 0; i < _items.length; i++) _itemRow(c, i, plain),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton.icon(
                          onPressed: _addItem,
                          icon: Icon(Icons.add, size: 18, color: c.accentText),
                          label: Text('Element qo‘shish', style: TextStyle(color: c.accentText)),
                        ),
                      ),
                    ],
                    if (n?.chatId != null) ...[
                      const SizedBox(height: 10),
                      ChatSourceBox(
                        state: widget.state,
                        chatId: n!.chatId!,
                        chatTitle: n.chatTitle,
                        onOpenChat: () => widget.state.openNoteChat(n),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            _toolbar(c, n),
          ],
        ),
      ),
    );
  }

  Widget _itemRow(FokusColors c, int i, InputDecoration plain) {
    final r = _items[i];
    // Backspace on an empty line removes it and goes to the line above
    // (like Keep); any other key is handled by the text field as usual.
    r.focus.onKeyEvent = (node, event) {
      if (event is KeyDownEvent &&
          event.logicalKey == LogicalKeyboardKey.backspace &&
          r.ctrl.text.isEmpty &&
          _items.length > 1) {
        final at = _items.indexOf(r);
        final prev = at > 0 ? _items[at - 1] : null;
        _removeItem(at);
        prev?.focus.requestFocus();
        return KeyEventResult.handled;
      }
      return KeyEventResult.ignored;
    };
    return Row(
      children: [
        Checkbox(
          value: r.done,
          onChanged: (v) => setState(() => r.done = v ?? false),
          activeColor: c.accentStrong,
          side: BorderSide(color: c.text2, width: 1.5),
          visualDensity: VisualDensity.compact,
        ),
        Expanded(
          child: TextField(
            controller: r.ctrl,
            focusNode: r.focus,
            autofocus: i == _items.length - 1 && widget.note == null,
            onSubmitted: (_) => _addItem(after: i),
            style: TextStyle(
              color: r.done ? c.text2 : c.text,
              fontSize: 14.5,
              decoration: r.done ? TextDecoration.lineThrough : null,
            ),
            decoration: plain.copyWith(hintText: 'Element'),
          ),
        ),
        IconButton(
          tooltip: 'Olib tashlash',
          visualDensity: VisualDensity.compact,
          onPressed: () => _removeItem(i),
          icon: Icon(Icons.close, size: 16, color: c.text2),
        ),
      ],
    );
  }

  Widget _toolbar(FokusColors c, Note? n) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        runSpacing: 6,
        children: [
          Wrap(
            spacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              for (final col in NoteColor.values)
                Tooltip(
                  message: col.label,
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: () => setState(() => _color = col),
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: c.noteColors[col.index],
                        shape: BoxShape.circle,
                        border:
                            Border.all(color: _color == col ? c.accent : c.chipBorder, width: _color == col ? 2.5 : 1),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                tooltip: _pinned ? 'Qadashni olib tashlash' : 'Qadash',
                onPressed: () => setState(() => _pinned = !_pinned),
                icon: Icon(_pinned ? Icons.push_pin : Icons.push_pin_outlined,
                    size: 20, color: _pinned ? c.accentText : c.icon),
              ),
              IconButton(
                tooltip: _checklist ? 'Matnga aylantirish' : 'Ro‘yxatga aylantirish',
                onPressed: _toggleChecklist,
                icon: Icon(_checklist ? Icons.notes : Icons.checklist, size: 20, color: c.icon),
              ),
              if (n != null)
                IconButton(
                  tooltip: 'O‘chirish',
                  onPressed: () {
                    _deleted = true;
                    Navigator.pop(context);
                    deleteNoteWithUndo(context, widget.state, n);
                  },
                  icon: Icon(Icons.delete_outline, size: 20, color: c.danger),
                ),
              const SizedBox(width: 4),
              FilledButton(
                onPressed: () => Navigator.pop(context),
                style: FilledButton.styleFrom(backgroundColor: c.accentStrong, foregroundColor: Colors.white),
                child: const Text('Tayyor'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

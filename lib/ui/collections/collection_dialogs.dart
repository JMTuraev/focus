import 'package:flutter/material.dart';

import '../../data/models.dart';
import '../../state/app_state.dart';
import '../../theme.dart';

/// Create a collection, or rename / change the icon of [existing].
/// Returns the created or edited collection, or null if cancelled.
Future<Collection?> showCollectionEditor(BuildContext context, AppState state, {Collection? existing}) {
  return showDialog<Collection>(
    context: context,
    builder: (context) => _CollectionEditor(state: state, existing: existing),
  );
}

class _CollectionEditor extends StatefulWidget {
  const _CollectionEditor({required this.state, this.existing});

  final AppState state;
  final Collection? existing;

  @override
  State<_CollectionEditor> createState() => _CollectionEditorState();
}

class _CollectionEditorState extends State<_CollectionEditor> {
  late final _name = TextEditingController(text: widget.existing?.label ?? '');
  late String _icon = widget.existing?.iconKey ?? 'folder';
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _save() {
    final name = _name.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Nomini kiriting.');
      return;
    }
    final taken =
        widget.state.collections.any((c) => c.id != widget.existing?.id && c.label.toLowerCase() == name.toLowerCase());
    if (taken || name.toLowerCase() == kAllCollection.label.toLowerCase()) {
      setState(() => _error = 'Bu nomdagi to‘plam allaqachon bor.');
      return;
    }
    final existing = widget.existing;
    if (existing == null) {
      Navigator.pop(context, widget.state.createCollection(name, _icon));
    } else {
      widget.state.updateCollection(existing.id, label: name, iconKey: _icon);
      Navigator.pop(context, Collection(existing.id, name, _icon));
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.fc;
    OutlineInputBorder border(Color color, [double w = 1]) =>
        OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: color, width: w));
    return AlertDialog(
      backgroundColor: c.panel,
      title: Text(
        widget.existing == null ? 'Yangi to‘plam' : 'To‘plamni tahrirlash',
        style: TextStyle(color: c.text, fontSize: 18, fontWeight: FontWeight.w700),
      ),
      content: SizedBox(
        width: 360,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _name,
              autofocus: true,
              maxLength: 24,
              onSubmitted: (_) => _save(),
              onChanged: (_) {
                if (_error != null) setState(() => _error = null);
              },
              style: TextStyle(color: c.text, fontSize: 15),
              decoration: InputDecoration(
                hintText: 'Masalan: Yetkazib beruvchilar',
                hintStyle: TextStyle(color: c.text2),
                errorText: _error,
                filled: true,
                fillColor: c.bg,
                counterStyle: TextStyle(color: c.text2),
                border: border(c.chipBorder),
                enabledBorder: border(c.chipBorder),
                focusedBorder: border(c.accent, 2),
              ),
            ),
            const SizedBox(height: 8),
            Text('Ikonka', style: TextStyle(color: c.text2, fontSize: 13, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final e in kCollectionIcons.entries.where((e) => e.key != kAllCollection.iconKey))
                  Tooltip(
                    message: e.key,
                    waitDuration: const Duration(seconds: 1),
                    child: InkWell(
                      onTap: () => setState(() => _icon = e.key),
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: _icon == e.key ? c.accentSoft : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: _icon == e.key ? c.accent : c.chipBorder),
                        ),
                        child: Icon(e.value, size: 20, color: _icon == e.key ? c.accentText : c.icon),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          style: TextButton.styleFrom(foregroundColor: c.text2),
          child: const Text('Bekor qilish'),
        ),
        FilledButton(
          onPressed: _save,
          style: FilledButton.styleFrom(backgroundColor: c.accentStrong, foregroundColor: Colors.white),
          child: Text(widget.existing == null ? 'Yaratish' : 'Saqlash'),
        ),
      ],
    );
  }
}

/// Asks before deleting [col]; its chats become unsorted (nothing is lost).
Future<void> confirmDeleteCollection(BuildContext context, AppState state, Collection col) async {
  final c = context.fc;
  final count = state.countIn(col.id);
  final ok = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: c.panel,
      title: Text('«${col.label}» o‘chirilsinmi?',
          style: TextStyle(color: c.text, fontSize: 18, fontWeight: FontWeight.w700)),
      content: Text(
        count == 0
            ? 'To‘plam bo‘sh. Telegram’dagi chatlarga ta’sir qilmaydi.'
            : 'Undagi $count ta chat «Saralanmagan»ga qaytadi. Telegram’dagi chatlarga ta’sir qilmaydi.',
        style: TextStyle(color: c.text2, fontSize: 14, height: 1.4),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          style: TextButton.styleFrom(foregroundColor: c.text2),
          child: const Text('Bekor qilish'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          style: TextButton.styleFrom(foregroundColor: c.danger),
          child: const Text('O‘chirish'),
        ),
      ],
    ),
  );
  if (ok == true) state.deleteCollection(col.id);
}

/// Context menu for a chat: move it to a collection or back to unsorted.
Future<void> showAssignMenu(BuildContext context, AppState state, Chat chat, Offset globalPosition) async {
  final c = context.fc;
  final current = state.collectionOf(chat);
  final overlay = Overlay.of(context).context.findRenderObject()! as RenderBox;
  final choice = await showMenu<String>(
    context: context,
    color: c.panel,
    position: RelativeRect.fromRect(globalPosition & const Size(1, 1), Offset.zero & overlay.size),
    items: [
      PopupMenuItem<String>(
        enabled: false,
        height: 32,
        child:
            Text('To‘plamga qo‘shish', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: c.text2)),
      ),
      for (final col in state.collections)
        PopupMenuItem<String>(
          value: col.id,
          height: 38,
          child: Row(
            children: [
              Icon(col.icon, size: 18, color: c.icon),
              const SizedBox(width: 10),
              Expanded(child: Text(col.label, style: TextStyle(color: c.text, fontSize: 14))),
              if (col.id == current) Icon(Icons.check, size: 18, color: c.accentText),
            ],
          ),
        ),
      const PopupMenuDivider(),
      PopupMenuItem<String>(
        value: '+new',
        height: 38,
        child: Row(
          children: [
            Icon(Icons.add, size: 18, color: c.accentText),
            const SizedBox(width: 10),
            Text('Yangi to‘plam…', style: TextStyle(color: c.accentText, fontSize: 14)),
          ],
        ),
      ),
      if (current.isNotEmpty)
        PopupMenuItem<String>(
          value: '',
          height: 38,
          child: Row(
            children: [
              Icon(Icons.remove_circle_outline, size: 18, color: c.icon),
              const SizedBox(width: 10),
              Text('To‘plamdan chiqarish', style: TextStyle(color: c.text, fontSize: 14)),
            ],
          ),
        ),
    ],
  );
  if (choice == null) return;
  if (choice == '+new') {
    if (!context.mounted) return;
    final created = await showCollectionEditor(context, state);
    if (created != null) state.moveToCollection(chat.id, created.id);
    return;
  }
  state.moveToCollection(chat.id, choice);
}

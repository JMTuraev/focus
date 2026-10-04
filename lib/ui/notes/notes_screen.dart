import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../db/database.dart';
import '../../l10n/l10n.dart';
import '../../notes/note_store.dart';
import '../../state/app_state.dart';
import '../../theme.dart';
import '../common.dart';
import 'note_editor.dart';

/// Notes in colored cards (masonry), pinned first; checklists can be
/// ticked right on the card.
class NotesScreen extends StatefulWidget {
  const NotesScreen({super.key, required this.state});

  final AppState state;

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  String _query = '';
  NoteFilter _filter = NoteFilter.all;

  AppState get s => widget.state;

  @override
  Widget build(BuildContext context) {
    final c = context.fc;
    final t = context.s.notes;
    return ListenableBuilder(
      listenable: s.notes,
      builder: (context, _) => LayoutBuilder(
        builder: (context, box) {
          final pad = box.maxWidth < 600 ? 12.0 : 24.0;
          final notes = s.notes.filtered(filter: _filter, query: _query, chatId: s.noteChatFilter);
          final pinned = notes.where((n) => n.pinned).toList();
          final others = notes.where((n) => !n.pinned).toList();
          final width = box.maxWidth - pad * 2;
          return Container(
            color: c.bg,
            child: CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(pad, 20, pad, 0),
                  sliver: SliverToBoxAdapter(child: _header(c, box.maxWidth)),
                ),
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(pad, 12, pad, 0),
                  sliver: SliverToBoxAdapter(child: _filters(c)),
                ),
                if (notes.isEmpty)
                  SliverFillRemaining(hasScrollBody: false, child: _empty(c))
                else ...[
                  if (pinned.isNotEmpty) ...[
                    _sectionTitle(c, t.pinnedSection, pad),
                    _grid(pinned, width, pad),
                  ],
                  if (others.isNotEmpty) ...[
                    if (pinned.isNotEmpty) _sectionTitle(c, t.othersSection, pad),
                    _grid(others, width, pad),
                  ],
                  const SliverToBoxAdapter(child: SizedBox(height: 24)),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _header(FokusColors c, double width) {
    final total = s.notes.all.length;
    final t = context.s.notes;
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
            Text(t.notesTitle, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: c.text)),
            Text(t.notesCount(total), style: TextStyle(fontSize: 13, color: c.text2)),
          ],
        ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            SizedBox(
              width: width < 600 ? 170 : 240,
              height: 36,
              child: TextField(
                onChanged: (v) => setState(() => _query = v),
                style: TextStyle(fontSize: 14, color: c.text),
                decoration: InputDecoration(
                  hintText: t.searchHint,
                  hintStyle: TextStyle(color: c.text2),
                  prefixIcon: Icon(Icons.search, size: 18, color: c.text2),
                  filled: true,
                  fillColor: c.panel,
                  contentPadding: EdgeInsets.zero,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide.none),
                ),
              ),
            ),
            OutlinedButton.icon(
              onPressed: () => showNoteEditor(context, s, checklist: true),
              icon: Icon(Icons.checklist, size: 18, color: c.accentText),
              label: Text(width < 600 ? t.newChecklistShort : t.newChecklist, style: TextStyle(color: c.accentText)),
              style: OutlinedButton.styleFrom(side: BorderSide(color: c.chipBorder)),
            ),
            FilledButton.icon(
              onPressed: () => showNoteEditor(context, s),
              icon: const Icon(Icons.add, size: 18),
              label: Text(width < 600 ? t.newNoteShort : t.newNote),
              style: FilledButton.styleFrom(backgroundColor: c.accentStrong, foregroundColor: Colors.white),
            ),
          ],
        ),
      ],
    );
  }

  Widget _filters(FokusColors c) {
    final chatId = s.noteChatFilter;
    final chat = chatId == null ? null : s.source.chatById(chatId);
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        for (final f in NoteFilter.values)
          ChoiceChip(
            label: Text(f.label),
            selected: _filter == f,
            showCheckmark: false,
            onSelected: (_) => setState(() => _filter = f),
            labelStyle: TextStyle(color: _filter == f ? Colors.white : c.textSoft, fontWeight: FontWeight.w600),
            selectedColor: c.accentStrong,
            backgroundColor: c.panel,
            side: BorderSide(color: _filter == f ? c.accentStrong : c.chipBorder),
          ),
        if (chatId != null)
          InputChip(
            avatar: chat == null ? null : ChatAvatar(chat, size: 22, showOnline: false),
            label: Text(context.s.notes.onlyChat(chat?.name),
                maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: c.text, fontWeight: FontWeight.w600)),
            backgroundColor: c.accentSoft,
            side: BorderSide.none,
            deleteIcon: Icon(Icons.close, size: 16, color: c.icon),
            deleteButtonTooltipMessage: context.s.notes.removeFilter,
            onDeleted: s.clearNoteChatFilter,
          ),
      ],
    );
  }

  Widget _empty(FokusColors c) {
    final searching = _query.trim().isNotEmpty || _filter != NoteFilter.all || s.noteChatFilter != null;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.sticky_note_2_outlined, size: 48, color: c.text2),
            const SizedBox(height: 10),
            Text(
              searching ? context.s.notes.noMatches : context.s.notes.emptyHint,
              textAlign: TextAlign.center,
              style: TextStyle(color: c.text2, fontSize: 14, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(FokusColors c, String text, double pad) => SliverPadding(
        padding: EdgeInsets.fromLTRB(pad + 2, 18, pad, 8),
        sliver: SliverToBoxAdapter(
          child: Text(text.toUpperCase(),
              style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, letterSpacing: 0.8, color: c.text2)),
        ),
      );

  /// Masonry: each card goes to the column that is shortest so far,
  /// using a rough height estimate from its content.
  Widget _grid(List<Note> notes, double width, double pad) {
    const gap = 12.0;
    final cols = math.max(1, ((width + gap) / (250 + gap)).floor());
    final columns = List.generate(cols, (_) => <Note>[]);
    final heights = List.filled(cols, 0.0);
    for (final n in notes) {
      final lines = n.checklist ? math.min(n.items.length, 8) : math.min('\n'.allMatches(n.body).length + 1 + n.body.length ~/ 32, 12);
      final h = 60.0 + lines * 20 + (n.title.isNotEmpty ? 22 : 0) + (n.chatId != null ? 26 : 0);
      var target = 0;
      for (var i = 1; i < cols; i++) {
        if (heights[i] < heights[target]) target = i;
      }
      columns[target].add(n);
      heights[target] += h + gap;
    }
    return SliverPadding(
      padding: EdgeInsets.symmetric(horizontal: pad),
      sliver: SliverToBoxAdapter(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var i = 0; i < cols; i++) ...[
              if (i > 0) const SizedBox(width: gap),
              Expanded(
                child: Column(
                  children: [
                    for (final n in columns[i])
                      Padding(padding: const EdgeInsets.only(bottom: gap), child: _NoteCard(state: s, note: n)),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _NoteCard extends StatelessWidget {
  const _NoteCard({required this.state, required this.note});

  final AppState state;
  final Note note;

  static const _maxItems = 8;

  Future<void> _menu(BuildContext context, Offset pos) async {
    final c = context.fc;
    final t = context.s.notes;
    final n = note;
    final overlay = Overlay.of(context).context.findRenderObject()! as RenderBox;
    final choice = await showMenu<String>(
      context: context,
      color: c.panel,
      position: RelativeRect.fromRect(pos & const Size(1, 1), Offset.zero & overlay.size),
      items: [
        PopupMenuItem(
          value: 'pin',
          height: 38,
          child: Text(n.pinned ? t.unpin : t.pin, style: TextStyle(color: c.text)),
        ),
        PopupMenuItem(
          value: 'convert',
          height: 38,
          child: Text(n.checklist ? t.toText : t.toChecklist, style: TextStyle(color: c.text)),
        ),
        PopupMenuItem(
          enabled: false,
          height: 40,
          child: Wrap(
            spacing: 4,
            children: [
              for (final col in NoteColor.values)
                Tooltip(
                  message: col.label,
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: () {
                      Navigator.pop(context);
                      state.notes.edit(n.id, color: col);
                    },
                    child: Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        color: c.noteColors[col.index],
                        shape: BoxShape.circle,
                        border: Border.all(color: n.color == col ? c.accent : c.chipBorder, width: n.color == col ? 2.5 : 1),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        if (n.chatId != null)
          PopupMenuItem(value: 'chat', height: 38, child: Text(t.openChat, style: TextStyle(color: c.text))),
        PopupMenuItem(
            value: 'delete', height: 38, child: Text(context.s.common.delete, style: TextStyle(color: c.danger))),
      ],
    );
    if (choice == null || !context.mounted) return;
    switch (choice) {
      case 'pin':
        await state.notes.edit(n.id, pinned: !n.pinned);
      case 'convert':
        final (body, items) = NoteStore.convert(toChecklist: !n.checklist, body: n.body, items: n.items);
        await state.notes.edit(n.id, checklist: !n.checklist, body: body, items: items);
      case 'chat':
        state.openNoteChat(n);
      case 'delete':
        await deleteNoteWithUndo(context, state, n);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.fc;
    final n = note;
    final chat = n.chatId == null ? null : state.source.chatById(n.chatId!);
    return GestureDetector(
      onSecondaryTapDown: (d) => _menu(context, d.globalPosition),
      child: Tap(
        onTap: () => showNoteEditor(context, state, note: n),
        radius: 12,
        color: c.noteColors[n.color.index],
        border: Border.all(color: n.color == NoteColor.none ? c.border : Colors.transparent),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (n.title.isNotEmpty || n.pinned)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(n.title,
                          maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: c.text)),
                    ),
                    if (n.pinned) Icon(Icons.push_pin, size: 16, color: c.text2),
                  ],
                ),
              if (n.title.isNotEmpty) const SizedBox(height: 6),
              if (!n.checklist && n.body.isNotEmpty)
                Text(n.body, maxLines: 12, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 14, height: 1.4, color: c.text)),
              if (n.checklist) ...[
                for (var i = 0; i < n.items.length && i < _maxItems; i++)
                  InkWell(
                    onTap: () => state.notes.toggleItem(n.id, i),
                    borderRadius: BorderRadius.circular(6),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(n.items[i].done ? Icons.check_box : Icons.check_box_outline_blank,
                              size: 18, color: n.items[i].done ? c.accentText : c.text2),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              n.items[i].text,
                              style: TextStyle(
                                fontSize: 14,
                                color: n.items[i].done ? c.text2 : c.text,
                                decoration: n.items[i].done ? TextDecoration.lineThrough : null,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                if (n.items.length > _maxItems)
                  Padding(
                    padding: const EdgeInsets.only(top: 2, left: 26),
                    child: Text(context.s.notes.moreItems(n.items.length - _maxItems),
                        style: TextStyle(fontSize: 12.5, color: c.text2)),
                  ),
              ],
              if (n.chatId != null) ...[
                const SizedBox(height: 10),
                InkWell(
                  onTap: chat == null ? null : () => state.openNoteChat(n),
                  borderRadius: BorderRadius.circular(10),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (chat != null)
                        ChatAvatar(chat, size: 18, showOnline: false)
                      else
                        Icon(Icons.chat_bubble_outline, size: 14, color: c.text2),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(chat?.name ?? n.chatTitle ?? context.s.notes.unknownChat,
                            maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12, color: c.text2)),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

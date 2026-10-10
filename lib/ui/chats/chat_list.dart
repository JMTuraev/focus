import 'package:flutter/material.dart';

import '../../data/models.dart';
import '../../l10n/l10n.dart';
import '../../state/app_state.dart';
import '../../theme.dart';
import '../collections/collection_dialogs.dart';
import '../common.dart';

class ChatList extends StatelessWidget {
  const ChatList({super.key, required this.state, this.width = 340});

  final AppState state;

  /// Column width; `double.infinity` fills the narrow (one-column) layout.
  final double width;

  @override
  Widget build(BuildContext context) {
    final c = context.fc;
    final meta = TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: c.text2);
    final t = context.s.chats;
    final chats = state.visibleChats;
    final col = state.collectionById(state.collection);
    final inCollection = !state.collectionsOpen && state.collection != kAllCollection.id && col != null;
    return Container(
      width: width,
      decoration: BoxDecoration(
        color: c.panel,
        border: width.isFinite ? Border(right: BorderSide(color: c.border)) : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
            child: _PaneSwitch(state: state),
          ),
          if (state.collectionsOpen)
            Expanded(child: _CollectionList(state: state))
          else ...[
            if (!inCollection)
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 6, 12, 2),
                child: _SearchField(onChanged: state.setQuery),
              ),
            Padding(
              padding: EdgeInsets.fromLTRB(inCollection ? 8 : 16, inCollection ? 6 : 10, 16, 4),
              child: Row(
                children: [
                  if (inCollection)
                    // "‹ Ish": one click back to the list of collections.
                    Expanded(
                      child: Tooltip(
                        message: context.s.notes.collectionsTitle,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(8),
                          onTap: state.openCollectionList,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 2),
                            child: Row(
                              children: [
                                Icon(Icons.chevron_left, size: 18, color: c.text2),
                                Icon(col.icon, size: 15, color: c.collectionColor(col.colorKey)),
                                const SizedBox(width: 5),
                                Expanded(
                                  child: Text(col.label,
                                      maxLines: 1, overflow: TextOverflow.ellipsis, style: meta.copyWith(color: c.text)),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    )
                  else
                    Expanded(child: Text(t.allChats, maxLines: 1, overflow: TextOverflow.ellipsis, style: meta)),
                  Text(context.s.common.chatsCount(chats.length), style: meta),
                  const SizedBox(width: 4),
                  _TypeFilterButton(state: state),
                ],
              ),
            ),
            Expanded(
              child: chats.isEmpty
                  ? Center(
                      child: state.loadingChats
                          ? Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(strokeWidth: 2.4, color: c.accent)),
                                const SizedBox(height: 12),
                                Text(t.loadingChats, style: TextStyle(color: c.text2)),
                              ],
                            )
                          : Text(t.noChatsInFilter, style: TextStyle(color: c.text2)),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(6, 0, 6, 8),
                      itemCount: chats.length,
                      itemBuilder: (_, i) => _ChatTile(state: state, chat: chats[i]),
                    ),
            ),
          ],
        ],
      ),
    );
  }
}

/// "Chatlar | To‘plamlar" above the chat list. "Chatlar" shows every chat;
/// "To‘plamlar" shows the list of collections, then the chats of the one
/// that is picked.
class _PaneSwitch extends StatelessWidget {
  const _PaneSwitch({required this.state});

  final AppState state;

  @override
  Widget build(BuildContext context) {
    final c = context.fc;
    final allSide = !state.collectionsOpen && state.collection == kAllCollection.id;
    final inCollections = state.collections.fold(0, (n, col) => n + state.badgeFor(col.id));
    return Container(
      height: 34,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(color: c.bg, borderRadius: BorderRadius.circular(10)),
      child: Row(
        children: [
          Expanded(
            child: _PaneButton(
              label: context.s.app.chats,
              badge: state.badgeFor(kAllCollection.id),
              active: allSide,
              onTap: () => state.pickCollection(kAllCollection.id),
            ),
          ),
          const SizedBox(width: 3),
          Expanded(
            child: _PaneButton(
              label: context.s.notes.collectionsTitle,
              badge: inCollections,
              active: !allSide,
              onTap: state.openCollectionList,
            ),
          ),
        ],
      ),
    );
  }
}

class _PaneButton extends StatelessWidget {
  const _PaneButton({required this.label, required this.badge, required this.active, required this.onTap});

  final String label;
  final int badge;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.fc;
    final fg = active ? c.text : c.text2;
    return Tap(
      onTap: onTap,
      radius: 8,
      color: active ? c.panel : Colors.transparent,
      hover: active ? c.panel : c.hover,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Flexible(
            child: Text(label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: fg)),
          ),
          if (badge > 0) ...[const SizedBox(width: 6), _SmallBadge(badge, strong: active)],
        ],
      ),
    );
  }
}

class _SmallBadge extends StatelessWidget {
  const _SmallBadge(this.count, {this.strong = false});

  final int count;
  final bool strong;

  @override
  Widget build(BuildContext context) {
    final c = context.fc;
    return Container(
      constraints: const BoxConstraints(minWidth: 18),
      height: 18,
      padding: const EdgeInsets.symmetric(horizontal: 5),
      alignment: Alignment.center,
      decoration: BoxDecoration(color: strong ? c.accentStrong : c.muted, borderRadius: BorderRadius.circular(9)),
      child: Text(
        count > 99 ? '99+' : '$count',
        style: const TextStyle(color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.w700),
      ),
    );
  }
}

/// The "To‘plamlar" side: one row per collection (icon, name, chat count,
/// unread badge; right click edits or deletes; long press drags to reorder)
/// and "+ Yangi to‘plam".
class _CollectionList extends StatelessWidget {
  const _CollectionList({required this.state});

  final AppState state;

  @override
  Widget build(BuildContext context) {
    final c = context.fc;
    final t = context.s.notes;
    final cols = state.collections;
    return ListView(
      padding: const EdgeInsets.fromLTRB(6, 2, 6, 8),
      children: [
        ReorderableListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          buildDefaultDragHandles: false,
          onReorder: (from, to) => state.moveCollection(from, to > from ? to - 1 : to),
          proxyDecorator: (child, _, __) => Material(
            color: c.panel,
            borderRadius: BorderRadius.circular(10),
            elevation: 3,
            child: child,
          ),
          itemCount: cols.length,
          itemBuilder: (_, i) => ReorderableDragStartListener(
            key: ValueKey(cols[i].id),
            index: i,
            child: _CollectionRow(
              collection: cols[i],
              count: state.countIn(cols[i].id),
              badge: state.badgeFor(cols[i].id),
              onTap: () => state.pickCollection(cols[i].id),
              onMenu: (pos) => _menu(context, cols[i], pos),
            ),
          ),
        ),
        Tap(
          onTap: () => showCollectionEditor(context, state),
          hover: c.hover,
          child: SizedBox(
            height: 44,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Row(
                children: [
                  SizedBox(width: 36, child: Icon(Icons.add, size: 20, color: c.accentText)),
                  const SizedBox(width: 10),
                  Text(t.newCollection, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: c.accentText)),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _menu(BuildContext context, Collection col, Offset pos) async {
    final c = context.fc;
    final overlay = Overlay.of(context).context.findRenderObject()! as RenderBox;
    final choice = await showMenu<String>(
      context: context,
      color: c.panel,
      position: RelativeRect.fromRect(pos & const Size(1, 1), Offset.zero & overlay.size),
      items: [
        PopupMenuItem(
            value: 'edit', height: 38, child: Text(context.s.common.edit, style: TextStyle(color: c.text, fontSize: 14))),
        PopupMenuItem(
            value: 'delete',
            height: 38,
            child: Text(context.s.common.delete, style: TextStyle(color: c.danger, fontSize: 14))),
      ],
    );
    if (!context.mounted) return;
    switch (choice) {
      case 'edit':
        await showCollectionEditor(context, state, existing: col);
      case 'delete':
        await confirmDeleteCollection(context, state, col);
    }
  }
}

/// A collection in the list. Hovering shows the "⋯" menu (edit, delete);
/// right click opens the same menu; drag the row to reorder.
class _CollectionRow extends StatefulWidget {
  const _CollectionRow({
    required this.collection,
    required this.count,
    required this.badge,
    required this.onTap,
    required this.onMenu,
  });

  final Collection collection;
  final int count;
  final int badge;
  final VoidCallback onTap;
  final void Function(Offset globalPosition) onMenu;

  @override
  State<_CollectionRow> createState() => _CollectionRowState();
}

class _CollectionRowState extends State<_CollectionRow> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final c = context.fc;
    final col = widget.collection;
    final tint = c.collectionColor(col.colorKey);
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onSecondaryTapDown: (d) => widget.onMenu(d.globalPosition),
        child: Tap(
          onTap: widget.onTap,
          hover: c.hover,
          child: SizedBox(
            height: 56,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 0, 4, 0),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(color: tint.withValues(alpha: 0.16), borderRadius: BorderRadius.circular(10)),
                    child: Icon(col.icon, size: 19, color: tint),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(col.label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600, color: c.text)),
                        const SizedBox(height: 2),
                        Text(context.s.common.chatsCount(widget.count),
                            maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12.5, color: c.text2)),
                      ],
                    ),
                  ),
                  if (widget.badge > 0) ...[const SizedBox(width: 6), CountBadge(widget.badge)],
                  if (_hover) ...[
                    const SizedBox(width: 4),
                    Tooltip(
                      message: context.s.notes.actions,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(8),
                        onTapDown: (d) => widget.onMenu(d.globalPosition),
                        onTap: () {},
                        child: Padding(
                          padding: const EdgeInsets.all(4),
                          child: Icon(Icons.more_horiz, size: 20, color: c.text2),
                        ),
                      ),
                    ),
                  ],
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: Icon(Icons.chevron_right, size: 18, color: c.text2),
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

class _SearchField extends StatelessWidget {
  const _SearchField({required this.onChanged});

  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = context.fc;
    return SizedBox(
      height: 38,
      child: TextField(
        onChanged: onChanged,
        style: TextStyle(fontSize: 14, color: c.text),
        decoration: InputDecoration(
          hintText: context.s.common.search,
          hintStyle: TextStyle(color: c.text2),
          prefixIcon: Icon(Icons.search, size: 19, color: c.text2),
          filled: true,
          fillColor: c.bg,
          contentPadding: EdgeInsets.zero,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(19), borderSide: BorderSide.none),
        ),
      ),
    );
  }
}

class _ChatTile extends StatelessWidget {
  const _ChatTile({required this.state, required this.chat});

  final AppState state;
  final Chat chat;

  @override
  Widget build(BuildContext context) {
    final c = context.fc;
    final active = state.activeChatId == chat.id;
    final unread = state.unreadOf(chat);
    final waiting = state.waitingOf(chat);
    final main = active ? Colors.white : c.text;
    final sub = active ? Colors.white : c.text2;
    final draft = state.draftOf(chat.id);
    // Right click: move the chat to a collection.
    return GestureDetector(
      onSecondaryTapDown: (d) => showAssignMenu(context, state, chat, d.globalPosition),
      child: Tap(
        onTap: () => state.openChat(chat.id),
        color: active ? c.accentStrong : Colors.transparent,
        hover: active ? c.accentStrong : c.hover,
        child: SizedBox(
          height: 66,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Row(
              children: [
                ChatAvatar(chat),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(chat.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600, color: main)),
                          ),
                          Text(chat.time, style: TextStyle(fontSize: 12, color: sub)),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Expanded(
                            child: Text(chat.typing.isNotEmpty
                                ? chat.typing
                                : draft.isNotEmpty ? '${context.s.chats.draft}: $draft' : state.lastOf(chat),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                    fontSize: 13.5,
                                    color: !active && draft.isNotEmpty ? c.danger
                                        : chat.typing.isNotEmpty && !active ? c.accentText : sub)),
                          ),
                          if (waiting) ...[const SizedBox(width: 6), WaitingDot(ring: active)],
                          if (unread > 0) ...[
                            const SizedBox(width: 6),
                            CountBadge(unread, muted: chat.muted, inverted: active),
                          ] else if (chat.pinned && !waiting) ...[
                            const SizedBox(width: 6),
                            Tooltip(
                              message: context.s.chats.pinned,
                              child: Transform.rotate(
                                angle: 0.75,
                                child: Icon(Icons.push_pin_outlined, size: 16, color: active ? Colors.white : c.text2),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Filter by chat type (several can be ticked) and hide muted chats.
class _TypeFilterButton extends StatelessWidget {
  const _TypeFilterButton({required this.state});

  final AppState state;

  @override
  Widget build(BuildContext context) {
    final c = context.fc;
    final active = state.typeFilterCount;
    final item = TextStyle(color: c.text, fontSize: 14);
    return MenuAnchor(
      style: MenuStyle(backgroundColor: WidgetStatePropertyAll(c.panel)),
      menuChildren: [
        for (final t in ChatType.values)
          CheckboxMenuButton(
            value: state.types.contains(t),
            closeOnActivate: false,
            onChanged: (_) => state.toggleType(t),
            child: Text(t.label, style: item),
          ),
        const Divider(height: 8),
        CheckboxMenuButton(
          value: state.hideMuted,
          closeOnActivate: false,
          onChanged: (v) => state.setHideMuted(v ?? false),
          child: Text(context.s.chats.hideMuted, style: item),
        ),
        if (active > 0)
          MenuItemButton(
            onPressed: state.clearTypeFilter,
            child: Text(context.s.chats.clearFilter, style: TextStyle(color: c.accentText, fontSize: 14)),
          ),
      ],
      builder: (context, controller, _) => Tooltip(
        message: context.s.chats.typeFilter,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () => controller.isOpen ? controller.close() : controller.open(),
          child: Container(
            height: 24,
            padding: const EdgeInsets.symmetric(horizontal: 6),
            decoration: BoxDecoration(
              color: active > 0 ? c.accentSoft : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.tune, size: 16, color: active > 0 ? c.accentText : c.text2),
                if (active > 0) ...[
                  const SizedBox(width: 3),
                  Text('$active', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: c.accentText)),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

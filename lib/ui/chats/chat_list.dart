import 'package:flutter/material.dart';

import '../../data/models.dart';
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
    final chats = state.visibleChats;
    final colLabel = state.collectionById(state.collection)?.label ?? kAllCollection.label;
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
            child: _SearchField(onChanged: state.setQuery),
          ),
          _CollectionTabs(state: state),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            // scaleDown keeps the three chips on one line if fonts or text
            // scaling make them wider than the column.
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Row(
                children: [
                  _FilterChip(
                    label: 'Javob kutmoqda',
                    count: state.waitingCount,
                    active: state.filter == ChatFilter.waiting,
                    activeColor: c.waitingStrong,
                    dot: state.filter != ChatFilter.waiting,
                    onTap: () => state.setFilter(ChatFilter.waiting),
                  ),
                  const SizedBox(width: 4),
                  _FilterChip(
                    label: 'O‘qilmagan',
                    count: state.unreadChatCount,
                    active: state.filter == ChatFilter.unread,
                    onTap: () => state.setFilter(ChatFilter.unread),
                  ),
                  const SizedBox(width: 4),
                  _FilterChip(
                    label: 'Hammasi',
                    active: state.filter == ChatFilter.all,
                    onTap: () => state.setFilter(ChatFilter.all),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
            child: Row(
              children: [
                Text(colLabel == 'Hammasi' ? 'Barcha chatlar' : colLabel, style: meta),
                const Spacer(),
                Text('${chats.length} ta chat', style: meta),
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
                              Text('Chatlar yuklanmoqda…', style: TextStyle(color: c.text2)),
                            ],
                          )
                        : Text('Bu filtrda chat yo‘q', style: TextStyle(color: c.text2)),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(6, 0, 6, 8),
                    itemCount: chats.length,
                    itemBuilder: (_, i) => _ChatTile(state: state, chat: chats[i]),
                  ),
          ),
        ],
      ),
    );
  }
}

/// Collections as Telegram-like folder tabs: click to filter, right click
/// to edit or delete, + to add.
class _CollectionTabs extends StatelessWidget {
  const _CollectionTabs({required this.state});

  final AppState state;

  @override
  Widget build(BuildContext context) {
    final c = context.fc;
    return Container(
      height: 38,
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: c.border))),
      // A Row, not a lazy ListView: all tabs exist, so any can be scrolled to.
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final col in [kAllCollection, ...state.collections])
              _CollectionTab(
                label: col.label,
                badge: state.badgeFor(col.id),
                active: state.collection == col.id,
                onTap: () => state.pickCollection(col.id),
                onMenu: col.id == kAllCollection.id ? null : (pos) => _menu(context, col, pos),
              ),
            Tooltip(
              message: 'To‘plam qo‘shish',
              child: IconButton(
                onPressed: () => showCollectionEditor(context, state),
                visualDensity: VisualDensity.compact,
                icon: Icon(Icons.add, size: 18, color: c.text2),
              ),
            ),
          ],
        ),
      ),
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
            value: 'edit', height: 38, child: Text('Tahrirlash', style: TextStyle(color: c.text, fontSize: 14))),
        PopupMenuItem(
            value: 'delete', height: 38, child: Text('O‘chirish', style: TextStyle(color: c.danger, fontSize: 14))),
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

class _CollectionTab extends StatelessWidget {
  const _CollectionTab(
      {required this.label, required this.badge, required this.active, required this.onTap, this.onMenu});

  final String label;
  final int badge;
  final bool active;
  final VoidCallback onTap;
  final void Function(Offset globalPosition)? onMenu;

  @override
  Widget build(BuildContext context) {
    final c = context.fc;
    final fg = active ? c.accentText : c.text2;
    final menu = onMenu;
    return InkWell(
      onTap: onTap,
      onSecondaryTapDown: menu == null ? null : (d) => menu(d.globalPosition),
      hoverColor: c.hover,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: active ? c.accent : Colors.transparent, width: 2.5)),
        ),
        alignment: Alignment.center,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label, style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: fg)),
            if (badge > 0) ...[
              const SizedBox(width: 5),
              Container(
                constraints: const BoxConstraints(minWidth: 18),
                height: 18,
                padding: const EdgeInsets.symmetric(horizontal: 5),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: active ? c.accentStrong : c.muted,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Text(
                  badge > 99 ? '99+' : '$badge',
                  style: const TextStyle(color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ],
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
          hintText: 'Qidiruv',
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

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.active,
    required this.onTap,
    this.count,
    this.activeColor,
    this.dot = false,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;
  final int? count;

  /// Defaults to the palette's accentStrong.
  final Color? activeColor;
  final bool dot;

  @override
  Widget build(BuildContext context) {
    final c = context.fc;
    final on = activeColor ?? c.accentStrong;
    final fg = active ? Colors.white : c.textSoft;
    return Tap(
      onTap: onTap,
      radius: 15,
      color: active ? on : c.panel,
      hover: active ? on : c.hover,
      border: Border.all(color: active ? on : c.chipBorder),
      child: Container(
        height: 30,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (dot) ...[const WaitingDot(), const SizedBox(width: 6)],
            Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: fg)),
            if (count != null) ...[
              const SizedBox(width: 4),
              Text('$count', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: fg)),
            ],
          ],
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
                            child: Text(state.lastOf(chat),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(fontSize: 13.5, color: sub)),
                          ),
                          if (waiting) ...[const SizedBox(width: 6), WaitingDot(ring: active)],
                          if (unread > 0) ...[
                            const SizedBox(width: 6),
                            CountBadge(unread, muted: chat.muted, inverted: active),
                          ] else if (chat.pinned && !waiting) ...[
                            const SizedBox(width: 6),
                            Tooltip(
                              message: 'Qadalgan',
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
          child: Text('Ovozsizlarni yashirish', style: item),
        ),
        if (active > 0)
          MenuItemButton(
            onPressed: state.clearTypeFilter,
            child: Text('Filtrni tozalash', style: TextStyle(color: c.accentText, fontSize: 14)),
          ),
      ],
      builder: (context, controller, _) => Tooltip(
        message: 'Chat turi bo‘yicha filtr',
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

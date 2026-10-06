import 'package:flutter/material.dart';

import '../../data/models.dart';
import '../../l10n/l10n.dart';
import '../../state/app_state.dart';
import '../../theme.dart';
import '../collections/collection_dialogs.dart';
import '../common.dart';

class InfoPanel extends StatelessWidget {
  const InfoPanel({super.key, required this.state, required this.onClose, this.width = 320});

  final AppState state;
  final VoidCallback onClose;

  /// 320 when docked or sliding over the chat; `double.infinity` in the
  /// narrow (one-column) layout.
  final double width;

  @override
  Widget build(BuildContext context) {
    final c = context.fc;
    final chat = state.activeChat;
    if (chat == null) return SizedBox(width: width.isFinite ? width : null);
    // Phone and bio/description are fetched once per chat when the panel shows.
    WidgetsBinding.instance.addPostFrameCallback((_) => state.loadDetails(chat.id));
    final t = context.s.chats;
    final accentLabel = TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: c.accentText);
    return Container(
      width: width,
      decoration: BoxDecoration(
        color: c.panel,
        border: width.isFinite ? Border(left: BorderSide(color: c.border)) : null,
      ),
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          Container(
            height: 56,
            padding: const EdgeInsets.only(left: 18, right: 8),
            decoration: BoxDecoration(border: Border(bottom: BorderSide(color: c.border))),
            child: Row(
              children: [
                Expanded(
                    child:
                        Text(t.info, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: c.text))),
                IconButton(
                    tooltip: t.closePanel, onPressed: onClose, icon: Icon(Icons.close, size: 18, color: c.icon)),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Center(child: ChatAvatar(chat, size: 88, showOnline: false)),
          const SizedBox(height: 10),
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                chat.name,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: c.text),
              ),
            ),
          ),
          Center(
            child: Text(chat.typing.isNotEmpty ? chat.typing : chat.status,
                style: TextStyle(fontSize: 13, color: chat.online || chat.typing.isNotEmpty ? c.accentText : c.text2)),
          ),
          const SizedBox(height: 10),
          // The chat's collection as one badge; click to move it.
          Center(child: _CollectionBadge(state: state, chat: chat)),
          const SizedBox(height: 12),
          if (chat.phone.isNotEmpty) _Row(icon: Icons.call_outlined, title: chat.phone, subtitle: t.phone),
          if (chat.about.isNotEmpty) _Row(icon: Icons.info_outline, title: chat.about, subtitle: t.about),
          const SizedBox(height: 8),
          Container(height: 8, color: c.bg),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 6),
            child: Text(t.fromThisChat, style: accentLabel),
          ),
          _Link(
            icon: Icons.checklist,
            label: t.tasks,
            count: state.tasks.openForChat(chat.id),
            onTap: () => state.showTasksForChat(chat.id),
          ),
          _Link(
            icon: Icons.calendar_today_outlined,
            label: t.meetings,
            count: state.events.upcomingForChat(chat.id).length,
            onTap: () => state.showEventsForChat(chat.id),
          ),
          _Link(
            icon: Icons.sticky_note_2_outlined,
            label: t.notes,
            count: state.notes.countForChat(chat.id),
            onTap: () => state.showNotesForChat(chat.id),
          ),
          _Link(
            icon: Icons.folder_outlined,
            label: t.files,
            count: state.savedCountFor(chat.id),
            onTap: () => state.showFilesForChat(chat.id),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.icon, required this.title, required this.subtitle});

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final c = context.fc;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: c.text2),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontSize: 14, color: c.text)),
                Text(subtitle, style: TextStyle(fontSize: 12, color: c.text2)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The collection the chat is in (icon and name in its color), or
/// "+ To‘plamga" when unsorted. Click opens the move menu.
class _CollectionBadge extends StatelessWidget {
  const _CollectionBadge({required this.state, required this.chat});

  final AppState state;
  final Chat chat;

  @override
  Widget build(BuildContext context) {
    final c = context.fc;
    final col = state.collectionById(state.collectionOf(chat));
    final tint = col == null ? c.text2 : c.collectionColor(col.colorKey);
    return Tooltip(
      message: context.s.chats.collection,
      child: Tap(
        onTap: null,
        radius: 14,
        color: col == null ? Colors.transparent : tint.withValues(alpha: 0.14),
        border: Border.all(color: col == null ? c.chipBorder : tint.withValues(alpha: 0.5)),
        child: GestureDetector(
          onTapDown: (d) => showAssignMenu(context, state, chat, d.globalPosition),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(10, 5, 12, 5),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(col?.icon ?? Icons.add, size: 15, color: tint),
                const SizedBox(width: 6),
                Text(
                  col?.label ?? context.s.notes.addToCollection,
                  style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: col == null ? c.textSoft : tint),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Link extends StatelessWidget {
  const _Link({required this.icon, required this.label, required this.onTap, this.count = 0});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  /// Shown before the chevron when > 0 (e.g. open tasks of this chat).
  final int count;

  @override
  Widget build(BuildContext context) {
    final c = context.fc;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Tap(
        onTap: onTap,
        radius: 8,
        child: SizedBox(
          height: 44,
          child: Row(
            children: [
              const SizedBox(width: 10),
              Icon(icon, size: 20, color: c.text2),
              const SizedBox(width: 12),
              Expanded(child: Text(label, style: TextStyle(fontSize: 14, color: c.text))),
              if (count > 0) Text('$count', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: c.accentText)),
              Icon(Icons.chevron_right, size: 18, color: c.text2),
              const SizedBox(width: 8),
            ],
          ),
        ),
      ),
    );
  }
}

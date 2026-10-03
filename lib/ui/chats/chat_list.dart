import 'package:flutter/material.dart';

import '../../data/mock.dart';
import '../../data/models.dart';
import '../../state/app_state.dart';
import '../../theme.dart';
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
    final colLabel = kCollections.firstWhere((col) => col.id == state.collection).label;
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
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
            child: _SearchField(onChanged: state.setQuery),
          ),
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
                              SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2.4, color: c.accent)),
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
    return Tap(
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
                              maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 13.5, color: sub)),
                        ),
                        if (waiting) ...[const SizedBox(width: 6), WaitingDot(ring: active)],
                        if (unread > 0) ...[
                          const SizedBox(width: 6),
                          CountBadge(unread, muted: chat.muted, inverted: active),
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
    );
  }
}

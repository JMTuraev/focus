import 'package:flutter/material.dart';

import '../../data/mock.dart';
import '../../data/models.dart';
import '../../state/app_state.dart';
import '../../theme.dart';
import '../common.dart';

class ChatList extends StatelessWidget {
  const ChatList({super.key, required this.state});

  final AppState state;

  @override
  Widget build(BuildContext context) {
    final chats = state.visibleChats;
    final colLabel = kCollections.firstWhere((c) => c.id == state.collection).label;
    return Container(
      width: 340,
      decoration: const BoxDecoration(
        color: FC.panel,
        border: Border(right: BorderSide(color: FC.border)),
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
            // scaling make them wider than the 340 px column.
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Row(
                children: [
                  _FilterChip(
                    label: 'Javob kutmoqda',
                    count: state.waitingCount,
                    active: state.filter == ChatFilter.waiting,
                    activeColor: FC.waitingStrong,
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
                Text(colLabel == 'Hammasi' ? 'Barcha chatlar' : colLabel, style: _meta),
                const Spacer(),
                Text('${chats.length} ta chat', style: _meta),
              ],
            ),
          ),
          Expanded(
            child: chats.isEmpty
                ? const Center(child: Text('Bu filtrda chat yo‘q', style: TextStyle(color: FC.text2)))
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

  static const _meta = TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: FC.text2);
}

class _SearchField extends StatelessWidget {
  const _SearchField({required this.onChanged});

  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 38,
      child: TextField(
        onChanged: onChanged,
        style: const TextStyle(fontSize: 14),
        decoration: InputDecoration(
          hintText: 'Qidiruv',
          hintStyle: const TextStyle(color: FC.text2),
          prefixIcon: const Icon(Icons.search, size: 19, color: FC.text2),
          filled: true,
          fillColor: FC.bg,
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
    this.activeColor = FC.accentStrong,
    this.dot = false,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;
  final int? count;
  final Color activeColor;
  final bool dot;

  @override
  Widget build(BuildContext context) {
    final fg = active ? Colors.white : const Color(0xFF3A4048);
    return Tap(
      onTap: onTap,
      radius: 15,
      color: active ? activeColor : Colors.white,
      hover: active ? activeColor : FC.hover,
      border: Border.all(color: active ? activeColor : const Color(0xFFDDE1E6)),
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
    final active = state.activeChatId == chat.id;
    final unread = state.unreadOf(chat);
    final waiting = state.waitingOf(chat);
    final main = active ? Colors.white : FC.text;
    final sub = active ? Colors.white : FC.text2;
    return Tap(
      onTap: () => state.openChat(chat.id),
      color: active ? FC.accentStrong : Colors.transparent,
      hover: active ? FC.accentStrong : FC.hover,
      child: SizedBox(
        height: 66,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Row(
            children: [
              Avatar(initials: chat.initials, color: chat.color, online: chat.online),
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

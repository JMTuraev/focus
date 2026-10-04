import 'package:flutter/material.dart';

import '../state/app_state.dart';
import '../theme.dart';
import 'common.dart';

/// The chat and message a task or event came from, with "Chatni ochish".
class ChatSourceBox extends StatelessWidget {
  const ChatSourceBox({
    super.key,
    required this.state,
    required this.chatId,
    required this.onOpenChat,
    this.chatTitle,
    this.messageText,
  });

  final AppState state;
  final String chatId;
  final String? chatTitle;
  final String? messageText;
  final VoidCallback onOpenChat;

  @override
  Widget build(BuildContext context) {
    final c = context.fc;
    final chat = state.source.chatById(chatId);
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: c.bg, borderRadius: BorderRadius.circular(10)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (chat != null)
                ChatAvatar(chat, size: 26, showOnline: false)
              else
                Icon(Icons.chat_bubble_outline, size: 20, color: c.icon),
              const SizedBox(width: 8),
              Expanded(
                child: Text(chat?.name ?? chatTitle ?? 'Chat',
                    maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: c.text, fontWeight: FontWeight.w600)),
              ),
              if (chat != null)
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    onOpenChat();
                  },
                  style: TextButton.styleFrom(foregroundColor: c.accentText),
                  child: const Text('Chatni ochish'),
                ),
            ],
          ),
          if ((messageText ?? '').isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(messageText!,
                  maxLines: 4, overflow: TextOverflow.ellipsis, style: TextStyle(color: c.textSoft, fontSize: 13.5, height: 1.35)),
            ),
        ],
      ),
    );
  }
}

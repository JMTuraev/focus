import 'dart:async';

import 'package:flutter/foundation.dart';

import '../data/chat_source.dart';
import '../data/models.dart';
import '../l10n/l10n.dart';
import '../state/settings.dart';
import 'notifier.dart';

/// Windows toasts for new Telegram messages, like Telegram itself shows:
/// one toast per chat (a newer message replaces the earlier toast), skipped
/// for muted chats, for channels unless [Settings.notifyChannels] is on, and
/// while the user is looking at that very chat in a focused window.
/// Clicking a toast opens the chat (payload `chat:ID`). Nothing is sent to
/// Telegram.
class MessageNotifier {
  MessageNotifier({
    required this.notifier,
    required this.source,
    required this.settings,
    required this.windowActive,
    required this.activeChatId,
  });

  final Notifier notifier;
  final ChatSource source;
  final Settings settings;

  /// True while the Focus window is focused.
  final bool Function() windowActive;

  /// The chat open in Focus, if any.
  final String? Function() activeChatId;

  /// Notification ids live above the reminder ranges (1xxxxxxxx, 2xxxxxxxx).
  static const base = 300000000;

  StreamSubscription<IncomingMessage>? _sub;

  void start() => _sub ??= source.incoming.listen(_onMessage);

  void dispose() {
    _sub?.cancel();
    _sub = null;
  }

  /// Whether [m] gets a toast under the current settings and window state.
  @visibleForTesting
  bool wanted(IncomingMessage m) {
    if (!settings.messageNotifications) return false;
    if (m.muted) return false;
    if (m.kind == ChatKind.channel && !settings.notifyChannels) return false;
    if (m.kind == ChatKind.saved) return false;
    if (windowActive() && activeChatId() == m.chatId) return false;
    return true;
  }

  static int idFor(String chatId) => base + chatId.hashCode.abs() % 100000000;

  Future<void> _onMessage(IncomingMessage m) async {
    if (!wanted(m)) return;
    final s = S.current.app;
    final String body;
    if (!settings.notifyShowText) {
      body = s.newMessageHidden;
    } else if (m.sender != null && m.sender!.isNotEmpty) {
      body = '${m.sender}: ${m.preview}';
    } else {
      body = m.preview;
    }
    try {
      await notifier.show(id: idFor(m.chatId), title: m.chatTitle, body: body, payload: 'chat:${m.chatId}');
    } catch (e) {
      debugPrint('message toast: $e');
    }
  }
}

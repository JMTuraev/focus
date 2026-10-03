import 'package:flutter/foundation.dart';

import 'local_store.dart';
import 'models.dart';

/// Where chats and messages come from: mock data or TDLib.
/// Notifies listeners whenever chats or loaded messages change.
abstract class ChatSource extends ChangeNotifier {
  /// Chats in Telegram order (pinned first).
  List<Chat> get chats;

  /// True while the first page of chats is loading.
  bool get loading;

  Chat? chatById(String id);

  /// Loaded messages, oldest first.
  List<Message> messagesOf(String chatId);

  /// True while older messages are being fetched for [chatId].
  bool loadingHistory(String chatId);

  /// The user opened [chatId]: load its history (TDLib: openChat).
  /// Never marks anything as read.
  Future<void> open(String chatId);

  /// The user left [chatId] (TDLib: closeChat).
  void close(String chatId);

  /// Fetch older messages for [chatId].
  Future<void> loadOlder(String chatId);

  /// Load phone number and bio/description for the info panel.
  Future<void> loadDetails(String chatId);

  Future<void> send(String chatId, String text);
}

/// What the app needs after login: chats plus Fokus-only local data.
class ChatSession {
  ChatSession({required this.source, required this.store, this.initialChatId});

  final ChatSource source;
  final LocalStore store;

  /// Chat selected at start (mock data opens the first scripted chat).
  final String? initialChatId;

  Future<void> close() async {
    await store.flush();
    source.dispose();
  }
}

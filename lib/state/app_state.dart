import 'package:flutter/foundation.dart';

import '../data/chat_source.dart';
import '../data/local_store.dart';
import '../data/models.dart';

enum Module { chats, collections, tasks, calendar, notes, files, stats }

enum ChatFilter { waiting, unread, all }

/// UI state on top of a [ChatSource] (mock or TDLib) and the [LocalStore]
/// with Fokus-only data (collections, locally seen messages).
class AppState extends ChangeNotifier {
  AppState({required this.source, required this.store, String? initialChatId}) : activeChatId = initialChatId {
    source.addListener(_onSource);
  }

  final ChatSource source;
  final LocalStore store;

  Module module = Module.chats;
  String collection = 'all';
  ChatFilter filter = ChatFilter.all;
  String? activeChatId;
  String query = '';

  /// Docked info column (wide layout).
  bool infoOpen = true;

  /// Info panel shown over the chat (medium and narrow layouts).
  bool infoOverlayOpen = false;

  /// Narrow layout: true while a chat is shown instead of the chat list.
  bool narrowChatOpen = false;
  String? selectedMessageId;

  void _onSource() {
    // Messages arriving in the chat the user is looking at count as seen.
    final c = activeChat;
    if (c != null) store.setSeen(c.id, c.unread);
    notifyListeners();
  }

  @override
  void dispose() {
    source.removeListener(_onSource);
    final id = activeChatId;
    if (id != null) source.close(id);
    store.flush();
    super.dispose();
  }

  // ---- navigation ----
  void openModule(Module m) {
    module = m;
    notifyListeners();
  }

  void pickCollection(String id) {
    collection = id;
    module = Module.chats;
    narrowChatOpen = false;
    infoOverlayOpen = false;
    notifyListeners();
  }

  void setFilter(ChatFilter f) {
    filter = f;
    notifyListeners();
  }

  void setQuery(String q) {
    query = q;
    notifyListeners();
  }

  void toggleInfo() {
    infoOpen = !infoOpen;
    notifyListeners();
  }

  void toggleInfoOverlay() {
    infoOverlayOpen = !infoOverlayOpen;
    notifyListeners();
  }

  /// Narrow layout: back from the chat to the chat list.
  void closeChat() {
    narrowChatOpen = false;
    infoOverlayOpen = false;
    notifyListeners();
  }

  // ---- chats ----
  String collectionOf(Chat c) => store.collectionOf(c.id) ?? c.collection;

  /// Unread messages not yet seen in Fokus. Telegram's own counter is left
  /// untouched (no viewMessages); if it drops because the chat was read on
  /// another device, the local mark follows it down.
  int unreadOf(Chat c) {
    final seen = store.seenOf(c.id);
    if (c.unread < seen) {
      store.setSeen(c.id, c.unread);
      return 0;
    }
    return c.unread - seen;
  }

  bool waitingOf(Chat c) => c.waiting;

  Chat? get activeChat {
    final id = activeChatId;
    return id == null ? null : source.chatById(id);
  }

  bool get loadingChats => source.loading;

  List<Chat> get chatsInCollection =>
      source.chats.where((c) => collection == 'all' || collectionOf(c) == collection).toList();

  List<Chat> get visibleChats {
    final q = query.trim().toLowerCase();
    return chatsInCollection.where((c) {
      if (filter == ChatFilter.waiting && !waitingOf(c)) return false;
      if (filter == ChatFilter.unread && unreadOf(c) == 0) return false;
      if (q.isNotEmpty && !c.name.toLowerCase().contains(q)) return false;
      return true;
    }).toList();
  }

  int get waitingCount => chatsInCollection.where(waitingOf).length;
  int get unreadChatCount => chatsInCollection.where((c) => unreadOf(c) > 0).length;

  int badgeFor(String collectionId) => source.chats
      .where((c) =>
          (collectionId == 'all' || collectionOf(c) == collectionId) &&
          unreadOf(c) > 0 &&
          !c.muted)
      .length;

  String lastOf(Chat c) => c.last;

  void openChat(String id) {
    final previous = activeChatId;
    if (previous != null && previous != id) source.close(previous);
    activeChatId = id;
    selectedMessageId = null;
    narrowChatOpen = true;
    // Local mode: only the badge inside Fokus is cleared.
    // Nothing is reported to Telegram (no viewMessages call).
    final c = source.chatById(id);
    if (c != null) store.setSeen(id, c.unread);
    source.open(id);
    notifyListeners();
  }

  void moveToCollection(String chatId, String collectionId) {
    store.setCollection(chatId, collectionId);
    notifyListeners();
  }

  void loadDetails(String chatId) => source.loadDetails(chatId);

  // ---- messages ----
  List<Message> messagesOf(String chatId) => source.messagesOf(chatId);

  bool get loadingHistory {
    final id = activeChatId;
    return id != null && source.loadingHistory(id);
  }

  void loadOlder() {
    final id = activeChatId;
    if (id != null) source.loadOlder(id);
  }

  void selectMessage(String id) {
    selectedMessageId = selectedMessageId == id ? null : id;
    notifyListeners();
  }

  /// Selected message, or the latest incoming one.
  Message? get targetMessage {
    final id = activeChatId;
    if (id == null) return null;
    final list = messagesOf(id).where((m) => !m.service).toList();
    if (selectedMessageId != null) {
      for (final m in list) {
        if (m.id == selectedMessageId) return m;
      }
    }
    for (final m in list.reversed) {
      if (!m.out) return m;
    }
    return list.isEmpty ? null : list.last;
  }

  Future<void> send(String text) async {
    final id = activeChatId;
    if (id == null || text.trim().isEmpty) return;
    await source.send(id, text);
  }
}

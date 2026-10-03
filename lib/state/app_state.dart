import 'package:flutter/foundation.dart';

import '../data/mock.dart';
import '../data/models.dart';

enum Module { chats, collections, tasks, calendar, notes, files, stats }

enum ChatFilter { waiting, unread, all }

/// UI state for phase 0 (mock data). In phase 1 the chat/message
/// getters are backed by TDLib, the rest by the local database.
class AppState extends ChangeNotifier {
  Module module = Module.chats;
  String collection = 'all';
  ChatFilter filter = ChatFilter.all;
  String activeChatId = 'dilshod';
  String query = '';
  /// Docked info column (wide layout).
  bool infoOpen = true;

  /// Info panel shown over the chat (medium and narrow layouts).
  bool infoOverlayOpen = false;

  /// Narrow layout: true while a chat is shown instead of the chat list.
  bool narrowChatOpen = false;
  String? selectedMessageId;

  final Map<String, List<Message>> _sent = {};
  final Set<String> _read = {};
  final Set<String> _replied = {};
  final Map<String, String> _collectionOverride = {};

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
  String collectionOf(Chat c) => _collectionOverride[c.id] ?? c.collection;
  int unreadOf(Chat c) => _read.contains(c.id) ? 0 : c.unread;
  bool waitingOf(Chat c) => c.waiting && !_replied.contains(c.id);

  Chat get activeChat => kChats.firstWhere((c) => c.id == activeChatId);

  List<Chat> get chatsInCollection => kChats
      .where((c) => collection == 'all' || collectionOf(c) == collection)
      .toList();

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

  int badgeFor(String collectionId) => kChats
      .where((c) =>
          (collectionId == 'all' || collectionOf(c) == collectionId) &&
          unreadOf(c) > 0 &&
          !c.muted)
      .length;

  String lastOf(Chat c) {
    final s = _sent[c.id];
    return (s != null && s.isNotEmpty) ? 'Siz: ${s.last.text}' : c.last;
  }

  void openChat(String id) {
    activeChatId = id;
    selectedMessageId = null;
    narrowChatOpen = true;
    // Local mode: this only clears the badge inside Fokus.
    // Nothing is reported to Telegram (no viewMessages call).
    _read.add(id);
    notifyListeners();
  }

  void moveToCollection(String chatId, String collectionId) {
    _collectionOverride[chatId] = collectionId;
    notifyListeners();
  }

  // ---- messages ----
  List<Message> messagesOf(String chatId) {
    final chat = kChats.firstWhere((c) => c.id == chatId);
    final base = kMessages[chatId] ?? fallbackMessages(chat);
    return [...base, ...?_sent[chatId]];
  }

  void selectMessage(String id) {
    selectedMessageId = selectedMessageId == id ? null : id;
    notifyListeners();
  }

  /// Selected message, or the latest incoming one.
  Message? get targetMessage {
    final list = messagesOf(activeChatId);
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

  void send(String text) {
    final t = text.trim();
    if (t.isEmpty) return;
    final now = DateTime.now();
    final time = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    (_sent[activeChatId] ??= []).add(
      Message(id: '$activeChatId-s${now.microsecondsSinceEpoch}', text: t, time: time, out: true),
    );
    _replied.add(activeChatId);
    notifyListeners();
  }
}

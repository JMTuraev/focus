import 'package:flutter/foundation.dart';

import '../calendar/event_store.dart';
import '../data/chat_source.dart';
import '../data/local_store.dart';
import '../data/models.dart';
import '../db/database.dart';
import '../notes/note_store.dart';
import '../tasks/task_store.dart';

enum Module { chats, collections, tasks, calendar, notes, files, stats }

enum ChatFilter { waiting, unread, all }

/// Chat types for the type filter and the "Saralanmagan" tabs.
enum ChatType {
  private('Shaxsiy'),
  group('Guruhlar'),
  channel('Kanallar'),
  bot('Botlar');

  const ChatType(this.label);
  final String label;

  static ChatType of(Chat c) => switch (c.kind) {
        ChatKind.private || ChatKind.saved => ChatType.private,
        ChatKind.group => ChatType.group,
        ChatKind.channel => ChatType.channel,
        ChatKind.bot => ChatType.bot,
      };
}

/// UI state on top of a [ChatSource] (mock or TDLib) and the [LocalStore]
/// with Focus-only data (collections, locally seen messages).
class AppState extends ChangeNotifier {
  AppState({
    required this.source,
    required this.store,
    TaskStore? tasks,
    EventStore? events,
    NoteStore? notes,
    String? initialChatId,
  })  : tasks = tasks ?? TaskStore(AppDatabase.memory()),
        events = events ?? EventStore(AppDatabase.memory()),
        notes = notes ?? NoteStore(AppDatabase.memory()),
        activeChatId = initialChatId {
    source.addListener(_onSource);
  }

  final ChatSource source;
  final LocalStore store;

  /// Tasks (own listenable: the board rebuilds without the chat list).
  final TaskStore tasks;

  /// Calendar events (own listenable, like [tasks]).
  final EventStore events;

  /// Notes (own listenable, like [tasks]).
  final NoteStore notes;

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

  /// Tasks board shows only the tasks of this chat.
  String? taskChatFilter;

  /// Calendar shows only the events of this chat.
  String? eventChatFilter;

  /// Notes screen shows only the notes of this chat.
  String? noteChatFilter;

  /// A day inside the week (or the day) the calendar shows.
  DateTime calendarFocus = EventStore.day(DateTime.now());
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
    tasks.dispose();
    events.dispose();
    notes.dispose();
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
  // ---- collections ----
  List<Collection> get collections => store.collections;

  /// [kAllCollection] for 'all'; null if the id no longer exists.
  Collection? collectionById(String id) => id == kAllCollection.id ? kAllCollection : store.collectionById(id);

  /// The chat's collection id, or '' when it is unsorted (or its collection
  /// was deleted).
  String collectionOf(Chat c) {
    final id = store.collectionOf(c.id) ?? c.collection;
    return id.isNotEmpty && store.collectionById(id) != null ? id : '';
  }

  /// Chats that are in no collection yet, optionally of one [type].
  List<Chat> unsorted({ChatType? type}) =>
      source.chats.where((c) => collectionOf(c).isEmpty && (type == null || ChatType.of(c) == type)).toList();

  int countIn(String collectionId) => source.chats.where((c) => collectionOf(c) == collectionId).length;

  List<Chat> chatsIn(String collectionId) => source.chats.where((c) => collectionOf(c) == collectionId).toList();

  Collection createCollection(String label, String iconKey) {
    final c = store.addCollection(label, iconKey);
    notifyListeners();
    return c;
  }

  void updateCollection(String id, {required String label, required String iconKey}) {
    store.updateCollection(id, label: label, iconKey: iconKey);
    notifyListeners();
  }

  void deleteCollection(String id) {
    store.deleteCollection(id);
    if (collection == id) collection = kAllCollection.id;
    notifyListeners();
  }

  void moveCollection(int from, int to) {
    store.moveCollection(from, to);
    notifyListeners();
  }

  /// Puts every chat in [chats] into [collectionId] ('' = unsorted).
  void assignAll(Iterable<Chat> chats, String collectionId) {
    for (final c in chats) {
      store.setCollection(c.id, collectionId);
    }
    notifyListeners();
  }

  // ---- type filter ----
  /// Empty = every type.
  final Set<ChatType> types = {};
  bool hideMuted = false;

  int get typeFilterCount => types.length + (hideMuted ? 1 : 0);

  void toggleType(ChatType t) {
    if (!types.remove(t)) types.add(t);
    notifyListeners();
  }

  void setHideMuted(bool v) {
    hideMuted = v;
    notifyListeners();
  }

  void clearTypeFilter() {
    types.clear();
    hideMuted = false;
    notifyListeners();
  }

  bool _passesType(Chat c) => (types.isEmpty || types.contains(ChatType.of(c))) && !(hideMuted && c.muted);

  /// Unread messages not yet seen in Focus. Telegram's own counter is left
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

  /// Chats of the selected collection that pass the type filter; the
  /// waiting/unread chips count and filter within these.
  List<Chat> get chatsInCollection => source.chats
      .where((c) => (collection == kAllCollection.id || collectionOf(c) == collection) && _passesType(c))
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

  int badgeFor(String collectionId) => source.chats
      .where((c) => (collectionId == 'all' || collectionOf(c) == collectionId) && unreadOf(c) > 0 && !c.muted)
      .length;

  String lastOf(Chat c) => c.last;

  void openChat(String id) {
    final previous = activeChatId;
    if (previous != null && previous != id) source.close(previous);
    activeChatId = id;
    selectedMessageId = null;
    narrowChatOpen = true;
    // Local mode: only the badge inside Focus is cleared.
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

  void download(int fileId, {int priority = 1}) => source.download(fileId, priority: priority);

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

  /// Sends files to the open chat (see [ChatSource.sendFiles]).
  Future<void> sendFiles(List<OutgoingFile> files, {String caption = '', bool compressImages = true}) async {
    final id = activeChatId;
    if (id == null || files.isEmpty) return;
    await source.sendFiles(id, files, caption: caption, compressImages: compressImages);
  }

  // ---- tasks ----
  /// Shows the board with only the tasks of [chatId].
  void showTasksForChat(String chatId) {
    taskChatFilter = chatId;
    openModule(Module.tasks);
  }

  void clearTaskChatFilter() {
    taskChatFilter = null;
    notifyListeners();
  }

  /// Opens the chat a task came from.
  void openTaskChat(Task t) {
    final id = t.chatId;
    if (id == null) return;
    module = Module.chats;
    openChat(id);
  }

  /// Creates a task from [m] in the open chat. The title is the first line
  /// of the text (or the file / media name), the full text is kept too.
  Future<int?> taskFromMessage(Message m) async {
    final chat = activeChat;
    if (chat == null) return null;
    var title = m.text.trim().split('\n').first.trim();
    if (title.isEmpty) title = m.fileName ?? m.mediaLabel ?? 'Xabar';
    if (title.length > 140) title = '${title.substring(0, 139)}…';
    return tasks.add(
      title: title,
      chatId: chat.id,
      chatTitle: chat.name,
      messageId: m.id,
      messageText: m.text.isEmpty ? null : m.text,
    );
  }

  // ---- calendar ----
  void setCalendarFocus(DateTime d) {
    calendarFocus = EventStore.day(d);
    notifyListeners();
  }

  /// Opens the calendar on the week of [d].
  void showCalendarAt(DateTime d) {
    calendarFocus = EventStore.day(d);
    openModule(Module.calendar);
  }

  /// Calendar with only the events of [chatId], at its next event.
  void showEventsForChat(String chatId) {
    eventChatFilter = chatId;
    final next = events.upcomingForChat(chatId);
    showCalendarAt(next.isEmpty ? DateTime.now() : next.first.start);
  }

  void clearEventChatFilter() {
    eventChatFilter = null;
    notifyListeners();
  }

  void openEventChat(Event e) {
    final id = e.chatId;
    if (id == null) return;
    module = Module.chats;
    openChat(id);
  }

  /// Adds the meeting found in [m] (one hour, reminder 30 minutes before).
  Future<int?> eventFromMeeting(Message m) async {
    final chat = activeChat;
    final at = m.meetingAt;
    if (chat == null || at == null) return null;
    return events.add(
      title: 'Uchrashuv: ${chat.name}',
      start: at,
      end: at.add(const Duration(hours: 1)),
      note: m.text,
      remindBefore: 30,
      chatId: chat.id,
      chatTitle: chat.name,
      messageId: m.id,
      messageText: m.text.isEmpty ? null : m.text,
    );
  }

  /// After a backup restore: re-read tasks, events, notes, collections.
  Future<void> reloadLocalData() async {
    await Future.wait([tasks.reload(), events.reload(), notes.reload(), store.reload()]);
    notifyListeners();
  }

  // ---- notes ----
  void showNotesForChat(String chatId) {
    noteChatFilter = chatId;
    openModule(Module.notes);
  }

  void clearNoteChatFilter() {
    noteChatFilter = null;
    notifyListeners();
  }

  void openNoteChat(Note n) {
    final id = n.chatId;
    if (id == null) return;
    module = Module.chats;
    openChat(id);
  }

  /// Saves [m] from the open chat as a note (text, or the file / media name).
  Future<int?> noteFromMessage(Message m) async {
    final chat = activeChat;
    if (chat == null) return null;
    final body = m.text.trim().isNotEmpty ? m.text : (m.fileName ?? m.mediaLabel ?? '');
    return notes.add(body: body, chatId: chat.id, chatTitle: chat.name, messageId: m.id);
  }
}

import 'models.dart';
import 'chat_source.dart';
import 'mock.dart';

/// Phase 0 mock data behind the [ChatSource] interface.
class MockChatSource extends ChatSource {
  MockChatSource() : _chats = List.of(kChats);

  final List<Chat> _chats;
  final Map<String, List<Message>> _sent = {};

  @override
  List<Chat> get chats => _chats;

  @override
  bool get loading => false;

  @override
  Chat? chatById(String id) {
    for (final c in _chats) {
      if (c.id == id) return c;
    }
    return null;
  }

  @override
  List<Message> messagesOf(String chatId) {
    final chat = chatById(chatId);
    if (chat == null) return const [];
    final base = kMessages[chatId] ?? fallbackMessages(kChats.firstWhere((c) => c.id == chatId));
    return [...base, ...?_sent[chatId]];
  }

  @override
  bool loadingHistory(String chatId) => false;

  @override
  Future<void> open(String chatId) async {}

  @override
  void close(String chatId) {}

  @override
  Future<void> loadOlder(String chatId) async {}

  @override
  Future<void> loadDetails(String chatId) async {}

  @override
  Future<void> send(String chatId, String text) async {
    final t = text.trim();
    if (t.isEmpty) return;
    final now = DateTime.now();
    final time = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    (_sent[chatId] ??= []).add(Message(id: '$chatId-s${now.microsecondsSinceEpoch}', text: t, time: time, out: true));
    final i = _chats.indexWhere((c) => c.id == chatId);
    if (i >= 0) _chats[i] = _chats[i].copyWith(last: 'Siz: $t', time: time, waiting: false);
    notifyListeners();
  }
}

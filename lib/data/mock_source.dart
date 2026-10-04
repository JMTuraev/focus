import 'models.dart';
import 'chat_source.dart';
import 'format.dart';
import '../l10n/l10n.dart';
import 'meeting_parser.dart';
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
    // Meetings are found by the same parser as for Telegram messages;
    // mock messages are "today", so relative days count from now.
    final now = DateTime.now();
    return [
      for (final m in [...base, ...?_sent[chatId]])
        if (m.out) m else _withMeeting(m, now),
    ];
  }

  static Message _withMeeting(Message m, DateTime now) {
    final meet = MeetingParser.parse(m.text, now);
    return m.withMeeting(meet?.label, meet?.at);
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
  void download(int fileId, {int priority = 1}) {}

  @override
  Future<void> send(String chatId, String text) async {
    final t = text.trim();
    if (t.isEmpty) return;
    final now = DateTime.now();
    final time = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    (_sent[chatId] ??= []).add(Message(id: '$chatId-s${now.microsecondsSinceEpoch}', text: t, time: time, out: true));
    final i = _chats.indexWhere((c) => c.id == chatId);
    if (i >= 0) _chats[i] = _chats[i].copyWith(last: '${S.current.chats.youPrefix}$t', time: time, waiting: false);
    notifyListeners();
  }

  @override
  Future<void> sendFiles(String chatId, List<OutgoingFile> files, {String caption = '', bool compressImages = true}) async {
    if (files.isEmpty) return;
    final now = DateTime.now();
    final time = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    for (var i = 0; i < files.length; i++) {
      final f = files[i];
      (_sent[chatId] ??= []).add(Message(
        id: '$chatId-f${now.microsecondsSinceEpoch}-$i',
        text: i == 0 ? caption.trim() : '',
        time: time,
        out: true,
        fileName: f.name,
        fileMeta: '${Fmt.size(f.size)} · ${f.extension.isEmpty ? S.current.common.file : f.extension.toUpperCase()}',
        file: FileInfo(fileId: -1, size: f.size, path: f.path, progress: 1),
      ));
    }
    final idx = _chats.indexWhere((c) => c.id == chatId);
    if (idx >= 0) _chats[idx] = _chats[idx].copyWith(last: '${S.current.chats.youPrefix}${files.last.name}', time: time, waiting: false);
    notifyListeners();
  }
}

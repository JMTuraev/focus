import 'dart:async';

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

  /// Edited texts and deleted messages by "chatId:messageId".
  final Map<String, String> _edits = {};
  final Set<String> _deleted = {};
  final _incoming = StreamController<IncomingMessage>.broadcast();

  @override
  Stream<IncomingMessage> get incoming => _incoming.stream;

  /// Tests and demos: pretend [text] just arrived in [chatId].
  void receive(String chatId, String text, {String? sender}) {
    final chat = chatById(chatId);
    if (chat == null) return;
    final kind = chat.kind;
    _incoming.add(IncomingMessage(
      chatId: chatId,
      chatTitle: chat.name,
      kind: kind,
      muted: chat.muted,
      preview: text,
      sender: kind == ChatKind.group ? sender : null,
    ));
  }

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
      for (final raw in [...base, ...?_sent[chatId]])
        if (!_deleted.contains('$chatId:${raw.id}'))
          if (_edits['$chatId:${raw.id}'] case final text?)
            raw.withText(text)
          else if (raw.out)
            raw
          else
            _withMeeting(raw, now),
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
  Future<FoundFile?> getFound(String chatId, String messageId) async {
    final chat = chatById(chatId);
    if (chat == null) return null;
    for (final m in [...(kMessages[chatId] ?? const <Message>[]), ...(_sent[chatId] ?? const <Message>[])]) {
      if (m.id == messageId) return FoundFile(chatId: chatId, chatTitle: chat.name, message: m);
    }
    return null;
  }

  @override
  Future<MessageRights> rightsOf(String chatId, String messageId) async {
    final chat = chatById(chatId);
    final m = messagesOf(chatId).where((x) => x.id == messageId).firstOrNull;
    if (chat == null || m == null || m.service) return const MessageRights();
    final plainText = m.fileName == null && m.info == null && m.media == null;
    return MessageRights(
      canEdit: m.out && plainText,
      canDeleteForMe: true,
      canDeleteForAll: m.out || chat.kind == ChatKind.private,
    );
  }

  @override
  Future<void> editText(String chatId, String messageId, String text) async {
    _edits['$chatId:$messageId'] = text.trim();
    notifyListeners();
  }

  @override
  Future<void> deleteMessages(String chatId, List<String> messageIds, {required bool forAll}) async {
    _deleted.addAll(messageIds.map((id) => '$chatId:$id'));
    notifyListeners();
  }

  @override
  Future<void> setPinned(String chatId, bool pinned) async {
    final i = _chats.indexWhere((c) => c.id == chatId);
    if (i < 0) return;
    final chat = _chats.removeAt(i).copyWith(pinned: pinned);
    // Pinned chats stay first, in the order they were pinned (newest on top).
    _chats.insert(pinned ? 0 : _chats.indexWhere((c) => !c.pinned).clamp(0, _chats.length), chat);
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

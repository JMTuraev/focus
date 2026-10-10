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
  final Map<String, ReplyInfo> _replies = {};
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
    (_sent[chatId] ??= []).add(Message(id: '$chatId-s${now.microsecondsSinceEpoch}', text: t, time: time, out: true, reply: _replies.remove(chatId)));
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

  ReplyInfo _reply(String chatId, String messageId) {
    final m = messagesOf(chatId).firstWhere((m) => m.id == messageId);
    return ReplyInfo(chatId: chatId, messageId: messageId,
      author: m.from ?? chatById(chatId)!.name,
      text: m.text.isNotEmpty ? m.text : m.fileName ?? m.mediaLabel ?? S.current.chats.message);
  }

  @override
  Future<void> sendReply(String chatId, String text, String messageId) async {
    _replies[chatId] = _reply(chatId, messageId);
    await send(chatId, text);
  }

  @override
  Future<void> sendFilesReply(String chatId, List<OutgoingFile> files, String messageId,
      {String caption = '', bool compressImages = true}) async {
    _replies[chatId] = _reply(chatId, messageId);
    await sendFiles(chatId, files, caption: caption, compressImages: compressImages);
  }

  @override
  Future<void> forwardMessages(String chatId, String fromChatId, List<String> messageIds) async {
    if (chatById(chatId)?.canSend != true) throw StateError('Read-only destination');
    final now = DateTime.now();
    for (final id in messageIds) {
      final m = messagesOf(fromChatId).firstWhere((m) => m.id == id);
      (_sent[chatId] ??= []).add(Message(
        id: '$chatId-forward-${now.microsecondsSinceEpoch}-$id', text: m.text, time: Fmt.hm(now), date: now, out: true,
        fileName: m.fileName, fileMeta: m.fileMeta, file: m.file, info: m.info, media: m.media, mediaLabel: m.mediaLabel,
        entities: m.entities, reply: m.reply, forwardedFrom: m.forwardedFrom ?? m.from ?? chatById(fromChatId)!.name,
      ));
    }
    notifyListeners();
  }

  @override
  Future<MessageSearchPage> searchMessages(String chatId, String query, {String fromMessageId = '', int limit = 50}) async {
    if (query.trim().isEmpty) return const MessageSearchPage(messages: [], total: 0);
    final found = messagesOf(chatId).reversed.where((m) => !m.service &&
        '${m.text} ${m.fileName ?? ''}'.toLowerCase().contains(query.trim().toLowerCase())).toList();
    final start = fromMessageId.isEmpty ? 0 : found.indexWhere((m) => m.id == fromMessageId);
    final offset = start < 0 ? found.length : start;
    final page = found.skip(offset).take(limit.clamp(1, 100)).toList();
    return MessageSearchPage(messages: page, total: found.length,
      nextFromMessageId: offset + page.length < found.length ? found[offset + page.length].id : '');
  }

  @override
  Future<void> historyAround(String chatId, String messageId) async {}

  @override
  Future<MessageRights> rightsOf(String chatId, String messageId) async {
    final chat = chatById(chatId);
    final m = messagesOf(chatId).where((x) => x.id == messageId).firstOrNull;
    if (chat == null || m == null || m.service) return const MessageRights();
    final plainText = m.fileName == null && m.info == null && m.media == null;
    return MessageRights(
      canEdit: m.out && plainText,
      canReply: chat.canSend && !m.pending && !m.failed,
      canForward: !m.pending && !m.failed,
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
        reply: _replies.remove(chatId),
      ));
    }
    final idx = _chats.indexWhere((c) => c.id == chatId);
    if (idx >= 0) _chats[idx] = _chats[idx].copyWith(last: '${S.current.chats.youPrefix}${files.last.name}', time: time, waiting: false);
    notifyListeners();
  }
}

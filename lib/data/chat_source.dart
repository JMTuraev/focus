import 'package:flutter/foundation.dart';

import '../backup/backup_key_store.dart';
import '../backup/backup_transport.dart';
import '../db/database.dart';
import 'local_store.dart';
import 'account_storage.dart';
import 'models.dart';

/// A message that just arrived from someone else (for Windows toasts).
@immutable
class IncomingMessage {
  const IncomingMessage({
    required this.chatId,
    required this.chatTitle,
    required this.kind,
    required this.muted,
    required this.preview,
    this.sender,
  });

  final String chatId;
  final String chatTitle;
  final ChatKind kind;

  /// Muted in Telegram (no toast).
  final bool muted;

  /// Text or a media label ("Rasm", "Fayl…").
  final String preview;

  /// Who wrote it, in groups.
  final String? sender;
}

/// A saved message as loaded from its chat (with the file's download state).
@immutable
class FoundFile {
  const FoundFile({required this.chatId, required this.chatTitle, required this.message});

  final String chatId;
  final String chatTitle;

  /// The message that carries the file: name, size, download state, media.
  final Message message;

  String get key => '$chatId:${message.id}';
}

/// Where chats and messages come from: mock data or TDLib.
/// Notifies listeners whenever chats or loaded messages change.
abstract class ChatSource extends ChangeNotifier {
  Future<void> sendReply(String chatId, String text, String messageId) =>
      Future.error(UnsupportedError('Replies are not supported by this source'));
  Future<void> sendFilesReply(String chatId, List<OutgoingFile> files, String messageId,
          {String caption = '', bool compressImages = true}) =>
      Future.error(UnsupportedError('File replies are not supported by this source'));
  Future<void> forwardMessages(String chatId, String fromChatId, List<String> messageIds) =>
      Future.error(UnsupportedError('Forwarding is not supported by this source'));
  Future<MessageSearchPage> searchMessages(String chatId, String query, {String fromMessageId = '', int limit = 50}) =>
      Future.error(UnsupportedError('Search is not supported by this source'));
  Future<void> historyAround(String chatId, String messageId) =>
      Future.error(UnsupportedError('Message navigation is not supported by this source'));

  /// A found file's message with the current download state (progress,
  /// local path). The default returns it unchanged.
  Message refreshFound(FoundFile f) => f.message;

  /// One message by id (saved items are stored as ids); null when the
  /// message is gone. Never marks anything as read.
  Future<FoundFile?> getFound(String chatId, String messageId);

  /// New messages from others as they arrive (not history, not our own).
  Stream<IncomingMessage> get incoming;

  /// Start downloading a file (photo, video, voice) by its TDLib file id.
  /// Progress and the local path show up in [MediaInfo] on later rebuilds.
  void download(int fileId, {int priority = 1});

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

  /// What the user may do with [messageId] (edit, delete for self / all).
  Future<MessageRights> rightsOf(String chatId, String messageId);

  /// Replaces the text of an own text message (TDLib: editMessageText).
  Future<void> editText(String chatId, String messageId, String text);

  /// Deletes messages; [forAll] also removes them for the other side
  /// (TDLib: deleteMessages with revoke).
  Future<void> deleteMessages(String chatId, List<String> messageIds, {required bool forAll});

  /// Pins or unpins [chatId] in Telegram's main chat list
  /// (TDLib: toggleChatIsPinned). The new order arrives as a position update.
  Future<void> setPinned(String chatId, bool pinned);

  /// Sends [files] to [chatId]. Images go as compressed photos when
  /// [compressImages] is set (grouped into albums), everything else as
  /// documents. [caption] goes with the first file.
  Future<void> sendFiles(String chatId, List<OutgoingFile> files, {String caption = '', bool compressImages = true});
}

/// What the user may do with a message (TDLib getMessageProperties).
@immutable
class MessageRights {
  const MessageRights(
      {this.canEdit = false, this.canDeleteForMe = false, this.canDeleteForAll = false, this.canReply = false, this.canForward = false});

  final bool canEdit;
  final bool canDeleteForMe;
  final bool canDeleteForAll;
  final bool canReply;
  final bool canForward;

  bool get canDelete => canDeleteForMe || canDeleteForAll;
}

class MessageSearchPage {
  const MessageSearchPage({required this.messages, required this.total, this.nextFromMessageId = ''});
  final List<Message> messages;
  final int total;
  final String nextFromMessageId;
}

/// What the app needs after login: chats plus Focus-only local data.
class ChatSession {
  ChatSession({
    required this.source,
    required this.store,
    AppDatabase? db,
    BackupTransport? backupTransport,
    BackupKeyStore? backupKeys,
    this.initialChatId,
    this.accountStorage,
  })  : db = db ?? AppDatabase.memory(),
        backupTransport = backupTransport ?? MemoryBackupTransport(),
        backupKeys = backupKeys ?? MemoryBackupKeyStore();

  final ChatSource source;
  final LocalStore store;

  /// Tasks and other Focus data (in memory for mock sessions).
  final AppDatabase db;

  /// Where encrypted backups go (Saved Messages; memory for mock sessions).
  final BackupTransport backupTransport;

  /// The backup key on this PC (DPAPI; memory for mock sessions).
  final BackupKeyStore backupKeys;

  /// Chat selected at start (mock data opens the first scripted chat).
  final String? initialChatId;
  final AccountStorage? accountStorage;
  String? get accountId => accountStorage?.accountId;

  Future<void> close() async {
    await store.flush();
    source.dispose();
    await db.close();
  }
}

import 'package:flutter/foundation.dart';

import '../backup/backup_key_store.dart';
import '../backup/backup_transport.dart';
import '../db/database.dart';
import 'local_store.dart';
import 'models.dart';

/// Where chats and messages come from: mock data or TDLib.
/// Notifies listeners whenever chats or loaded messages change.
abstract class ChatSource extends ChangeNotifier {
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

  Future<void> close() async {
    await store.flush();
    source.dispose();
    await db.close();
  }
}

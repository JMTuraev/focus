import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../l10n/l10n.dart';

/// Icons a collection can use, by a stable key (stored in local_state.json).
const kCollectionIcons = <String, IconData>{
  'forum': Icons.forum_outlined,
  'person': Icons.person_outline,
  'work': Icons.work_outline,
  'groups': Icons.groups_outlined,
  'handshake': Icons.handshake_outlined,
  'wallet': Icons.account_balance_wallet_outlined,
  'home': Icons.home_outlined,
  'public': Icons.public,
  'star': Icons.star_outline,
  'favorite': Icons.favorite_border,
  'school': Icons.school_outlined,
  'shopping': Icons.shopping_bag_outlined,
  'truck': Icons.local_shipping_outlined,
  'campaign': Icons.campaign_outlined,
  'code': Icons.code,
  'health': Icons.medical_services_outlined,
  'sport': Icons.sports_soccer_outlined,
  'flag': Icons.flag_outlined,
  'folder': Icons.folder_outlined,
  'bolt': Icons.bolt_outlined,
};

/// A user-defined group of chats (Focus-only, never sent to Telegram).
/// Keys of the collection colors, in [FokusColors.collectionColors] order.
/// '' is the default (accent blue).
const kCollectionColorKeys = ['', 'green', 'teal', 'orange', 'red', 'purple', 'pink', 'grey'];

class Collection {
  const Collection(this.id, this._label, this.iconKey, [this.colorKey = '']);
  final String id;
  final String _label;
  final String iconKey;

  /// One of [kCollectionColorKeys]; '' = accent.
  final String colorKey;

  /// The name; the virtual [kAllCollection] is named in the current language.
  String get label => id == kAllCollection.id ? S.current.notes.allCollection : _label;

  IconData get icon => kCollectionIcons[iconKey] ?? Icons.folder_outlined;

  Map<String, String> toJson() => {'id': id, 'label': label, 'icon': iconKey, 'color': colorKey};

  static Collection fromJson(Map<String, dynamic> j) => Collection(
      j['id'] as String, j['label'] as String, (j['icon'] as String?) ?? 'folder', (j['color'] as String?) ?? '');
}

/// The virtual "all chats" entry: the "Chatlar" side of the switch above
/// the chat list.
const kAllCollection = Collection('all', 'Hammasi', 'forum');

/// Collections a new install starts with.
const kDefaultCollections = <Collection>[
  Collection('mijoz', 'Mijozlar', 'person'),
  Collection('ish', 'Ish', 'work'),
  Collection('jamoa', 'Jamoa', 'groups'),
  Collection('hamkor', 'Hamkorlar', 'handshake'),
  Collection('moliya', 'Moliya', 'wallet'),
  Collection('oila', 'Oila', 'home'),
  Collection('hamjam', 'Hamjamiyatlar', 'public'),
];

enum ChatKind { private, bot, group, channel, saved }

class Chat {
  const Chat({
    required this.id,
    required this.name,
    required this.initials,
    required this.color,
    required this.collection,
    required this.last,
    required this.time,
    required this.status,
    this.unread = 0,
    this.waiting = false,
    this.online = false,
    this.muted = false,
    this.phone = '',
    this.about = '',
    this.photo,
    this.kind = ChatKind.private,
    this.pinned = false,
    this.canSend = true,
    this.typing = '',
    this.lastAt,
  });

  final String id;
  final String name;
  final String initials;
  final Color color;

  /// Default collection id ('' = not sorted yet). The user's choice is
  /// stored separately (LocalStore) and wins over this.
  final String collection;

  /// Last message preview, e.g. "Siz: Kelishdik" or "Sardor: Reliz tayyor".
  final String last;
  final String time;
  final String status;

  /// Unread count as Telegram knows it (Focus never marks chats as read).
  final int unread;

  /// The other side is waiting for our reply.
  final bool waiting;
  final bool online;
  final bool muted;
  final String phone;
  final String about;

  /// Local path of the small profile photo, once downloaded.
  final String? photo;
  final ChatKind kind;

  /// Pinned in the main chat list.
  final bool pinned;

  /// False for channels where we are not an admin, or groups that do not let
  /// us write; the composer is replaced by a read-only note.
  final bool canSend;

  /// What the other side is doing right now ("yozmoqda…", in groups with the
  /// name), or '' (from TDLib updateChatAction; shown instead of the status).
  final String typing;

  /// When the last message was sent (null in mock data).
  final DateTime? lastAt;

  Chat copyWith({String? last, String? time, int? unread, bool? waiting, String? phone, String? about, bool? pinned}) =>
      Chat(
        id: id,
        name: name,
        initials: initials,
        color: color,
        collection: collection,
        last: last ?? this.last,
        time: time ?? this.time,
        status: status,
        unread: unread ?? this.unread,
        waiting: waiting ?? this.waiting,
        online: online,
        muted: muted,
        phone: phone ?? this.phone,
        about: about ?? this.about,
        photo: photo,
        kind: kind,
        pinned: pinned ?? this.pinned,
        canSend: canSend,
        typing: typing,
        lastAt: lastAt,
      );
}

enum MediaKind { photo, video, gif, sticker, voice, videoNote, audio, location, contact, poll, call, other }

/// Formatting inside a message text (Telegram text entities).
enum EntityKind {
  bold,
  italic,
  underline,
  strike,
  code,
  pre,
  spoiler,
  quote,

  /// A visible URL, e-mail or phone number.
  url,

  /// Text with a hidden link ([TextEntity.url]).
  textUrl,
  mention,
  hashtag,
}

class TextEntity {
  const TextEntity(this.offset, this.length, this.kind, {this.url});

  /// UTF-16 offsets, the same units as Dart strings.
  final int offset;
  final int length;
  final EntityKind kind;
  final String? url;
}

/// Photo, video, voice, sticker... with what is needed to draw and play it.
class MediaInfo {
  const MediaInfo({
    required this.kind,
    this.width = 0,
    this.height = 0,
    this.mini,
    this.previewFileId,
    this.previewPath,
    this.fileId,
    this.filePath,
    this.progress = 0,
    this.downloading = false,
    this.duration = 0,
    this.waveform = const [],
    this.size = 0,
  });

  final MediaKind kind;
  final int width;
  final int height;

  /// Tiny blurred JPEG shown until the preview is downloaded.
  final Uint8List? mini;

  /// Picture shown in the chat: a photo size or a video thumbnail.
  final int? previewFileId;
  final String? previewPath;

  /// The full file: video, voice, large photo.
  final int? fileId;
  final String? filePath;

  /// Download progress of [fileId], 0..1.
  final double progress;
  final bool downloading;

  /// Seconds (video, voice).
  final int duration;

  /// Voice: amplitudes 0..31.
  final List<int> waveform;
  final int size;

  double get aspect => width > 0 && height > 0 ? width / height : 4 / 3;
}

class Message {
  const Message({
    required this.id,
    required this.text,
    required this.time,
    this.out = false,
    this.from,
    this.fileName,
    this.fileMeta,
    this.meeting,
    this.date,
    this.media,
    this.mediaLabel,
    this.service = false,
    this.pending = false,
    this.failed = false,
    this.read = true,
    this.entities = const [],
    this.info,
    this.senderId,
    this.senderInitials = '',
    this.senderColor = 0,
    this.senderPhoto,
    this.meetingAt,
    this.file,
    this.edited = false,
  });

  final String id;

  /// Text or caption ('' for media without caption).
  final String text;
  final String time;
  final bool out;
  final String? from;
  final String? fileName;
  final String? fileMeta;

  /// Meeting detected in the text, e.g. "Payshanba, 8-okt · 15:00".
  final String? meeting;

  /// When the detected meeting starts.
  final DateTime? meetingAt;

  /// Edited after sending ("tahrirlangan" next to the time).
  final bool edited;

  /// Send date (null in mock data: everything is "today").
  final DateTime? date;

  /// Non-file media shown as an icon row with [mediaLabel].
  final MediaKind? media;
  final String? mediaLabel;

  /// Service message ("X joined the group"), shown centered.
  final bool service;

  /// Outgoing: still sending / failed / read by the other side.
  final bool pending;
  final bool failed;
  final bool read;

  /// Bold, links, spoilers... in [text].
  final List<TextEntity> entities;

  /// Drawable media (photos, videos, voice, stickers).
  final MediaInfo? info;

  /// Group messages: who wrote it, for the name color and the avatar.
  final String? senderId;
  final String senderInitials;

  /// Index into the theme's sender colors.
  final int senderColor;
  final String? senderPhoto;

  /// Document or audio file: download state, or upload state while sending.
  final FileInfo? file;

  /// Same message with a detected meeting (or none).
  Message withMeeting(String? label, DateTime? at) => Message(
        id: id,
        text: text,
        time: time,
        out: out,
        from: from,
        fileName: fileName,
        fileMeta: fileMeta,
        meeting: label,
        meetingAt: at,
        date: date,
        media: media,
        mediaLabel: mediaLabel,
        service: service,
        pending: pending,
        failed: failed,
        read: read,
        entities: entities,
        info: info,
        senderId: senderId,
        senderInitials: senderInitials,
        senderColor: senderColor,
        senderPhoto: senderPhoto,
        file: file,
        edited: edited,
      );

  /// The same message with new text (mock edits).
  Message withText(String newText) => Message(
        id: id,
        text: newText,
        time: time,
        out: out,
        from: from,
        fileName: fileName,
        fileMeta: fileMeta,
        date: date,
        media: media,
        mediaLabel: mediaLabel,
        service: service,
        read: read,
        info: info,
        senderId: senderId,
        senderInitials: senderInitials,
        senderColor: senderColor,
        senderPhoto: senderPhoto,
        file: file,
        edited: true,
      );
}

/// A document or audio file inside a message.
class FileInfo {
  const FileInfo({
    required this.fileId,
    this.size = 0,
    this.path,
    this.progress = 0,
    this.downloading = false,
    this.uploadProgress,
  });

  final int fileId;
  final int size;

  /// Local path once the file is downloaded (or the source of an upload).
  final String? path;

  /// Download progress 0..1.
  final double progress;
  final bool downloading;

  /// Upload progress 0..1 while the message is being sent, else null.
  final double? uploadProgress;

  bool get downloaded => path != null;
}

/// What a saved item is; the tabs of the "Fayllar" module.
enum SavedKind {
  documents,
  photos,
  videos,
  audio,
  text;

  static SavedKind of(Message m) => switch (m.info?.kind) {
        MediaKind.photo => SavedKind.photos,
        MediaKind.video || MediaKind.gif || MediaKind.videoNote => SavedKind.videos,
        MediaKind.voice || MediaKind.audio => SavedKind.audio,
        _ => m.fileName != null ? SavedKind.documents : SavedKind.text,
      };

  bool get isMedia => this == SavedKind.photos || this == SavedKind.videos;
}

/// A message the user saved from a chat into "Fayllar" (Focus-only). Keeps
/// a snapshot (chat title, text, file name, size, date) so the list shows
/// at once; the file itself is fetched from TDLib when opened.
@immutable
class SavedItem {
  const SavedItem({
    required this.chatId,
    required this.messageId,
    required this.kind,
    required this.chatTitle,
    this.text = '',
    this.fileName,
    this.size = 0,
    this.date,
    required this.savedAt,
  });

  final String chatId;
  final String messageId;
  final SavedKind kind;
  final String chatTitle;

  /// Message text or caption.
  final String text;
  final String? fileName;
  final int size;

  /// When the message was sent (null in mock data).
  final DateTime? date;
  final DateTime savedAt;

  String get key => '$chatId:$messageId';

  /// Date used for sorting and day groups.
  DateTime get when => date ?? savedAt;
}

/// Favorite and tags the user put on a file in Focus (never in Telegram).
@immutable
class FileMark {
  const FileMark({
    required this.chatId,
    required this.messageId,
    required this.kind,
    this.favorite = false,
    this.tags = const [],
    required this.updatedAt,
  });

  final String chatId;
  final String messageId;

  /// [SavedKind] name.
  final String kind;
  final bool favorite;
  final List<String> tags;
  final DateTime updatedAt;

  bool get isEmpty => !favorite && tags.isEmpty;

  bool hasTag(String tag) => tags.any((t) => t.toLowerCase() == tag.toLowerCase());
}

/// A file the user picked or dropped to send.
class OutgoingFile {
  const OutgoingFile({required this.path, required this.name, this.size = 0});

  final String path;
  final String name;
  final int size;

  String get extension => name.contains('.') ? name.split('.').last.toLowerCase() : '';

  /// Formats Telegram can show as a compressed photo.
  bool get isImage => const {'jpg', 'jpeg', 'png', 'webp', 'bmp'}.contains(extension);
}

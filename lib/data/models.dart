import 'dart:typed_data';

import 'package:flutter/material.dart';

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
class Collection {
  const Collection(this.id, this.label, this.iconKey);
  final String id;
  final String label;
  final String iconKey;

  IconData get icon => kCollectionIcons[iconKey] ?? Icons.folder_outlined;

  Map<String, String> toJson() => {'id': id, 'label': label, 'icon': iconKey};

  static Collection fromJson(Map<String, dynamic> j) =>
      Collection(j['id'] as String, j['label'] as String, (j['icon'] as String?) ?? 'folder');
}

/// The virtual "all chats" entry at the top of the rail.
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

  Chat copyWith({String? last, String? time, int? unread, bool? waiting, String? phone, String? about}) => Chat(
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
        pinned: pinned,
        canSend: canSend,
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
      );
}

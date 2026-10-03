import 'package:flutter/material.dart';

class Collection {
  const Collection(this.id, this.label, this.icon);
  final String id;
  final String label;
  final IconData icon;
}

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

  /// Unread count as Telegram knows it (Fokus never marks chats as read).
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
}

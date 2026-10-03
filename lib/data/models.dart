import 'package:flutter/material.dart';

class Collection {
  const Collection(this.id, this.label, this.icon);
  final String id;
  final String label;
  final IconData icon;
}

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
  });

  final String id;
  final String name;
  final String initials;
  final Color color;
  final String collection;
  final String last;
  final String time;
  final String status;
  final int unread;
  final bool waiting;
  final bool online;
  final bool muted;
  final String phone;
  final String about;
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
  });

  final String id;
  final String text;
  final String time;
  final bool out;
  final String? from;
  final String? fileName;
  final String? fileMeta;

  /// Meeting detected in the text, e.g. "Payshanba, 8-okt · 15:00".
  final String? meeting;
}

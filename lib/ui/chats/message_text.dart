import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../data/models.dart';
import '../../l10n/l10n.dart';
import '../../theme.dart';

/// Message text with Telegram formatting: bold, italic, code, links,
/// mentions, hashtags, quotes and spoilers (hidden until tapped).
class MessageText extends StatefulWidget {
  const MessageText(this.text, {super.key, this.entities = const [], required this.style});

  final String text;
  final List<TextEntity> entities;
  final TextStyle style;

  @override
  State<MessageText> createState() => _MessageTextState();
}

class _MessageTextState extends State<MessageText> {
  final _recognizers = <GestureRecognizer>[];
  final _revealed = <int>{};

  @override
  void dispose() {
    _disposeRecognizers();
    super.dispose();
  }

  void _disposeRecognizers() {
    for (final r in _recognizers) {
      r.dispose();
    }
    _recognizers.clear();
  }

  @override
  Widget build(BuildContext context) {
    _disposeRecognizers();
    if (widget.entities.isEmpty) return Text(widget.text, style: widget.style);
    return Text.rich(TextSpan(children: _spans(context)), style: widget.style);
  }

  List<InlineSpan> _spans(BuildContext context) {
    final c = context.fc;
    final text = widget.text;
    final ents = widget.entities;
    final cuts = <int>{0, text.length};
    for (final e in ents) {
      cuts.add(e.offset.clamp(0, text.length));
      cuts.add((e.offset + e.length).clamp(0, text.length));
    }
    final points = cuts.toList()..sort();
    final spans = <InlineSpan>[];
    for (var i = 0; i + 1 < points.length; i++) {
      final a = points[i];
      final b = points[i + 1];
      if (a == b) continue;
      final active = <int>[
        for (var k = 0; k < ents.length; k++)
          if (ents[k].offset <= a && ents[k].offset + ents[k].length >= b) k,
      ];
      spans.add(_segment(context, c, text.substring(a, b), active));
    }
    return spans;
  }

  InlineSpan _segment(BuildContext context, FokusColors c, String part, List<int> active) {
    var style = const TextStyle();
    final decorations = <TextDecoration>[];
    TextEntity? link;
    int? hiddenSpoiler;
    for (final k in active) {
      final e = widget.entities[k];
      switch (e.kind) {
        case EntityKind.bold:
          style = style.copyWith(fontWeight: FontWeight.w700);
        case EntityKind.italic:
          style = style.copyWith(fontStyle: FontStyle.italic);
        case EntityKind.underline:
          decorations.add(TextDecoration.underline);
        case EntityKind.strike:
          decorations.add(TextDecoration.lineThrough);
        case EntityKind.code || EntityKind.pre:
          style = style.copyWith(fontFamily: 'Consolas', color: c.qaFg, backgroundColor: c.qaBg);
        case EntityKind.quote:
          style = style.copyWith(fontStyle: FontStyle.italic, color: c.textSoft);
        case EntityKind.url || EntityKind.textUrl || EntityKind.mention || EntityKind.hashtag:
          style = style.copyWith(color: c.accentText);
          if (e.kind == EntityKind.url || e.kind == EntityKind.textUrl) link = e;
        case EntityKind.spoiler:
          if (!_revealed.contains(k)) hiddenSpoiler = k;
      }
    }
    if (decorations.isNotEmpty) style = style.copyWith(decoration: TextDecoration.combine(decorations));

    if (hiddenSpoiler != null) {
      final k = hiddenSpoiler;
      final r = TapGestureRecognizer()..onTap = () => setState(() => _revealed.add(k));
      _recognizers.add(r);
      return TextSpan(
        text: part,
        style: style.copyWith(color: Colors.transparent, backgroundColor: c.text2.withValues(alpha: 0.45)),
        recognizer: r,
        mouseCursor: SystemMouseCursors.click,
      );
    }
    if (link != null) {
      final e = link;
      final full = widget.text.substring(
        e.offset.clamp(0, widget.text.length),
        (e.offset + e.length).clamp(0, widget.text.length),
      );
      final r = TapGestureRecognizer()..onTap = () => openLink(context, e, full);
      _recognizers.add(r);
      return TextSpan(text: part, style: style, recognizer: r, mouseCursor: SystemMouseCursors.click);
    }
    return TextSpan(text: part, style: style);
  }
}

/// Target URL for a link entity, or null when it must not be opened.
/// Only web, e-mail, phone and Telegram links are allowed.
Uri? linkTarget(TextEntity e, String visibleText) {
  var raw = switch (e.kind) {
    EntityKind.textUrl => e.url ?? '',
    _ => (e.url ?? '') + visibleText.trim(),
  };
  if (!raw.contains(':')) raw = 'https://$raw';
  final uri = Uri.tryParse(raw);
  if (uri == null) return null;
  const allowed = {'http', 'https', 'mailto', 'tel', 'tg'};
  return allowed.contains(uri.scheme.toLowerCase()) ? uri : null;
}

/// Opens a link from a message in the default browser. Hidden links
/// (text that differs from its URL) are confirmed first, like Telegram does.
Future<void> openLink(BuildContext context, TextEntity e, String visibleText) async {
  final uri = linkTarget(e, visibleText);
  if (uri == null) return;
  if (e.kind == EntityKind.textUrl && e.url != visibleText.trim()) {
    final c = context.fc;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: c.panel,
        title: Text(context.s.chats.openLinkTitle, style: TextStyle(color: c.text, fontSize: 18, fontWeight: FontWeight.w700)),
        content: SelectableText(uri.toString(), style: TextStyle(color: c.accentText, fontSize: 14)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            style: TextButton.styleFrom(foregroundColor: c.text2),
            child: Text(context.s.common.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: c.accentText),
            child: Text(context.s.common.open),
          ),
        ],
      ),
    );
    if (ok != true) return;
  }
  await launchUrl(uri, mode: LaunchMode.externalApplication);
}

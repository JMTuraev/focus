import 'package:flutter/material.dart';

import '../../data/models.dart';
import '../../l10n/l10n.dart';
import '../../state/app_state.dart';
import '../../theme.dart';
import '../common.dart';

/// Color of a user tag: stable per name, from the collection palette
/// (light and dark variants), never the grey slot.
Color tagColor(FokusColors c, String tag) {
  var h = 0;
  for (final u in tag.toLowerCase().codeUnits) {
    h = (h * 31 + u) & 0x7fffffff;
  }
  return c.collectionColors[h % 7];
}

/// Small pill with a colored dot and the tag name.
class TagPill extends StatelessWidget {
  const TagPill(this.tag, {super.key, this.selected = false, this.onTap, this.count});

  final String tag;
  final bool selected;
  final VoidCallback? onTap;
  final int? count;

  @override
  Widget build(BuildContext context) {
    final c = context.fc;
    final tint = tagColor(c, tag);
    return Tap(
      onTap: onTap,
      radius: 12,
      color: selected ? tint.withValues(alpha: 0.2) : Colors.transparent,
      hover: onTap == null ? null : tint.withValues(alpha: 0.12),
      border: Border.all(color: selected ? tint : c.chipBorder),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(7, 3, 9, 3),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 7, height: 7, decoration: BoxDecoration(color: tint, shape: BoxShape.circle)),
            const SizedBox(width: 5),
            Text(count == null ? tag : '$tag $count',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: selected ? c.text : c.textSoft)),
          ],
        ),
      ),
    );
  }
}

/// Opens the marks popover next to [anchor] (the card's global rect):
/// favorite and the user's tags for [item], and taking it out of
/// "Fayllar". Changes apply at once; Escape or a click outside closes it.
Future<void> showFileMarksPopover(
  BuildContext context, {
  required Rect anchor,
  required AppState state,
  required SavedItem item,
  required String title,
}) {
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: context.s.common.close,
    barrierColor: Colors.transparent,
    transitionDuration: const Duration(milliseconds: 120),
    pageBuilder: (context, _, __) => CustomSingleChildLayout(
      delegate: _BesideLayout(anchor),
      child: _MarksPopover(state: state, item: item, title: title),
    ),
    transitionBuilder: (context, a, _, child) => FadeTransition(
      opacity: CurvedAnimation(parent: a, curve: Curves.easeOut),
      child: child,
    ),
  );
}

/// Places the popover right of the anchor, or left of it when there is no
/// room, else below; always inside the window with an 8 px margin.
class _BesideLayout extends SingleChildLayoutDelegate {
  _BesideLayout(this.anchor);

  final Rect anchor;
  static const _gap = 8.0;

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) =>
      BoxConstraints.loose(Size(constraints.maxWidth - 2 * _gap, constraints.maxHeight - 2 * _gap));

  @override
  Offset getPositionForChild(Size size, Size child) {
    double x;
    double y = anchor.top;
    if (anchor.right + _gap + child.width <= size.width - _gap) {
      x = anchor.right + _gap;
    } else if (anchor.left - _gap - child.width >= _gap) {
      x = anchor.left - _gap - child.width;
    } else {
      x = anchor.left;
      y = anchor.bottom + _gap;
    }
    x = x.clamp(_gap, size.width - child.width - _gap);
    y = y.clamp(_gap, size.height - child.height - _gap);
    return Offset(x, y);
  }

  @override
  bool shouldRelayout(_BesideLayout old) => old.anchor != anchor;
}

class _MarksPopover extends StatefulWidget {
  const _MarksPopover({required this.state, required this.item, required this.title});

  final AppState state;
  final SavedItem item;
  final String title;

  @override
  State<_MarksPopover> createState() => _MarksPopoverState();
}

class _MarksPopoverState extends State<_MarksPopover> {
  final _tag = TextEditingController();
  final _focus = FocusNode();

  AppState get s => widget.state;
  String get _chatId => widget.item.chatId;
  String get _msgId => widget.item.messageId;
  String get _kind => widget.item.kind.name;

  @override
  void dispose() {
    _tag.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _add(String v) {
    final t = v.trim();
    if (t.isNotEmpty) s.setFileTag(_chatId, _msgId, _kind, t, true);
    _tag.clear();
    _focus.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.fc;
    final t = context.s.files;
    return ListenableBuilder(
      listenable: s,
      builder: (context, _) {
        final mark = s.fileMark(_chatId, _msgId);
        final fav = mark?.favorite ?? false;
        final all = s.store.tagCounts.map((e) => e.$1).toList();
        // Tags of this file first, in the order they were added.
        final own = mark?.tags ?? const <String>[];
        final others = all.where((x) => !own.any((o) => o.toLowerCase() == x.toLowerCase()));
        // Its own raised surface with an accent edge, so it never blends
        // with the cards behind it.
        return Material(
          color: c.popover,
          elevation: 12,
          shadowColor: Colors.black54,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            width: 290,
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: c.accent.withValues(alpha: 0.45)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: c.text)),
                Text(widget.item.chatTitle,
                    maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12, color: c.text2)),
                const SizedBox(height: 10),
                Tap(
                  onTap: () => s.toggleFileFavorite(_chatId, _msgId, _kind),
                  radius: 10,
                  color: fav ? c.waitingStrong.withValues(alpha: 0.14) : c.hover,
                  hover: c.border,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    child: Row(
                      children: [
                        Icon(fav ? Icons.star_rounded : Icons.star_outline_rounded,
                            size: 20, color: fav ? c.waitingStrong : c.text2),
                        const SizedBox(width: 8),
                        Text(fav ? t.removeFavorite : t.addFavorite,
                            style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: c.text)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(t.tags, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: c.text2)),
                const SizedBox(height: 6),
                if (all.isNotEmpty) ...[
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final tag in own)
                        TagPill(tag, selected: true, onTap: () => s.setFileTag(_chatId, _msgId, _kind, tag, false)),
                      for (final tag in others)
                        TagPill(tag, onTap: () => s.setFileTag(_chatId, _msgId, _kind, tag, true)),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
                SizedBox(
                  height: 34,
                  child: TextField(
                    controller: _tag,
                    focusNode: _focus,
                    autofocus: true,
                    maxLength: 24,
                    onSubmitted: _add,
                    style: TextStyle(fontSize: 13.5, color: c.text),
                    decoration: InputDecoration(
                      counterText: '',
                      hintText: t.newTagHint,
                      hintStyle: TextStyle(color: c.text2, fontSize: 13.5),
                      prefixIcon: Icon(Icons.sell_outlined, size: 16, color: c.text2),
                      isDense: true,
                      filled: true,
                      fillColor: c.hover,
                      contentPadding: EdgeInsets.zero,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: c.chipBorder)),
                      enabledBorder:
                          OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: c.chipBorder)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: c.accent)),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(t.tagsHint, style: TextStyle(fontSize: 11, color: c.text2, height: 1.3)),
                const SizedBox(height: 8),
                Divider(height: 1, color: c.border),
                const SizedBox(height: 4),
                TextButton.icon(
                  onPressed: () {
                    Navigator.of(context).pop();
                    s.removeFromFiles(_chatId, _msgId);
                  },
                  icon: Icon(Icons.delete_outline, size: 18, color: c.danger),
                  label: Text(t.removeFromFiles, style: TextStyle(color: c.danger, fontSize: 13)),
                  style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 6)),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

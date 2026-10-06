import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/chat_source.dart';
import '../../data/format.dart';
import '../../data/models.dart';
import '../../l10n/l10n.dart';
import '../../state/app_state.dart';
import '../../theme.dart';
import '../chats/file_actions.dart';
import '../common.dart';
import 'file_marks_popover.dart';

/// "Fayllar": the files and messages the user saved from chats ("Fayllarga"
/// in a chat, or "Fayllarga saqlash" on a file), not every file of every
/// chat. Shown as cards, grouped by day or by chat, with kind tabs, a local
/// search over names, texts and tags, and the marks filter (favorites, one
/// tag). Each card has a marks button: a popover beside it sets favorite,
/// tags, or takes the item out. Click opens a document (downloading it
/// first) or the chat; the pencil renames a file in Focus only.
class FilesScreen extends StatefulWidget {
  const FilesScreen({super.key, required this.state});

  final AppState state;

  @override
  State<FilesScreen> createState() => _FilesScreenState();
}

class _FilesScreenState extends State<FilesScreen> {
  /// Kind tab; null = every kind.
  SavedKind? _kind;
  final _query = TextEditingController();

  /// Marks filter: favorites only, or one tag (lower case).
  bool _favorites = false;
  String? _tag;

  /// Card being renamed inline.
  String? _renaming;

  /// Saved files loaded from their chats (download state, local path).
  final _found = <String, FoundFile>{};
  final _requested = <String>{};

  AppState get s => widget.state;

  @override
  void initState() {
    super.initState();
    // Marks made in the old all-chats list become saved items once.
    s.adoptMarkedFiles();
  }

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  /// Saved items in the chat filter (if any), before tabs and marks.
  List<SavedItem> get _inScope {
    final chat = s.fileChatFilter;
    return s.store.savedItems.where((i) => chat == null || i.chatId == chat).toList();
  }

  List<SavedItem> _visible(List<SavedItem> scope) {
    final q = _query.text.trim().toLowerCase();
    return scope.where((i) {
      if (_kind != null && i.kind != _kind) return false;
      final m = s.fileMark(i.chatId, i.messageId);
      if (_favorites && !(m?.favorite ?? false)) return false;
      if (_tag != null && !(m?.hasTag(_tag!) ?? false)) return false;
      if (q.isEmpty) return true;
      final name = (s.store.fileName(i.chatId, i.messageId) ?? i.fileName ?? '').toLowerCase();
      return name.contains(q) ||
          i.text.toLowerCase().contains(q) ||
          i.chatTitle.toLowerCase().contains(q) ||
          (m?.tags.any((t) => t.toLowerCase().contains(q)) ?? false);
    }).toList();
  }

  /// Loads the shown files from their chats once, for download state.
  void _ensureLoaded(List<SavedItem> items) {
    for (final i in items) {
      if (i.kind == SavedKind.text || !_requested.add(i.key)) continue;
      s.source.getFound(i.chatId, i.messageId).then((f) {
        if (f == null || !mounted) return;
        setState(() => _found[i.key] = f);
      });
    }
  }

  void _toggleFilter({bool favorites = false, String? tag}) {
    setState(() {
      if (favorites) {
        _favorites = !_favorites;
        _tag = null;
      } else {
        _tag = _tag == tag ? null : tag;
        _favorites = false;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = context.fc;
    final t = context.s.files;
    final scope = _inScope;
    final visible = _visible(scope);
    // A tag that is no longer used drops its filter.
    if (_tag != null && !s.store.tagCounts.any((e) => e.$1.toLowerCase() == _tag)) _tag = null;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _ensureLoaded(visible);
    });
    return Container(
      color: c.bg,
      child: LayoutBuilder(
        builder: (context, box) {
          final pad = box.maxWidth < 600 ? 16.0 : 28.0;
          return CustomScrollView(
            slivers: [
              SliverPadding(
                padding: EdgeInsets.fromLTRB(pad, 24, pad, 6),
                sliver: SliverToBoxAdapter(child: _header(c, t, scope, visible.length)),
              ),
              if (visible.isEmpty)
                SliverFillRemaining(hasScrollBody: false, child: Center(child: _emptyState(c, t, scope.isEmpty)))
              else
                for (final g in _groups(visible, t)) ...[
                  if (g.header != null)
                    SliverPadding(
                      padding: EdgeInsets.fromLTRB(pad, 14, pad, 8),
                      sliver: SliverToBoxAdapter(child: g.header),
                    )
                  else
                    const SliverToBoxAdapter(child: SizedBox(height: 10)),
                  SliverPadding(
                    padding: EdgeInsets.symmetric(horizontal: pad),
                    sliver: SliverGrid(
                      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: 320,
                        mainAxisExtent: 128,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, i) => _card(g.items[i]),
                        childCount: g.items.length,
                      ),
                    ),
                  ),
                ],
              const SliverToBoxAdapter(child: SizedBox(height: 24)),
            ],
          );
        },
      ),
    );
  }

  Widget _card(SavedItem i) {
    return _SavedCard(
      key: ValueKey(i.key),
      item: i,
      found: _found[i.key],
      state: s,
      renaming: _renaming == i.key,
      onRename: () => setState(() => _renaming = i.key),
      onRenamed: (name) {
        s.renameFile(i.chatId, i.messageId, name);
        setState(() => _renaming = null);
      },
      onCancelRename: () => setState(() => _renaming = null),
    );
  }

  /// Splits [items] (newest first) by day or by chat, keeping their order.
  List<_Group> _groups(List<SavedItem> items, FilesStrings t) {
    final group = s.filesGroup;
    if (group == FilesGroup.none) return [_Group(null, items)];
    final c = context.fc;
    final order = <String>[];
    final byKey = <String, List<SavedItem>>{};
    String keyOf(SavedItem i) {
      if (group == FilesGroup.chat) return i.chatId;
      final d = i.date;
      return d == null ? '' : '${d.year}-${d.month}-${d.day}';
    }

    for (final i in items) {
      final k = keyOf(i);
      if (!byKey.containsKey(k)) order.add(k);
      (byKey[k] ??= []).add(i);
    }
    return [
      for (final k in order)
        _Group(
          group == FilesGroup.chat
              ? _GroupHeader(
                  leading: ChatAvatar(_chatOf(byKey[k]!.first), size: 22, showOnline: false),
                  title: byKey[k]!.first.chatTitle,
                  count: byKey[k]!.length,
                )
              : _GroupHeader(
                  leading: Icon(Icons.event_outlined, size: 18, color: c.text2),
                  title: k.isEmpty ? t.noDate : Fmt.dayLabel(byKey[k]!.first.date!),
                  count: byKey[k]!.length,
                ),
          byKey[k]!,
        ),
    ];
  }

  Chat _chatOf(SavedItem i) => chatOrPlaceholder(s, i.chatId, i.chatTitle);

  Widget _header(FokusColors c, FilesStrings t, List<SavedItem> scope, int shown) {
    final chat = s.fileChatFilter == null ? null : s.source.chatById(s.fileChatFilter!);
    final sub = chat == null ? t.intro : t.introForChat(chat.name);
    int countOf(SavedKind? k) => k == null ? scope.length : scope.where((i) => i.kind == k).length;
    final inKind = scope.where((i) => _kind == null || i.kind == _kind).toList();
    final marks = [for (final i in inKind) s.fileMark(i.chatId, i.messageId)].whereType<FileMark>().toList();
    final favCount = marks.where((m) => m.favorite).length;
    final tagCounts = [
      for (final (tag, _) in s.store.tagCounts) (tag, marks.where((m) => m.hasTag(tag)).length),
    ].where((e) => e.$2 > 0 || e.$1.toLowerCase() == _tag);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 12,
          runSpacing: 6,
          children: [
            Text(t.title, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: c.text)),
            if (shown > 0) Text(t.foundCount(shown), style: TextStyle(fontSize: 13, color: c.text2)),
          ],
        ),
        const SizedBox(height: 4),
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 8,
          runSpacing: 6,
          children: [
            Text(sub, style: TextStyle(fontSize: 13.5, color: c.text2)),
            if (chat != null)
              InputChip(
                avatar: ChatAvatar(chat, size: 20, showOnline: false),
                label: Text(chat.name, style: TextStyle(fontSize: 12.5, color: c.text)),
                deleteIcon: Icon(Icons.close, size: 16, color: c.text2),
                deleteButtonTooltipMessage: t.allChats,
                onDeleted: s.clearFileChatFilter,
                backgroundColor: c.panel,
                side: BorderSide(color: c.chipBorder),
                visualDensity: VisualDensity.compact,
              ),
          ],
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 6,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            for (final k in <SavedKind?>[null, ...SavedKind.values])
              _KindChip(
                label: '${switch (k) {
                  null => t.allFiles,
                  SavedKind.documents => t.tabDocuments,
                  SavedKind.photos => t.tabPhotos,
                  SavedKind.videos => t.tabVideos,
                  SavedKind.audio => t.tabAudio,
                  SavedKind.text => t.tabTexts,
                }} ${countOf(k)}',
                icon: switch (k) {
                  null => Icons.inventory_2_outlined,
                  SavedKind.documents => Icons.description_outlined,
                  SavedKind.photos => Icons.image_outlined,
                  SavedKind.videos => Icons.videocam_outlined,
                  SavedKind.audio => Icons.music_note_outlined,
                  SavedKind.text => Icons.notes_outlined,
                },
                active: _kind == k,
                onTap: () => setState(() => _kind = k),
              ),
            SizedBox(
              width: 260,
              height: 34,
              child: TextField(
                controller: _query,
                onChanged: (_) => setState(() {}),
                style: TextStyle(fontSize: 13.5, color: c.text),
                decoration: InputDecoration(
                  hintText: t.searchHint,
                  hintStyle: TextStyle(color: c.text2, fontSize: 13.5),
                  prefixIcon: Icon(Icons.search, size: 18, color: c.text2),
                  isDense: true,
                  filled: true,
                  fillColor: c.panel,
                  contentPadding: EdgeInsets.zero,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(17), borderSide: BorderSide(color: c.chipBorder)),
                  enabledBorder:
                      OutlineInputBorder(borderRadius: BorderRadius.circular(17), borderSide: BorderSide(color: c.chipBorder)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(17), borderSide: BorderSide(color: c.accent)),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 16,
          runSpacing: 8,
          children: [
            Wrap(
              spacing: 6,
              runSpacing: 6,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                _FilterPill(
                  label: '${t.favorites} $favCount',
                  icon: Icons.star_rounded,
                  iconColor: c.waitingStrong,
                  active: _favorites,
                  onTap: () => _toggleFilter(favorites: true),
                ),
                for (final (tag, n) in tagCounts)
                  TagPill(tag,
                      count: n, selected: _tag == tag.toLowerCase(), onTap: () => _toggleFilter(tag: tag.toLowerCase())),
              ],
            ),
            _GroupSwitch(
              label: t.groupBy,
              value: s.filesGroup,
              labels: {FilesGroup.day: t.groupDay, FilesGroup.chat: t.groupChat, FilesGroup.none: t.groupNone},
              onChanged: s.setFilesGroup,
            ),
          ],
        ),
      ],
    );
  }

  Widget _emptyState(FokusColors c, FilesStrings t, bool nothingSaved) {
    if (nothingSaved) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.bookmark_add_outlined, size: 40, color: c.text2),
            const SizedBox(height: 10),
            Text(t.emptySaved, textAlign: TextAlign.center, style: TextStyle(color: c.text2, fontSize: 14, height: 1.45)),
          ],
        ),
      );
    }
    final text = _query.text.trim().isNotEmpty ? t.emptySearch : (_favorites || _tag != null ? t.emptyMarked : t.emptyKind);
    return Text(text, style: TextStyle(color: c.text2, fontSize: 14));
  }
}

/// The chat for an avatar; a placeholder when it is not loaded.
Chat chatOrPlaceholder(AppState s, String chatId, String title) =>
    s.source.chatById(chatId) ??
    Chat(
        id: chatId,
        name: title,
        initials: Fmt.initials(title.isEmpty ? '?' : title),
        color: Fmt.avatarColor(int.tryParse(chatId) ?? chatId.hashCode),
        collection: '',
        last: '',
        time: '',
        status: '');

class _Group {
  const _Group(this.header, this.items);

  final Widget? header;
  final List<SavedItem> items;
}

class _GroupHeader extends StatelessWidget {
  const _GroupHeader({required this.leading, required this.title, required this.count});

  final Widget leading;
  final String title;
  final int count;

  @override
  Widget build(BuildContext context) {
    final c = context.fc;
    return Row(
      children: [
        leading,
        const SizedBox(width: 8),
        Flexible(
          child: Text(title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, color: c.text)),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
          decoration: BoxDecoration(color: c.panel, borderRadius: BorderRadius.circular(9)),
          child: Text('$count', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: c.text2)),
        ),
        const SizedBox(width: 10),
        Expanded(child: Divider(color: c.border, height: 1)),
      ],
    );
  }
}

class _FilterPill extends StatelessWidget {
  const _FilterPill({required this.label, required this.active, required this.onTap, this.icon, this.iconColor});

  final String label;
  final bool active;
  final VoidCallback onTap;
  final IconData? icon;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final c = context.fc;
    return Tap(
      onTap: onTap,
      radius: 12,
      color: active ? c.accentSoft : Colors.transparent,
      hover: c.hover,
      border: Border.all(color: active ? c.accent : c.chipBorder),
      child: Padding(
        padding: EdgeInsets.fromLTRB(icon == null ? 10 : 6, 3, 10, 3),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[Icon(icon, size: 15, color: iconColor), const SizedBox(width: 4)],
            Text(label,
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: active ? c.accentText : c.textSoft)),
          ],
        ),
      ),
    );
  }
}

/// "Guruhlash: Kunlar | Chatlar | Yo‘q".
class _GroupSwitch extends StatelessWidget {
  const _GroupSwitch({required this.label, required this.value, required this.labels, required this.onChanged});

  final String label;
  final FilesGroup value;
  final Map<FilesGroup, String> labels;
  final ValueChanged<FilesGroup> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = context.fc;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: TextStyle(fontSize: 12.5, color: c.text2)),
        const SizedBox(width: 8),
        Container(
          height: 28,
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
              color: c.panel, borderRadius: BorderRadius.circular(8), border: Border.all(color: c.border)),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final e in labels.entries)
                Tap(
                  onTap: () => onChanged(e.key),
                  radius: 6,
                  color: value == e.key ? c.accentStrong : Colors.transparent,
                  hover: value == e.key ? c.accentStrong : c.hover,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Center(
                      child: Text(e.value,
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: value == e.key ? Colors.white : c.textSoft)),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _KindChip extends StatelessWidget {
  const _KindChip({required this.label, required this.icon, required this.active, required this.onTap});

  final String label;
  final IconData icon;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.fc;
    final fg = active ? Colors.white : c.textSoft;
    return Tap(
      onTap: onTap,
      radius: 17,
      color: active ? c.accentStrong : c.panel,
      hover: active ? c.accentStrong : c.hover,
      border: Border.all(color: active ? c.accentStrong : c.chipBorder),
      child: Container(
        height: 34,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: fg),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: fg)),
          ],
        ),
      ),
    );
  }
}

/// Kinds of documents, each with its own icon and color.
enum FileType { pdf, document, sheet, slides, archive, image, video, audio, program, other }

FileType fileTypeOf(String name) {
  final ext = name.contains('.') ? name.split('.').last.toLowerCase() : '';
  return switch (ext) {
    'pdf' => FileType.pdf,
    'doc' || 'docx' || 'rtf' || 'odt' || 'txt' || 'md' => FileType.document,
    'xls' || 'xlsx' || 'csv' || 'ods' => FileType.sheet,
    'ppt' || 'pptx' || 'odp' => FileType.slides,
    'zip' || 'rar' || '7z' || 'gz' || 'tar' => FileType.archive,
    'jpg' || 'jpeg' || 'png' || 'gif' || 'webp' || 'bmp' || 'svg' || 'heic' => FileType.image,
    'mp4' || 'mov' || 'avi' || 'mkv' || 'webm' => FileType.video,
    'mp3' || 'ogg' || 'wav' || 'm4a' || 'flac' || 'opus' => FileType.audio,
    'exe' || 'msi' || 'bat' || 'cmd' || 'ps1' || 'apk' || 'sh' => FileType.program,
    _ => FileType.other,
  };
}

IconData fileTypeIcon(FileType t) => switch (t) {
      FileType.pdf => Icons.picture_as_pdf_outlined,
      FileType.document => Icons.description_outlined,
      FileType.sheet => Icons.table_chart_outlined,
      FileType.slides => Icons.slideshow_outlined,
      FileType.archive => Icons.folder_zip_outlined,
      FileType.image => Icons.image_outlined,
      FileType.video => Icons.videocam_outlined,
      FileType.audio => Icons.music_note_outlined,
      FileType.program => Icons.terminal,
      FileType.other => Icons.insert_drive_file_outlined,
    };

/// Type colors come from the collection palette (light and dark variants):
/// PDF red, text blue, sheets green, slides orange, archives purple,
/// images pink, video and audio teal, programs and the rest grey.
Color fileTypeColor(FokusColors c, FileType t) => c.collectionColors[switch (t) {
      FileType.pdf => 4,
      FileType.document => 0,
      FileType.sheet => 1,
      FileType.slides => 3,
      FileType.archive => 5,
      FileType.image => 6,
      FileType.video || FileType.audio => 2,
      FileType.program || FileType.other => 7,
    }];

/// A saved file or message. [found] is the message loaded from its chat
/// (download state); until it arrives the card shows the saved snapshot.
class _SavedCard extends StatefulWidget {
  const _SavedCard({
    super.key,
    required this.item,
    required this.found,
    required this.state,
    required this.renaming,
    required this.onRename,
    required this.onRenamed,
    required this.onCancelRename,
  });

  final SavedItem item;
  final FoundFile? found;
  final AppState state;
  final bool renaming;
  final VoidCallback onRename;
  final ValueChanged<String> onRenamed;
  final VoidCallback onCancelRename;

  @override
  State<_SavedCard> createState() => _SavedCardState();
}

class _SavedCardState extends State<_SavedCard> {
  bool _hover = false;

  SavedItem get _item => widget.item;
  AppState get _s => widget.state;
  bool get _text => _item.kind == SavedKind.text;
  bool get _media => _item.kind.isMedia;

  /// The message with the current download state, else the snapshot.
  Message get _message {
    final f = widget.found;
    if (f != null) return _s.source.refreshFound(f);
    return Message(id: _item.messageId, text: _item.text, time: '', fileName: _item.fileName, date: _item.date);
  }

  String _title(BuildContext context, Message m) {
    final t = context.s.files;
    if (_text) return _item.text;
    if (_media) return _item.text.isNotEmpty ? _item.text : (_item.kind == SavedKind.photos ? t.photo : t.video);
    return _s.store.fileName(_item.chatId, _item.messageId) ?? m.fileName ?? _item.fileName ?? context.s.common.file;
  }

  void _goToChat() {
    _s.jumpToChat(_item.chatId);
    _s.selectMessage(_item.messageId);
  }

  Future<void> _open(Message m) async {
    if (_text || _media || m.file == null) {
      _goToChat();
    } else {
      await openOrDownload(context, _s, m);
    }
  }

  Future<void> _menu(Offset pos, Message m) async {
    final t = context.s.files;
    final copyable = _item.text.isNotEmpty;
    await showFileMenu(
      context,
      m,
      pos,
      extra: {
        t.marks: _openMarks,
        if (!_text && !_media) t.rename: widget.onRename,
        if (copyable)
          t.copyText: () {
            Clipboard.setData(ClipboardData(text: _item.text));
            showToast(context, (w) => SnackBar(width: w < 360 ? w : 360, content: Text(t.copied)));
          },
        t.goToChat: _goToChat,
        t.removeFromFiles: () => _s.removeFromFiles(_item.chatId, _item.messageId),
      },
    );
  }

  /// The marks popover, beside this card.
  void _openMarks() {
    final box = context.findRenderObject() as RenderBox?;
    if (box == null || !box.attached) return;
    showFileMarksPopover(
      context,
      anchor: box.localToGlobal(Offset.zero) & box.size,
      state: _s,
      item: _item,
      title: _title(context, _message),
    );
  }

  Widget _iconButton(IconData icon, String tip, VoidCallback onTap, Color color) => Tooltip(
        message: tip,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onTap,
          child: Padding(padding: const EdgeInsets.all(4), child: Icon(icon, size: 18, color: color)),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final c = context.fc;
    final t = context.s.files;
    final m = _message;
    final f = m.file;
    final info = m.info;
    final downloading = f != null && !f.downloaded && f.downloading;
    final type = switch (_item.kind) {
      SavedKind.photos => FileType.image,
      SavedKind.videos => FileType.video,
      SavedKind.audio => FileType.audio,
      _ => fileTypeOf(m.fileName ?? _item.fileName ?? ''),
    };
    final tint = _text ? c.accent : fileTypeColor(c, type);
    final alias = _text || _media ? null : _s.store.fileName(_item.chatId, _item.messageId);
    final original = m.fileName ?? _item.fileName;
    final mark = _s.fileMark(_item.chatId, _item.messageId);
    final fav = mark?.favorite ?? false;
    final tags = mark?.tags ?? const <String>[];

    final size = f?.size ?? info?.size ?? _item.size;
    final meta = [
      if (_item.date != null) Fmt.listTime(_item.date!),
      if (downloading)
        '${Fmt.size((f.size * f.progress).round())} / ${Fmt.size(f.size)}'
      else if (size > 0)
        Fmt.size(size),
    ].join(' · ');

    final Widget leading = _text
        ? _TypeIcon(type: FileType.other, tint: tint, downloading: false, file: null, icon: Icons.format_quote_rounded)
        : _media
            ? _Thumb(info: info, kind: _item.kind, tint: tint)
            : _TypeIcon(type: type, tint: tint, downloading: downloading, file: f);

    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onSecondaryTapDown: (d) => _menu(d.globalPosition, m),
        child: Material(
          color: c.panel,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            onTap: widget.renaming ? null : () => _open(m),
            borderRadius: BorderRadius.circular(14),
            hoverColor: c.hover,
            child: Container(
              padding: const EdgeInsets.fromLTRB(12, 12, 10, 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _hover || widget.renaming ? tint.withValues(alpha: 0.55) : c.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      leading,
                      const SizedBox(width: 10),
                      Expanded(
                        child: widget.renaming
                            ? _RenameField(
                                initial: _title(context, m),
                                original: original ?? '',
                                onDone: widget.onRenamed,
                                onCancel: widget.onCancelRename,
                              )
                            : Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(_title(context, m),
                                      maxLines: _text ? 3 : 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                          fontSize: _text ? 13.5 : 14,
                                          fontWeight: _text ? FontWeight.w500 : FontWeight.w600,
                                          color: c.text,
                                          height: 1.25)),
                                  if (alias != null && original != null)
                                    Text(t.originalName(original),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(fontSize: 11.5, color: c.text2)),
                                  if (tags.isNotEmpty && !_text) ...[
                                    const SizedBox(height: 4),
                                    // One line of tags; the rest is clipped.
                                    SizedBox(
                                      height: 22,
                                      child: ClipRect(
                                        child: Wrap(
                                          spacing: 4,
                                          runSpacing: 4,
                                          children: [
                                            for (final tag in tags.take(3)) TagPill(tag),
                                            if (tags.length > 3)
                                              Text('+${tags.length - 3}', style: TextStyle(fontSize: 12, color: c.text2)),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                      ),
                      if (!widget.renaming) ...[
                        if (fav || _hover)
                          _iconButton(
                            fav ? Icons.star_rounded : Icons.star_outline_rounded,
                            fav ? t.removeFavorite : t.addFavorite,
                            () => _s.toggleFileFavorite(_item.chatId, _item.messageId, _item.kind.name),
                            fav ? c.waitingStrong : c.text2,
                          ),
                        if (!_text && !_media && _hover) _iconButton(Icons.edit_outlined, t.rename, widget.onRename, c.text2),
                        _iconButton(Icons.sell_outlined, t.marks, _openMarks, tags.isEmpty ? c.text2 : tagColor(c, tags.first)),
                      ],
                    ],
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      ChatAvatar(chatOrPlaceholder(_s, _item.chatId, _item.chatTitle), size: 18, showOnline: false),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(_item.chatTitle,
                            maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12, color: c.text2)),
                      ),
                      if (_text && tags.isNotEmpty) ...[
                        const SizedBox(width: 6),
                        TagPill(tags.first),
                      ],
                      if (meta.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        Text(meta, style: TextStyle(fontSize: 12, color: c.text2)),
                      ],
                      const SizedBox(width: 6),
                      Icon(
                        _text || _media || f == null
                            ? Icons.chevron_right
                            : (f.downloaded ? Icons.open_in_new : Icons.download_outlined),
                        size: 15,
                        color: c.text2,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Inline rename: Enter saves, Escape or clicking away cancels; empty
/// restores Telegram's name.
class _RenameField extends StatefulWidget {
  const _RenameField({required this.initial, required this.original, required this.onDone, required this.onCancel});

  final String initial;
  final String original;
  final ValueChanged<String> onDone;
  final VoidCallback onCancel;

  @override
  State<_RenameField> createState() => _RenameFieldState();
}

class _RenameFieldState extends State<_RenameField> {
  late final _ctl = TextEditingController(text: widget.initial);
  final _focus = FocusNode();
  bool _done = false;

  @override
  void initState() {
    super.initState();
    // Select the name without its extension, like Explorer does.
    final dot = widget.initial.lastIndexOf('.');
    _ctl.selection = TextSelection(baseOffset: 0, extentOffset: dot > 0 ? dot : widget.initial.length);
    _focus.addListener(() {
      if (!_focus.hasFocus && !_done) _finish(_ctl.text);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _focus.requestFocus());
  }

  @override
  void dispose() {
    _ctl.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _finish(String value) {
    if (_done) return;
    _done = true;
    final v = value.trim();
    // Same as Telegram's name = no alias.
    widget.onDone(v == widget.original ? '' : v);
  }

  void _cancel() {
    if (_done) return;
    _done = true;
    widget.onCancel();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.fc;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CallbackShortcuts(
          bindings: {const SingleActivator(LogicalKeyboardKey.escape): _cancel},
          child: TextField(
            controller: _ctl,
            focusNode: _focus,
            onSubmitted: _finish,
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: c.text),
            decoration: InputDecoration(
              isDense: true,
              filled: true,
              fillColor: c.bg,
              contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: c.accent)),
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: c.chipBorder)),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: c.accent, width: 1.5)),
            ),
          ),
        ),
        const SizedBox(height: 3),
        Text(context.s.files.renameHint, maxLines: 2, style: TextStyle(fontSize: 10.5, color: c.text2, height: 1.2)),
      ],
    );
  }
}

class _TypeIcon extends StatelessWidget {
  const _TypeIcon({required this.type, required this.tint, required this.downloading, required this.file, this.icon});

  final FileType type;

  /// Overrides the type's icon (quote for saved texts).
  final IconData? icon;
  final Color tint;
  final bool downloading;
  final FileInfo? file;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 44,
      height: 44,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
              decoration: BoxDecoration(color: tint.withValues(alpha: 0.16), borderRadius: BorderRadius.circular(11))),
          if (downloading)
            SizedBox(
              width: 38,
              height: 38,
              child: CircularProgressIndicator(
                value: (file?.progress ?? 0) > 0 ? file!.progress : null,
                strokeWidth: 2.2,
                color: tint,
              ),
            ),
          Icon(icon ?? fileTypeIcon(type), size: 22, color: tint),
        ],
      ),
    );
  }
}

/// Photo or video thumbnail: the preview file, else the blurred mini.
class _Thumb extends StatelessWidget {
  const _Thumb({required this.info, required this.kind, required this.tint});

  final MediaInfo? info;
  final SavedKind kind;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    final path = info?.previewPath;
    final mini = info?.mini;
    return ClipRRect(
      borderRadius: BorderRadius.circular(11),
      child: SizedBox(
        width: 52,
        height: 44,
        child: Stack(
          fit: StackFit.expand,
          alignment: Alignment.center,
          children: [
            if (path != null)
              Image.file(File(path),
                  fit: BoxFit.cover,
                  cacheWidth: 104,
                  errorBuilder: (_, __, ___) => ColoredBox(color: tint.withValues(alpha: 0.16)))
            else if (mini != null)
              Image.memory(mini, fit: BoxFit.cover)
            else
              ColoredBox(color: tint.withValues(alpha: 0.16)),
            if (kind == SavedKind.videos)
              Icon(Icons.play_circle_outline, size: 20, color: Colors.white.withValues(alpha: 0.9))
            else if (path == null && mini == null)
              Icon(Icons.image_outlined, size: 20, color: tint),
          ],
        ),
      ),
    );
  }
}

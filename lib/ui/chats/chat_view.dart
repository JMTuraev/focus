import 'dart:math' as math;

import 'package:desktop_drop/desktop_drop.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/chat_source.dart';
import '../../data/format.dart';
import '../../data/models.dart';
import '../../l10n/l10n.dart';
import '../../state/app_state.dart';
import '../../theme.dart';
import '../calendar/event_editor.dart';
import '../common.dart';
import 'file_actions.dart';
import 'media.dart';
import 'message_text.dart';
import 'send_files_dialog.dart';

class ChatView extends StatefulWidget {
  const ChatView({super.key, required this.state, required this.infoActive, required this.onInfo, this.onBack});

  final AppState state;

  /// Whether the info panel for this chat is currently shown.
  final bool infoActive;
  final VoidCallback onInfo;

  /// Narrow layout: shows a back arrow that returns to the chat list.
  final VoidCallback? onBack;

  @override
  State<ChatView> createState() => _ChatViewState();
}

class _ChatViewState extends State<ChatView> {
  final _input = TextEditingController();
  final _focus = FocusNode();

  /// Own message being edited in the composer (null = writing a new one).
  Message? _editing;
  bool _emojiOpen = false;
  bool _dragging = false;

  AppState get s => widget.state;

  Future<void> _attach() async {
    final files = await pickFiles();
    if (files.isNotEmpty) await _sendFiles(files);
  }

  /// Shows the send dialog for picked or dropped files. Text already typed
  /// in the composer becomes the caption.
  Future<void> _sendFiles(List<OutgoingFile> files) async {
    if (!mounted || files.isEmpty) return;
    final choice = await showSendFilesDialog(context, files, caption: _input.text.trim());
    if (choice == null || !mounted) return;
    if (choice.caption.trim().isNotEmpty) _input.clear();
    try {
      await s.sendFiles(choice.files, caption: choice.caption, compressImages: choice.compressImages);
    } catch (_) {
      if (mounted) _toast(context.s.chats.fileSendFailed);
    }
    _focus.requestFocus();
  }

  void _toggleEmoji() {
    setState(() => _emojiOpen = !_emojiOpen);
    _focus.requestFocus();
  }

  @override
  void dispose() {
    _input.dispose();
    _focus.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _input.text;
    final editing = _editing;
    if (editing != null) {
      await _saveEdit(editing, text);
      return;
    }
    if (text.trim().isEmpty) return;
    _input.clear();
    _focus.requestFocus();
    try {
      await s.send(text);
    } catch (_) {
      if (!mounted) return;
      _input.text = text;
      _toast(context.s.chats.messageSendFailed);
    }
  }

  // ---- editing and deleting ----

  /// Right click on a message: copy, edit (own text, if Telegram allows),
  /// delete. Rights come from TDLib (getMessageProperties).
  Future<void> _messageMenu(Message m, Offset pos) async {
    if (m.pending || m.service) return;
    final chat = s.activeChat;
    if (chat == null) return;
    final t = context.s.chats;
    final c = context.fc;
    var rights = const MessageRights();
    try {
      rights = await s.source.rightsOf(chat.id, m.id);
    } catch (_) {}
    if (!mounted) return;
    final plainText = m.fileName == null && m.info == null && m.media == null;
    final overlay = Overlay.of(context).context.findRenderObject()! as RenderBox;
    PopupMenuItem<String> item(String value, IconData icon, String label, {Color? color}) => PopupMenuItem(
          value: value,
          height: 38,
          child: Row(
            children: [
              Icon(icon, size: 18, color: color ?? c.icon),
              const SizedBox(width: 10),
              Text(label, style: TextStyle(color: color ?? c.text, fontSize: 14)),
            ],
          ),
        );
    final items = [
      if (m.text.isNotEmpty) item('copy', Icons.copy_outlined, t.copyMessage),
      if (rights.canEdit && plainText && chat.canSend) item('edit', Icons.edit_outlined, t.editMessage),
      if (rights.canDelete) item('delete', Icons.delete_outline, t.deleteMessage, color: c.danger),
    ];
    if (items.isEmpty) return;
    final choice = await showMenu<String>(
      context: context,
      color: c.panel,
      position: RelativeRect.fromRect(pos & const Size(1, 1), Offset.zero & overlay.size),
      items: items,
    );
    if (!mounted) return;
    switch (choice) {
      case 'copy':
        await Clipboard.setData(ClipboardData(text: m.text));
        if (mounted) _toast(t.copied);
      case 'edit':
        _startEdit(m);
      case 'delete':
        await _confirmDelete(chat, m, rights);
    }
  }

  void _startEdit(Message m) {
    setState(() {
      _editing = m;
      _emojiOpen = false;
    });
    _input.text = m.text;
    _input.selection = TextSelection.collapsed(offset: m.text.length);
    _focus.requestFocus();
  }

  void _cancelEdit() {
    setState(() => _editing = null);
    _input.clear();
    _focus.requestFocus();
  }

  Future<void> _saveEdit(Message m, String text) async {
    final chat = s.activeChat;
    // Empty or unchanged: nothing to send, like Telegram Desktop.
    if (chat == null || text.trim().isEmpty || text.trim() == m.text.trim()) {
      _cancelEdit();
      return;
    }
    setState(() => _editing = null);
    _input.clear();
    _focus.requestFocus();
    try {
      await s.source.editText(chat.id, m.id, text);
    } catch (_) {
      if (!mounted) return;
      _startEdit(m);
      _input.text = text;
      _toast(context.s.chats.editFailed);
    }
  }

  Future<void> _confirmDelete(Chat chat, Message m, MessageRights rights) async {
    final t = context.s.chats;
    final c = context.fc;
    // Both possible: a checkbox (on by default, like Telegram); else fixed.
    var forAll = rights.canDeleteForAll;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialog) => AlertDialog(
          backgroundColor: c.panel,
          title: Text(t.deleteTitle, style: TextStyle(color: c.text, fontSize: 18, fontWeight: FontWeight.w700)),
          content: SizedBox(
            width: 360,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (m.text.isNotEmpty)
                  Text(m.text, maxLines: 3, overflow: TextOverflow.ellipsis, style: TextStyle(color: c.textSoft, fontSize: 14)),
                if (rights.canDeleteForMe && rights.canDeleteForAll) ...[
                  const SizedBox(height: 8),
                  CheckboxListTile(
                    value: forAll,
                    onChanged: (v) => setDialog(() => forAll = v ?? false),
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                    activeColor: c.accentStrong,
                    title: Text(
                      chat.kind == ChatKind.private ? t.deleteForBoth(chat.name) : t.deleteForAll,
                      style: TextStyle(color: c.text, fontSize: 14),
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              style: TextButton.styleFrom(foregroundColor: c.text2),
              child: Text(context.s.common.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              style: FilledButton.styleFrom(backgroundColor: c.danger, foregroundColor: Colors.white),
              child: Text(context.s.common.delete),
            ),
          ],
        ),
      ),
    );
    if (ok != true || !mounted) return;
    if (_editing?.id == m.id) _cancelEdit();
    try {
      await s.source.deleteMessages(chat.id, [m.id], forAll: forAll);
    } catch (_) {
      if (mounted) _toast(t.deleteFailed);
    }
  }

  void _toast(String text, {String? action, Module? goTo, VoidCallback? onAction}) {
    showToast(
      context,
      (width) => SnackBar(
        persist: false,
        width: width,
        duration: const Duration(seconds: 4),
        content: Text(text, maxLines: 2, overflow: TextOverflow.ellipsis),
        action: action == null ? null : SnackBarAction(label: action, onPressed: onAction ?? () => s.openModule(goTo!)),
      ),
    );
  }

  /// "Kalendarga": a detected meeting is added at once; otherwise the event
  /// editor opens prefilled from the message.
  Future<void> _toCalendar(Message m) async {
    final at = m.meetingAt;
    if (at != null) {
      await s.eventFromMeeting(m);
      if (!mounted) return;
      final t = context.s.chats;
      _toast(t.addedToCalendar(m.meeting ?? ''), action: t.openCalendar, onAction: () => s.showCalendarAt(at));
      return;
    }
    final chat = s.activeChat;
    if (chat == null || !mounted) return;
    var title = m.text.trim().split('\n').first.trim();
    if (title.length > 100) title = '${title.substring(0, 99)}…';
    await showEventEditor(
      context,
      s,
      title: title,
      chatId: chat.id,
      chatTitle: chat.name,
      messageId: m.id,
      messageText: m.text.isEmpty ? null : m.text,
    );
  }

  String _short(String t) => t.length > 42 ? '${t.substring(0, 40)}…' : t;

  /// Messages with a date separator before each new day, grouped into runs
  /// from the same sender (name on the first, avatar on the last, like
  /// Telegram). Mock messages have no date and get one "Bugun" ([today])
  /// separator.
  static List<Object> _items(List<Message> msgs, String today) {
    String? key(Message m) => m.out || m.service ? null : (m.senderId ?? m.from);
    bool sameDay(Message a, Message b) => a.date == null || b.date == null || Fmt.sameDay(a.date!, b.date!);
    bool sameRun(Message a, Message? b) => b != null && key(a) != null && key(a) == key(b) && sameDay(a, b);

    final out = <Object>[];
    DateTime? prev;
    for (var i = 0; i < msgs.length; i++) {
      final m = msgs[i];
      final d = m.date;
      if (d == null) {
        if (i == 0) out.add(today);
      } else if (prev == null || !Fmt.sameDay(prev, d)) {
        out.add(Fmt.dayLabel(d));
        prev = d;
      }
      out.add(_Entry(
        m,
        first: !sameRun(m, i > 0 ? msgs[i - 1] : null),
        last: !sameRun(m, i + 1 < msgs.length ? msgs[i + 1] : null),
      ));
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    final c = context.fc;
    final chat = s.activeChat!;
    final msgs = s.messagesOf(chat.id);
    final t = context.s.chats;
    final items = _items(msgs, context.s.common.today);
    final loadingHistory = s.loadingHistory;
    final target = s.targetMessage;
    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Header(
          chat: chat,
          infoOpen: widget.infoActive,
          onInfo: widget.onInfo,
          onBack: widget.onBack,
          onCall: () => _toast(t.callsOnPhone),
        ),
        _QuickActions(
          label: s.selectedMessageId != null ? t.selectedMessage : t.lastMessageHint,
          text: target?.text ?? '',
          onTask: target == null
              ? null
              : () async {
                  await s.taskFromMessage(target);
                  final what = target.text.isEmpty ? (target.fileName ?? target.mediaLabel ?? t.messageLower) : target.text;
                  _toast(t.taskCreated(_short(what)), action: t.goToTasks, goTo: Module.tasks);
                },
          onCalendar: target == null ? null : () => _toCalendar(target),
          onNote: target == null
              ? null
              : () async {
                  await s.noteFromMessage(target);
                  final what = target.text.isEmpty ? (target.fileName ?? target.mediaLabel ?? t.messageLower) : target.text;
                  _toast(t.savedToNotes(_short(what)), action: t.openNotes, goTo: Module.notes);
                },
          onFiles: target == null
              ? null
              : () {
                  final added = s.saveToFiles(target);
                  final what = target.text.isEmpty ? (target.fileName ?? target.mediaLabel ?? t.messageLower) : target.text;
                  _toast(added ? t.savedToFiles(_short(what)) : t.alreadyInFiles, action: t.openFiles, goTo: Module.files);
                },
        ),
        Expanded(
          child: CustomPaint(
            painter: WallpaperPainter.of(c),
            child: LayoutBuilder(
              builder: (context, box) {
                final narrow = box.maxWidth < 600;
                final bubbleMax = math.min(460.0, box.maxWidth * (narrow ? 0.86 : 0.75));
                if (msgs.isEmpty) {
                  return Center(
                    child: loadingHistory
                        ? SizedBox(width: 26, height: 26, child: CircularProgressIndicator(strokeWidth: 2.6, color: c.accent))
                        : _DatePill(t.noMessages),
                  );
                }
                final groupStyle = chat.kind == ChatKind.group || msgs.any((m) => m.from != null && !m.out);
                return NotificationListener<ScrollNotification>(
                  // Older messages load when the top of the history comes close.
                  onNotification: (n) {
                    if (n.metrics.extentAfter < 600) s.loadOlder();
                    return false;
                  },
                  // Text can be selected and copied across messages.
                  child: SelectionArea(
                  child: ListView.builder(
                  reverse: true,
                  padding: EdgeInsets.symmetric(horizontal: narrow ? 10 : 22, vertical: 12),
                  itemCount: items.length + (loadingHistory ? 1 : 0),
                  itemBuilder: (_, i) {
                    if (i == items.length) {
                      return Padding(
                        padding: const EdgeInsets.all(12),
                        child: Center(
                          child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.2, color: c.accent)),
                        ),
                      );
                    }
                    final item = items[items.length - 1 - i];
                    if (item is String) return _DatePill(item);
                    final e = item as _Entry;
                    final m = e.m;
                    if (m.service) return _DatePill(m.text);
                    return _Bubble(
                      message: m,
                      state: s,
                      maxWidth: bubbleMax,
                      groupStyle: groupStyle,
                      first: e.first,
                      last: e.last,
                      selected: s.selectedMessageId == m.id,
                      onTap: () => s.selectMessage(m.id),
                      onMenu: (pos) => _messageMenu(m, pos),
                      onAddMeeting: () => _toCalendar(m),
                    );
                  },
                  ),
                  ),
                );
              },
            ),
          ),
        ),
        if (chat.canSend) ...[
          if (_emojiOpen) _EmojiPanel(controller: _input, onPicked: () => _focus.requestFocus()),
          _Composer(
            controller: _input,
            focus: _focus,
            onSend: _send,
            onAttach: _attach,
            emojiOpen: _emojiOpen,
            onEmoji: _toggleEmoji,
            editing: _editing?.text,
            onCancelEdit: _cancelEdit,
            onEscape: _emojiOpen ? () => setState(() => _emojiOpen = false) : (_editing != null ? _cancelEdit : null),
          ),
        ] else
          _ReadOnlyBar(channel: chat.kind == ChatKind.channel),
      ],
    );
    if (!chat.canSend) return body;
    // Files dragged from Explorer open the send dialog.
    return DropTarget(
      onDragEntered: (_) => setState(() => _dragging = true),
      onDragExited: (_) => setState(() => _dragging = false),
      onDragDone: (d) {
        setState(() => _dragging = false);
        _sendFiles(outgoingFiles(d.files.map((f) => f.path)));
      },
      child: Stack(
        children: [
          Positioned.fill(child: body),
          if (_dragging) const Positioned.fill(child: _DropOverlay()),
        ],
      ),
    );
  }
}

class _DropOverlay extends StatelessWidget {
  const _DropOverlay();

  @override
  Widget build(BuildContext context) {
    final c = context.fc;
    return IgnorePointer(
      child: Container(
        color: c.panel.withValues(alpha: 0.86),
        padding: const EdgeInsets.all(18),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: c.accent, width: 2),
          ),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.upload_file, size: 44, color: c.accent),
                const SizedBox(height: 10),
                Text(context.s.chats.dropFiles,
                    style: TextStyle(color: c.text, fontSize: 16, fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(context.s.chats.dropFilesHint, style: TextStyle(color: c.text2, fontSize: 13)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Emoji picker above the composer; inserts at the cursor.
class _EmojiPanel extends StatelessWidget {
  const _EmojiPanel({required this.controller, required this.onPicked});

  final TextEditingController controller;
  final VoidCallback onPicked;

  @override
  Widget build(BuildContext context) {
    final c = context.fc;
    return Container(
      height: 280,
      decoration: BoxDecoration(color: c.panel, border: Border(top: BorderSide(color: c.border))),
      child: EmojiPicker(
        textEditingController: controller,
        onEmojiSelected: (_, __) => onPicked(),
        config: Config(
          height: 280,
          checkPlatformCompatibility: false,
          locale: Localizations.localeOf(context),
          emojiTextStyle: const TextStyle(fontFamily: 'Twemoji', fontFamilyFallback: ['Segoe UI Emoji']),
          emojiViewConfig: EmojiViewConfig(
            columns: 10,
            emojiSizeMax: 26,
            backgroundColor: c.panel,
            noRecents: Text(context.s.chats.noRecentEmoji, style: TextStyle(color: c.text2, fontSize: 13)),
            buttonMode: ButtonMode.MATERIAL,
          ),
          categoryViewConfig: CategoryViewConfig(
            backgroundColor: c.panel,
            indicatorColor: c.accent,
            iconColor: c.text2,
            iconColorSelected: c.accent,
            backspaceColor: c.accent,
            dividerColor: c.border,
          ),
          bottomActionBarConfig: const BottomActionBarConfig(enabled: false),
          searchViewConfig: SearchViewConfig(
            backgroundColor: c.panel,
            buttonIconColor: c.text2,
            hintText: context.s.chats.emojiSearch,
          ),
          skinToneConfig: SkinToneConfig(dialogBackgroundColor: c.panel, indicatorColor: c.text2),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.chat, required this.infoOpen, required this.onInfo, required this.onCall, this.onBack});

  final Chat chat;
  final bool infoOpen;
  final VoidCallback onInfo;
  final VoidCallback onCall;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final c = context.fc;
    return Container(
      height: 56,
      padding: EdgeInsets.only(left: onBack != null ? 4 : 16, right: 10),
      decoration: BoxDecoration(color: c.panel, border: Border(bottom: BorderSide(color: c.border))),
      child: Row(
        children: [
          if (onBack != null)
            IconButton(tooltip: context.s.common.back, onPressed: onBack, icon: Icon(Icons.arrow_back, size: 20, color: c.icon)),
          ChatAvatar(chat, size: 40, showOnline: false),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(chat.name,
                    maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: c.text)),
                Text(chat.typing.isNotEmpty ? chat.typing : chat.status,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12.5, color: chat.online || chat.typing.isNotEmpty ? c.accentText : c.text2)),
              ],
            ),
          ),
          IconButton(tooltip: context.s.chats.call, onPressed: onCall, icon: Icon(Icons.call_outlined, size: 20, color: c.icon)),
          IconButton(
            tooltip: context.s.chats.infoPanel,
            onPressed: onInfo,
            isSelected: infoOpen,
            icon: Icon(Icons.info_outline, size: 20, color: c.icon),
            selectedIcon: Icon(Icons.info, size: 20, color: c.accentText),
          ),
        ],
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions({required this.label, required this.text, this.onTask, this.onCalendar, this.onNote, this.onFiles});

  final String label;
  final String text;
  final VoidCallback? onTask;
  final VoidCallback? onCalendar;
  final VoidCallback? onNote;
  final VoidCallback? onFiles;

  @override
  Widget build(BuildContext context) {
    final c = context.fc;
    return LayoutBuilder(
      builder: (context, box) {
        // Below ~640 px the buttons collapse to icons with tooltips.
        final iconsOnly = box.maxWidth < 640;
        return Container(
          height: 48,
          padding: const EdgeInsets.only(left: 16, right: 12),
          decoration: BoxDecoration(color: c.panel, border: Border(bottom: BorderSide(color: c.border))),
          child: Row(
            children: [
              Icon(Icons.auto_awesome_outlined, size: 18, color: c.accent),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: c.accentText)),
                    Text(text, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 13, color: c.textSoft)),
                  ],
                ),
              ),
              _QA(icon: Icons.checklist, label: context.s.chats.toTask, iconOnly: iconsOnly, onTap: onTask),
              _QA(icon: Icons.calendar_today_outlined, label: context.s.chats.toCalendar, iconOnly: iconsOnly, onTap: onCalendar),
              _QA(icon: Icons.sticky_note_2_outlined, label: context.s.chats.toNote, iconOnly: iconsOnly, onTap: onNote),
              _QA(icon: Icons.bookmark_add_outlined, label: context.s.chats.toFiles, iconOnly: iconsOnly, onTap: onFiles),
            ],
          ),
        );
      },
    );
  }
}

class _QA extends StatelessWidget {
  const _QA({required this.icon, required this.label, this.iconOnly = false, this.onTap});

  final IconData icon;
  final String label;
  final bool iconOnly;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.fc;
    Widget button = Tap(
      onTap: onTap,
      radius: 8,
      color: c.qaBg,
      hover: c.qaHover,
      border: Border.all(color: c.qaBorder),
      child: Container(
        height: 32,
        padding: EdgeInsets.symmetric(horizontal: iconOnly ? 8 : 12),
        child: Row(
          children: [
            Icon(icon, size: 16, color: c.qaFg),
            if (!iconOnly) ...[
              const SizedBox(width: 6),
              Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: c.qaFg)),
            ],
          ],
        ),
      ),
    );
    if (iconOnly) button = Tooltip(message: label, child: button);
    return Padding(padding: EdgeInsets.only(left: iconOnly ? 6 : 8), child: button);
  }
}

class _DatePill extends StatelessWidget {
  const _DatePill(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
        decoration: BoxDecoration(color: context.fc.datePill, borderRadius: BorderRadius.circular(12)),
        child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.w600)),
      ),
    );
  }
}

/// One message in the list with its place in a run from the same sender.
class _Entry {
  const _Entry(this.m, {required this.first, required this.last});

  final Message m;

  /// First of the run: shows the sender name.
  final bool first;

  /// Last of the run: shows the sender avatar.
  final bool last;
}

class _Bubble extends StatelessWidget {
  const _Bubble({
    required this.message,
    required this.state,
    required this.maxWidth,
    required this.selected,
    required this.onTap,
    this.onMenu,
    required this.onAddMeeting,
    this.groupStyle = false,
    this.first = true,
    this.last = true,
  });

  final Message message;
  final AppState state;
  final double maxWidth;
  final bool selected;
  final VoidCallback onTap;

  /// Right click: copy, edit, delete.
  final void Function(Offset globalPosition)? onMenu;
  final VoidCallback onAddMeeting;

  /// Group chat: avatar column and colored sender names.
  final bool groupStyle;
  final bool first;
  final bool last;

  static const _avatar = 34.0;

  /// Mock messages have no sender id: derive a stable color from the name.
  int get _colorIndex => message.senderId != null ? message.senderColor : (message.from ?? '').codeUnits.fold(0, (a, b) => a + b) % 7;

  @override
  Widget build(BuildContext context) {
    final c = context.fc;
    final m = message;
    final info = m.info;
    final sticker = info?.kind == MediaKind.sticker;
    // Photos, videos, GIFs and round videos without a caption float without
    // a bubble, like in Telegram; the time sits on the picture.
    final round = info?.kind == MediaKind.videoNote;
    final bareMedia = info != null &&
        const {MediaKind.photo, MediaKind.video, MediaKind.gif, MediaKind.videoNote}.contains(info.kind) &&
        m.text.isEmpty &&
        m.fileName == null;
    final showAvatarColumn = groupStyle && !m.out;
    final width = showAvatarColumn ? maxWidth - _avatar - 8 : maxWidth;
    final radius = BorderRadius.only(
      topLeft: const Radius.circular(14),
      topRight: const Radius.circular(14),
      bottomLeft: Radius.circular(m.out || !last ? 14 : 5),
      bottomRight: Radius.circular(m.out && last ? 5 : 14),
    );
    final metaColor = sticker || bareMedia ? Colors.white : (m.out ? c.outMeta : c.text2);
    final meta = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (m.edited)
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: Text(context.s.chats.edited,
                style: TextStyle(fontSize: 11.5, fontStyle: FontStyle.italic, color: metaColor)),
          ),
        Text(m.time,
            style: TextStyle(fontSize: 11.5, color: sticker || bareMedia ? Colors.white : (m.out ? c.outMeta : c.text2))),
        if (m.out) ...[const SizedBox(width: 3), _Tick(m, onMedia: sticker || bareMedia)],
      ],
    );

    final Widget content;
    if (bareMedia) {
      final pill = Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
        decoration: BoxDecoration(color: const Color(0x8C000000), borderRadius: BorderRadius.circular(8)),
        child: meta,
      );
      content = Column(
        crossAxisAlignment: m.out ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (m.from != null && first)
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 3),
              child: Text(
                m.from!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: c.senderName(_colorIndex)),
              ),
            ),
          DecoratedBox(
            position: DecorationPosition.foreground,
            decoration: selected
                ? BoxDecoration(
                    shape: round ? BoxShape.circle : BoxShape.rectangle,
                    borderRadius: round ? null : BorderRadius.circular(10),
                    border: Border.all(color: c.accent, width: 2),
                  )
                : const BoxDecoration(),
            child: Stack(
              children: [
                MessageMedia(message: m, state: state, maxWidth: width),
                if (!round) Positioned(right: 6, bottom: 10, child: pill),
              ],
            ),
          ),
          if (round) Padding(padding: const EdgeInsets.only(top: 2), child: pill),
        ],
      );
    } else if (sticker) {
      // Stickers float without a bubble, like in Telegram.
      content = Column(
        crossAxisAlignment: m.out ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          MessageMedia(message: m, state: state, maxWidth: width),
          Container(
            margin: const EdgeInsets.only(top: 2),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
            decoration: BoxDecoration(color: c.datePill, borderRadius: BorderRadius.circular(8)),
            child: meta,
          ),
        ],
      );
    } else {
      content = Container(
        padding: const EdgeInsets.fromLTRB(12, 7, 10, 6),
        decoration: BoxDecoration(
          color: m.out ? c.outBubble : c.inBubble,
          borderRadius: radius,
          border: selected ? Border.all(color: c.accent, width: 2) : null,
          boxShadow: [BoxShadow(color: c.bubbleShadow, blurRadius: 1, offset: const Offset(0, 1))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (m.from != null && first)
              Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Text(
                  m.from!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: c.senderName(_colorIndex)),
                ),
              ),
            if (m.fileName != null) FileRow(message: m, state: state),
            if (info != null)
              MessageMedia(message: m, state: state, maxWidth: width - 22)
            else if (m.media != null)
              _MediaRow(kind: m.media!, label: m.mediaLabel ?? ''),
            Wrap(
              alignment: WrapAlignment.end,
              crossAxisAlignment: WrapCrossAlignment.end,
              spacing: 12,
              children: [
                if (m.text.isNotEmpty)
                  MessageText(m.text, entities: m.entities, style: TextStyle(fontSize: 14.5, height: 1.42, color: c.text)),
                Padding(padding: const EdgeInsets.only(bottom: 1), child: meta),
              ],
            ),
          ],
        ),
      );
    }

    final bubble = ConstrainedBox(
      constraints: BoxConstraints(maxWidth: width),
      child: GestureDetector(
        onTap: onTap,
        onSecondaryTapDown: onMenu == null ? null : (d) => onMenu?.call(d.globalPosition),
        child: MouseRegion(cursor: SystemMouseCursors.click, child: content),
      ),
    );

    return Padding(
      padding: EdgeInsets.only(top: first ? 3 : 1, bottom: last ? 3 : 1),
      child: Column(
        crossAxisAlignment: m.out ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          if (showAvatarColumn)
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                SizedBox(
                  width: _avatar,
                  child: last
                      ? Avatar(
                          initials: m.senderInitials.isNotEmpty ? m.senderInitials : Fmt.initials(m.from ?? '?'),
                          color: Fmt.avatarColors[_colorIndex % Fmt.avatarColors.length],
                          size: _avatar,
                          photo: m.senderPhoto,
                        )
                      : null,
                ),
                const SizedBox(width: 8),
                Flexible(child: bubble),
              ],
            )
          else
            bubble,
          if (m.meeting != null)
            Container(
              margin: const EdgeInsets.only(top: 6),
              padding: const EdgeInsets.fromLTRB(10, 5, 5, 5),
              decoration: BoxDecoration(color: c.meetingBg, borderRadius: BorderRadius.circular(12)),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.event_outlined, size: 15, color: c.accentText),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text.rich(
                      TextSpan(children: [
                        TextSpan(text: context.s.chats.meetingFound),
                        TextSpan(text: m.meeting, style: const TextStyle(fontWeight: FontWeight.w700)),
                      ]),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12.5, color: c.textSoft),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: onAddMeeting,
                    style: FilledButton.styleFrom(
                      backgroundColor: c.accentStrong,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(0, 28),
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(7)),
                      textStyle: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
                    ),
                    child: Text(context.s.chats.toCalendar),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _Composer extends StatelessWidget {
  const _Composer({
    required this.controller,
    required this.focus,
    required this.onSend,
    required this.onAttach,
    required this.emojiOpen,
    required this.onEmoji,
    this.onEscape,
    this.editing,
    this.onCancelEdit,
  });

  /// Text of the message being edited; shows the "Tahrirlash" bar.
  final String? editing;
  final VoidCallback? onCancelEdit;

  final TextEditingController controller;
  final FocusNode focus;
  final VoidCallback onSend;
  final VoidCallback onAttach;
  final bool emojiOpen;
  final VoidCallback onEmoji;

  /// Closes the emoji panel (null when it is closed).
  final VoidCallback? onEscape;

  @override
  Widget build(BuildContext context) {
    final c = context.fc;
    final field = TextField(
      controller: controller,
      focusNode: focus,
      onSubmitted: (_) => onSend(),
      style: TextStyle(fontSize: 14.5, color: c.text),
      decoration: InputDecoration(
        hintText: context.s.chats.messageHint,
        hintStyle: TextStyle(color: c.text2),
        border: InputBorder.none,
      ),
    );
    final editing = this.editing;
    final row = Container(
      height: 58,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: c.panel,
        border: editing == null ? Border(top: BorderSide(color: c.border)) : null,
      ),
      child: Row(
        children: [
          IconButton(tooltip: context.s.chats.attachFile, onPressed: onAttach, icon: Icon(Icons.attach_file, color: c.icon)),
          Expanded(
            child: onEscape == null
                ? field
                : CallbackShortcuts(
                    bindings: {const SingleActivator(LogicalKeyboardKey.escape): onEscape!},
                    child: field,
                  ),
          ),
          IconButton(
            tooltip: emojiOpen ? context.s.chats.closeEmoji : context.s.chats.emoji,
            onPressed: onEmoji,
            icon: Icon(emojiOpen ? Icons.keyboard_alt_outlined : Icons.emoji_emotions_outlined,
                color: emojiOpen ? c.accent : c.icon),
          ),
          IconButton(
            tooltip: editing == null ? context.s.common.send : context.s.common.save,
            onPressed: onSend,
            icon: Icon(editing == null ? Icons.send_rounded : Icons.check_rounded, color: c.accent),
          ),
        ],
      ),
    );
    if (editing == null) return row;
    // "Tahrirlash" bar: what is being edited; the cross cancels (also Escape).
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(16, 6, 8, 2),
          decoration: BoxDecoration(color: c.panel, border: Border(top: BorderSide(color: c.border))),
          child: Row(
            children: [
              Icon(Icons.edit_outlined, size: 20, color: c.accent),
              const SizedBox(width: 12),
              Container(width: 2, height: 32, color: c.accent),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(context.s.chats.editing,
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: c.accentText)),
                    Text(editing,
                        maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 13, color: c.textSoft)),
                  ],
                ),
              ),
              IconButton(
                tooltip: context.s.chats.cancelEdit,
                onPressed: onCancelEdit,
                icon: Icon(Icons.close, size: 20, color: c.icon),
              ),
            ],
          ),
        ),
        row,
      ],
    );
  }
}

/// Delivery mark for outgoing messages: sending, failed, sent, read.
class _Tick extends StatelessWidget {
  const _Tick(this.m, {this.onMedia = false});

  final Message m;

  /// White, on a picture (bubble-less media and stickers).
  final bool onMedia;

  @override
  Widget build(BuildContext context) {
    final c = context.fc;
    final t = context.s.chats;
    final meta = onMedia ? Colors.white : c.outMeta;
    final (icon, color, tip) = m.failed
        ? (Icons.error_outline, c.danger, t.tickFailed)
        : m.pending
            ? (Icons.schedule, meta, t.tickSending)
            : m.read
                ? (Icons.done_all, meta, t.tickRead)
                : (Icons.done, meta, t.tickSent);
    return Tooltip(message: tip, child: Icon(icon, size: 15, color: color));
  }
}

/// Photo, voice, sticker... shown as an icon and a label for now
/// (previews and players come later).
class _MediaRow extends StatelessWidget {
  const _MediaRow({required this.kind, required this.label});

  final MediaKind kind;
  final String label;

  static IconData _icon(MediaKind k) => switch (k) {
        MediaKind.photo => Icons.image_outlined,
        MediaKind.video => Icons.videocam_outlined,
        MediaKind.gif => Icons.gif_box_outlined,
        MediaKind.sticker => Icons.emoji_emotions_outlined,
        MediaKind.voice => Icons.mic_none,
        MediaKind.videoNote => Icons.radio_button_checked,
        MediaKind.audio => Icons.music_note_outlined,
        MediaKind.location => Icons.place_outlined,
        MediaKind.contact => Icons.person_outline,
        MediaKind.poll => Icons.poll_outlined,
        MediaKind.call => Icons.call_outlined,
        MediaKind.other => Icons.attachment,
      };

  @override
  Widget build(BuildContext context) {
    final c = context.fc;
    return Padding(
      padding: const EdgeInsets.only(top: 2, bottom: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(color: c.accentSoft, shape: BoxShape.circle),
            child: Icon(_icon(kind), size: 19, color: c.accentText),
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Text(label, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: c.text)),
          ),
        ],
      ),
    );
  }
}

/// Chat area before any chat is selected (Telegram's "Select a chat").
class NoChatPlaceholder extends StatelessWidget {
  const NoChatPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: WallpaperPainter.of(context.fc),
      child: Center(child: _DatePill(context.s.chats.selectChat)),
    );
  }
}

/// Replaces the composer where we cannot write (channels, restricted groups).
class _ReadOnlyBar extends StatelessWidget {
  const _ReadOnlyBar({required this.channel});

  final bool channel;

  @override
  Widget build(BuildContext context) {
    final c = context.fc;
    return Container(
      height: 58,
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(color: c.panel, border: Border(top: BorderSide(color: c.border))),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(channel ? Icons.campaign_outlined : Icons.lock_outline, size: 18, color: c.text2),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              channel ? context.s.chats.channelReadOnly : context.s.chats.groupNoRights,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 14, color: c.text2),
            ),
          ),
        ],
      ),
    );
  }
}

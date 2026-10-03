import 'package:flutter/material.dart';

import '../../data/models.dart';
import '../../state/app_state.dart';
import '../../theme.dart';
import '../common.dart';

class ChatView extends StatefulWidget {
  const ChatView({super.key, required this.state});

  final AppState state;

  @override
  State<ChatView> createState() => _ChatViewState();
}

class _ChatViewState extends State<ChatView> {
  final _input = TextEditingController();
  final _focus = FocusNode();

  AppState get s => widget.state;

  @override
  void dispose() {
    _input.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _send() {
    s.send(_input.text);
    _input.clear();
    _focus.requestFocus();
  }

  void _toast(String text, {String? action, Module? goTo}) {
    final m = ScaffoldMessenger.of(context);
    m.hideCurrentSnackBar();
    m.showSnackBar(SnackBar(
      width: 560,
      duration: const Duration(seconds: 4),
      content: Text(text, maxLines: 2, overflow: TextOverflow.ellipsis),
      action: action == null ? null : SnackBarAction(label: action, onPressed: () => s.openModule(goTo!)),
    ));
  }

  String _short(String t) => t.length > 42 ? '${t.substring(0, 40)}…' : t;

  @override
  Widget build(BuildContext context) {
    final chat = s.activeChat;
    final msgs = s.messagesOf(chat.id);
    final target = s.targetMessage;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Header(chat: chat, infoOpen: s.infoOpen, onInfo: s.toggleInfo, onCall: () => _toast('Qo‘ng‘iroqlar telefon ilovasida qoladi')),
        _QuickActions(
          label: s.selectedMessageId != null ? 'Tanlangan xabar' : 'Oxirgi xabar · boshqasini tanlash uchun xabarni bosing',
          text: target?.text ?? '',
          onTask: target == null
              ? null
              : () => _toast('Vazifa yaratildi: “${_short(target.text)}”', action: 'Vazifalarga o‘tish', goTo: Module.tasks),
          onCalendar: target == null
              ? null
              : () => _toast(
                    target.meeting != null ? 'Kalendarga qo‘shildi: ${target.meeting}' : 'Kalendarga qoralama: “${_short(target.text)}”',
                    action: 'Kalendarni ochish',
                    goTo: Module.calendar,
                  ),
          onNote: target == null
              ? null
              : () => _toast('Eslatmaga saqlandi: “${_short(target.text)}”', action: 'Eslatmalarni ochish', goTo: Module.notes),
        ),
        Expanded(
          child: CustomPaint(
            painter: const WallpaperPainter(),
            child: ListView.builder(
              reverse: true,
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
              itemCount: msgs.length + 1,
              itemBuilder: (_, i) {
                if (i == msgs.length) return const _DatePill('Bugun');
                final m = msgs[msgs.length - 1 - i];
                return _Bubble(
                  message: m,
                  selected: s.selectedMessageId == m.id,
                  onTap: () => s.selectMessage(m.id),
                  onAddMeeting: () => _toast('Kalendarga qo‘shildi: ${m.meeting}', action: 'Kalendarni ochish', goTo: Module.calendar),
                );
              },
            ),
          ),
        ),
        _Composer(controller: _input, focus: _focus, onSend: _send, onAttach: () => _toast('Fayl tanlash 1-bosqichda ulanadi')),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.chat, required this.infoOpen, required this.onInfo, required this.onCall});

  final Chat chat;
  final bool infoOpen;
  final VoidCallback onInfo;
  final VoidCallback onCall;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      padding: const EdgeInsets.only(left: 16, right: 10),
      decoration: const BoxDecoration(color: FC.panel, border: Border(bottom: BorderSide(color: FC.border))),
      child: Row(
        children: [
          Avatar(initials: chat.initials, color: chat.color, size: 40),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(chat.name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                Text(chat.status, style: TextStyle(fontSize: 12.5, color: chat.online ? FC.accentStrong : FC.text2)),
              ],
            ),
          ),
          IconButton(tooltip: 'Qo‘ng‘iroq', onPressed: onCall, icon: const Icon(Icons.call_outlined, size: 20, color: FC.icon)),
          IconButton(
            tooltip: 'Ma’lumot paneli',
            onPressed: onInfo,
            isSelected: infoOpen,
            icon: const Icon(Icons.info_outline, size: 20, color: FC.icon),
            selectedIcon: const Icon(Icons.info, size: 20, color: FC.accentStrong),
          ),
        ],
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions({required this.label, required this.text, this.onTask, this.onCalendar, this.onNote});

  final String label;
  final String text;
  final VoidCallback? onTask;
  final VoidCallback? onCalendar;
  final VoidCallback? onNote;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      padding: const EdgeInsets.only(left: 16, right: 12),
      decoration: const BoxDecoration(color: FC.panel, border: Border(bottom: BorderSide(color: FC.border))),
      child: Row(
        children: [
          const Icon(Icons.auto_awesome_outlined, size: 18, color: FC.accent),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: FC.accentStrong)),
                Text(text, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13, color: Color(0xFF3A4048))),
              ],
            ),
          ),
          _QA(icon: Icons.checklist, label: 'Vazifa qilish', onTap: onTask),
          _QA(icon: Icons.calendar_today_outlined, label: 'Kalendarga', onTap: onCalendar),
          _QA(icon: Icons.sticky_note_2_outlined, label: 'Eslatmaga', onTap: onNote),
        ],
      ),
    );
  }
}

class _QA extends StatelessWidget {
  const _QA({required this.icon, required this.label, this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: Tap(
        onTap: onTap,
        radius: 8,
        color: const Color(0xFFF3F8FE),
        hover: const Color(0xFFE1EDFB),
        border: Border.all(color: const Color(0xFFCFE0F3)),
        child: Container(
          height: 32,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              Icon(icon, size: 16, color: const Color(0xFF1E5FA6)),
              const SizedBox(width: 6),
              Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1E5FA6))),
            ],
          ),
        ),
      ),
    );
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
        decoration: BoxDecoration(color: const Color(0x6B283C1E), borderRadius: BorderRadius.circular(12)),
        child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.w600)),
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.message, required this.selected, required this.onTap, required this.onAddMeeting});

  final Message message;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback onAddMeeting;

  @override
  Widget build(BuildContext context) {
    final m = message;
    final radius = BorderRadius.only(
      topLeft: const Radius.circular(14),
      topRight: const Radius.circular(14),
      bottomLeft: Radius.circular(m.out ? 14 : 5),
      bottomRight: Radius.circular(m.out ? 5 : 14),
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Column(
        crossAxisAlignment: m.out ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: GestureDetector(
              onTap: onTap,
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(12, 7, 10, 6),
                  decoration: BoxDecoration(
                    color: m.out ? FC.outBubble : Colors.white,
                    borderRadius: radius,
                    border: selected ? Border.all(color: FC.accent, width: 2) : null,
                    boxShadow: const [BoxShadow(color: Color(0x24203214), blurRadius: 1, offset: Offset(0, 1))],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (m.from != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 2),
                          child: Text(m.from!, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: FC.accentStrong)),
                        ),
                      if (m.fileName != null) _FileRow(name: m.fileName!, meta: m.fileMeta ?? ''),
                      Wrap(
                        alignment: WrapAlignment.end,
                        crossAxisAlignment: WrapCrossAlignment.end,
                        spacing: 12,
                        children: [
                          SelectableText(m.text, style: const TextStyle(fontSize: 14.5, height: 1.42, color: FC.text), onTap: onTap),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 1),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(m.time, style: TextStyle(fontSize: 11.5, color: m.out ? FC.outMeta : FC.text2)),
                                if (m.out) ...[const SizedBox(width: 3), const Icon(Icons.done_all, size: 15, color: FC.outMeta)],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (m.meeting != null)
            Container(
              margin: const EdgeInsets.only(top: 6),
              padding: const EdgeInsets.fromLTRB(10, 5, 5, 5),
              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.94), borderRadius: BorderRadius.circular(12)),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.event_outlined, size: 15, color: FC.accentStrong),
                  const SizedBox(width: 8),
                  Text.rich(TextSpan(children: [
                    const TextSpan(text: 'Uchrashuv aniqlandi: '),
                    TextSpan(text: m.meeting, style: const TextStyle(fontWeight: FontWeight.w700)),
                  ]), style: const TextStyle(fontSize: 12.5, color: Color(0xFF3A4048))),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: onAddMeeting,
                    style: FilledButton.styleFrom(
                      backgroundColor: FC.accentStrong,
                      minimumSize: const Size(0, 28),
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(7)),
                      textStyle: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
                    ),
                    child: const Text('Kalendarga'),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _FileRow extends StatelessWidget {
  const _FileRow({required this.name, required this.meta});

  final String name;
  final String meta;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 2, bottom: 6),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: const BoxDecoration(color: FC.accent, shape: BoxShape.circle),
            child: const Icon(Icons.insert_drive_file_outlined, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                Text(meta, style: const TextStyle(fontSize: 12.5, color: FC.text2)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Composer extends StatelessWidget {
  const _Composer({required this.controller, required this.focus, required this.onSend, required this.onAttach});

  final TextEditingController controller;
  final FocusNode focus;
  final VoidCallback onSend;
  final VoidCallback onAttach;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 58,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: const BoxDecoration(color: FC.panel, border: Border(top: BorderSide(color: FC.border))),
      child: Row(
        children: [
          IconButton(tooltip: 'Fayl biriktirish', onPressed: onAttach, icon: const Icon(Icons.attach_file, color: FC.icon)),
          Expanded(
            child: TextField(
              controller: controller,
              focusNode: focus,
              onSubmitted: (_) => onSend(),
              style: const TextStyle(fontSize: 14.5),
              decoration: const InputDecoration(
                hintText: 'Xabar yozing…',
                hintStyle: TextStyle(color: FC.text2),
                border: InputBorder.none,
              ),
            ),
          ),
          IconButton(tooltip: 'Yuborish', onPressed: onSend, icon: const Icon(Icons.send_rounded, color: FC.accent)),
        ],
      ),
    );
  }
}

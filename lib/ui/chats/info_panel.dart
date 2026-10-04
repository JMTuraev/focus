import 'package:flutter/material.dart';

import '../../state/app_state.dart';
import '../../theme.dart';
import '../collections/collection_dialogs.dart';
import '../common.dart';

class InfoPanel extends StatelessWidget {
  const InfoPanel({super.key, required this.state, required this.onClose, this.width = 320});

  final AppState state;
  final VoidCallback onClose;

  /// 320 when docked or sliding over the chat; `double.infinity` in the
  /// narrow (one-column) layout.
  final double width;

  @override
  Widget build(BuildContext context) {
    final c = context.fc;
    final chat = state.activeChat;
    if (chat == null) return SizedBox(width: width.isFinite ? width : null);
    final current = state.collectionOf(chat);
    // Phone and bio/description are fetched once per chat when the panel shows.
    WidgetsBinding.instance.addPostFrameCallback((_) => state.loadDetails(chat.id));
    final accentLabel = TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: c.accentText);
    return Container(
      width: width,
      decoration: BoxDecoration(
        color: c.panel,
        border: width.isFinite ? Border(left: BorderSide(color: c.border)) : null,
      ),
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          Container(
            height: 56,
            padding: const EdgeInsets.only(left: 18, right: 8),
            decoration: BoxDecoration(border: Border(bottom: BorderSide(color: c.border))),
            child: Row(
              children: [
                Expanded(
                    child:
                        Text('Ma’lumot', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: c.text))),
                IconButton(
                    tooltip: 'Panelni yopish', onPressed: onClose, icon: Icon(Icons.close, size: 18, color: c.icon)),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Center(child: ChatAvatar(chat, size: 88, showOnline: false)),
          const SizedBox(height: 10),
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                chat.name,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: c.text),
              ),
            ),
          ),
          Center(child: Text(chat.status, style: TextStyle(fontSize: 13, color: chat.online ? c.accentText : c.text2))),
          const SizedBox(height: 12),
          if (chat.phone.isNotEmpty) _Row(icon: Icons.call_outlined, title: chat.phone, subtitle: 'Telefon'),
          if (chat.about.isNotEmpty) _Row(icon: Icons.info_outline, title: chat.about, subtitle: 'Izoh'),
          const SizedBox(height: 8),
          Container(height: 8, color: c.bg),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('To‘plam', style: accentLabel),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final col in state.collections)
                      _TagChip(
                        label: col.label,
                        active: current == col.id,
                        onTap: () {
                          // Tapping the current collection takes the chat out of it.
                          final target = current == col.id ? '' : col.id;
                          state.moveToCollection(chat.id, target);
                          showToast(
                            context,
                            (w) => SnackBar(
                              width: w < 480 ? w : 480,
                              content: Text(target.isEmpty
                                  ? '${chat.name} «${col.label}» to‘plamidan chiqarildi'
                                  : '${chat.name} → ${col.label} to‘plamiga ko‘chirildi'),
                            ),
                          );
                        },
                      ),
                    _TagChip(
                      label: '+ Yangi',
                      active: false,
                      onTap: () async {
                        final created = await showCollectionEditor(context, state);
                        if (created != null) state.moveToCollection(chat.id, created.id);
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(height: 8, color: c.bg),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 6),
            child: Text('Shu chatdan', style: accentLabel),
          ),
          _Link(
            icon: Icons.checklist,
            label: 'Vazifalar',
            count: state.tasks.openForChat(chat.id),
            onTap: () => state.showTasksForChat(chat.id),
          ),
          _Link(
            icon: Icons.calendar_today_outlined,
            label: 'Uchrashuvlar',
            count: state.events.upcomingForChat(chat.id).length,
            onTap: () => state.showEventsForChat(chat.id),
          ),
          _Link(icon: Icons.sticky_note_2_outlined, label: 'Eslatmalar', onTap: () => state.openModule(Module.notes)),
          _Link(icon: Icons.folder_outlined, label: 'Fayllar', onTap: () => state.openModule(Module.files)),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.icon, required this.title, required this.subtitle});

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final c = context.fc;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: c.text2),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontSize: 14, color: c.text)),
                Text(subtitle, style: TextStyle(fontSize: 12, color: c.text2)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TagChip extends StatelessWidget {
  const _TagChip({required this.label, required this.active, required this.onTap});

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.fc;
    return Tap(
      onTap: onTap,
      radius: 14,
      color: active ? c.accentSoft : c.panel,
      border: Border.all(color: active ? c.tagActiveBorder : c.chipBorder),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        child: Text(
          label,
          style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: active ? c.qaFg : c.textSoft),
        ),
      ),
    );
  }
}

class _Link extends StatelessWidget {
  const _Link({required this.icon, required this.label, required this.onTap, this.count = 0});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  /// Shown before the chevron when > 0 (e.g. open tasks of this chat).
  final int count;

  @override
  Widget build(BuildContext context) {
    final c = context.fc;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Tap(
        onTap: onTap,
        radius: 8,
        child: SizedBox(
          height: 44,
          child: Row(
            children: [
              const SizedBox(width: 10),
              Icon(icon, size: 20, color: c.text2),
              const SizedBox(width: 12),
              Expanded(child: Text(label, style: TextStyle(fontSize: 14, color: c.text))),
              if (count > 0) Text('$count', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: c.accentText)),
              Icon(Icons.chevron_right, size: 18, color: c.text2),
              const SizedBox(width: 8),
            ],
          ),
        ),
      ),
    );
  }
}

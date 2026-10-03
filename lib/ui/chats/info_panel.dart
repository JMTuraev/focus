import 'package:flutter/material.dart';

import '../../data/mock.dart';
import '../../state/app_state.dart';
import '../../theme.dart';
import '../common.dart';

class InfoPanel extends StatelessWidget {
  const InfoPanel({super.key, required this.state});

  final AppState state;

  @override
  Widget build(BuildContext context) {
    final chat = state.activeChat;
    final current = state.collectionOf(chat);
    return Container(
      width: 320,
      decoration: const BoxDecoration(color: FC.panel, border: Border(left: BorderSide(color: FC.border))),
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          Container(
            height: 56,
            padding: const EdgeInsets.only(left: 18, right: 8),
            decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: FC.border))),
            child: Row(
              children: [
                const Expanded(child: Text('Ma’lumot', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700))),
                IconButton(tooltip: 'Panelni yopish', onPressed: state.toggleInfo, icon: const Icon(Icons.close, size: 18, color: FC.icon)),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Center(child: Avatar(initials: chat.initials, color: chat.color, size: 88)),
          const SizedBox(height: 10),
          Center(child: Text(chat.name, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700))),
          Center(child: Text(chat.status, style: TextStyle(fontSize: 13, color: chat.online ? FC.accentStrong : FC.text2))),
          const SizedBox(height: 12),
          if (chat.phone.isNotEmpty) _Row(icon: Icons.call_outlined, title: chat.phone, subtitle: 'Telefon'),
          _Row(icon: Icons.info_outline, title: chat.about, subtitle: 'Izoh'),
          const SizedBox(height: 8),
          Container(height: 8, color: FC.bg),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('To‘plam', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: FC.accentStrong)),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final c in kCollections.skip(1))
                      _TagChip(
                        label: c.label,
                        active: current == c.id,
                        onTap: () {
                          state.moveToCollection(chat.id, c.id);
                          ScaffoldMessenger.of(context)
                            ..hideCurrentSnackBar()
                            ..showSnackBar(SnackBar(width: 480, content: Text('${chat.name} → ${c.label} to‘plamiga ko‘chirildi')));
                        },
                      ),
                  ],
                ),
              ],
            ),
          ),
          Container(height: 8, color: FC.bg),
          const Padding(
            padding: EdgeInsets.fromLTRB(18, 14, 18, 6),
            child: Text('Shu chatdan', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: FC.accentStrong)),
          ),
          _Link(icon: Icons.checklist, label: 'Vazifalar', onTap: () => state.openModule(Module.tasks)),
          _Link(icon: Icons.calendar_today_outlined, label: 'Uchrashuvlar', onTap: () => state.openModule(Module.calendar)),
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: FC.text2),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 14)),
                Text(subtitle, style: const TextStyle(fontSize: 12, color: FC.text2)),
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
    return Tap(
      onTap: onTap,
      radius: 14,
      color: active ? FC.accentSoft : Colors.white,
      border: Border.all(color: active ? const Color(0xFF9CC2EC) : const Color(0xFFDDE1E6)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        child: Text(
          label,
          style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: active ? const Color(0xFF1E5FA6) : const Color(0xFF3A4048)),
        ),
      ),
    );
  }
}

class _Link extends StatelessWidget {
  const _Link({required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
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
              Icon(icon, size: 20, color: FC.text2),
              const SizedBox(width: 12),
              Expanded(child: Text(label, style: const TextStyle(fontSize: 14))),
              const Icon(Icons.chevron_right, size: 18, color: FC.text2),
              const SizedBox(width: 8),
            ],
          ),
        ),
      ),
    );
  }
}

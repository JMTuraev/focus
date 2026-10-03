import 'package:flutter/material.dart';

import '../data/mock.dart';
import '../state/app_state.dart';
import '../theme.dart';

const _modules = <(Module, String, IconData)>[
  (Module.chats, 'Chatlar', Icons.chat_bubble_outline),
  (Module.collections, 'To‘plamlar', Icons.grid_view_outlined),
  (Module.tasks, 'Vazifalar', Icons.checklist),
  (Module.calendar, 'Kalendar', Icons.calendar_today_outlined),
  (Module.notes, 'Eslatmalar', Icons.sticky_note_2_outlined),
  (Module.files, 'Fayllar', Icons.folder_outlined),
  (Module.stats, 'Statistika', Icons.bar_chart),
];

/// Narrow vertical panel: modules on top, collections below (like folders).
class Rail extends StatelessWidget {
  const Rail({super.key, required this.state});

  final AppState state;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 84,
      decoration: const BoxDecoration(
        color: FC.panel,
        border: Border(right: BorderSide(color: FC.border)),
      ),
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: [
          for (final m in _modules)
            _RailItem(
              label: m.$2,
              icon: m.$3,
              active: state.module == m.$1,
              onTap: () => state.openModule(m.$1),
            ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            child: Divider(height: 1, color: FC.border),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                for (final c in kCollections)
                  _RailItem(
                    label: c.label,
                    icon: c.icon,
                    height: 44,
                    iconSize: 20,
                    badge: state.badgeFor(c.id),
                    active: state.module == Module.chats && state.collection == c.id,
                    onTap: () => state.pickCollection(c.id),
                  ),
                _RailItem(
                  label: '',
                  icon: Icons.add,
                  height: 38,
                  iconSize: 20,
                  tooltip: 'To‘plam qo‘shish',
                  onTap: () => state.openModule(Module.collections),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RailItem extends StatelessWidget {
  const _RailItem({
    required this.label,
    required this.icon,
    required this.onTap,
    this.active = false,
    this.height = 48,
    this.iconSize = 22,
    this.badge = 0,
    this.tooltip,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool active;
  final double height;
  final double iconSize;
  final int badge;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final fg = active ? FC.accentStrong : FC.icon;
    Widget body = Material(
      color: active ? FC.accentSoft : Colors.transparent,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        hoverColor: const Color(0xFFEEF1F4),
        onTap: onTap,
        child: SizedBox(
          height: height,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: iconSize, color: fg),
                  if (label.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: fg, height: 1.1),
                    ),
                  ],
                ],
              ),
              if (badge > 0)
                Positioned(
                  top: 2,
                  right: 10,
                  child: Container(
                    constraints: const BoxConstraints(minWidth: 18),
                    height: 18,
                    padding: const EdgeInsets.symmetric(horizontal: 5),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: FC.accentStrong,
                      borderRadius: BorderRadius.circular(9),
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: Text('$badge', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700)),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
    if (tooltip != null) body = Tooltip(message: tooltip!, child: body);
    return Padding(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1), child: body);
  }
}

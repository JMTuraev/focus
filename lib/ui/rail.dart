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
  const Rail({super.key, required this.state, required this.onLogout, this.compact = false});

  final AppState state;
  final VoidCallback onLogout;

  /// Narrow layout: thinner rail, labels move into tooltips.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final c = context.fc;
    return Container(
      width: compact ? 64 : 84,
      decoration: BoxDecoration(
        color: c.panel,
        border: Border(right: BorderSide(color: c.border)),
      ),
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: [
          for (final m in _modules)
            _RailItem(
              label: m.$2,
              icon: m.$3,
              compact: compact,
              active: state.module == m.$1,
              onTap: () => state.openModule(m.$1),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            child: Divider(height: 1, color: c.border),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                for (final col in kCollections)
                  _RailItem(
                    label: col.label,
                    icon: col.icon,
                    compact: compact,
                    height: 44,
                    iconSize: 20,
                    badge: state.badgeFor(col.id),
                    active: state.module == Module.chats && state.collection == col.id,
                    onTap: () => state.pickCollection(col.id),
                  ),
                _RailItem(
                  label: '',
                  icon: Icons.add,
                  compact: compact,
                  height: 38,
                  iconSize: 20,
                  tooltip: 'To‘plam qo‘shish',
                  onTap: () => state.openModule(Module.collections),
                ),
              ],
            ),
          ),
          _RailItem(
            label: 'Chiqish',
            icon: Icons.logout,
            compact: compact,
            height: 44,
            iconSize: 20,
            tooltip: 'Akkauntdan chiqish',
            onTap: onLogout,
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
    this.compact = false,
    this.height = 48,
    this.iconSize = 22,
    this.badge = 0,
    this.tooltip,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool active;
  final bool compact;
  final double height;
  final double iconSize;
  final int badge;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final c = context.fc;
    final fg = active ? c.accentText : c.icon;
    final showLabel = label.isNotEmpty && !compact;
    Widget body = Material(
      color: active ? c.accentSoft : Colors.transparent,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        hoverColor: c.railHover,
        onTap: onTap,
        child: SizedBox(
          height: compact ? 44 : height,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: iconSize, color: fg),
                  if (showLabel) ...[
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
                  right: compact ? 4 : 10,
                  child: Container(
                    constraints: const BoxConstraints(minWidth: 18),
                    height: 18,
                    padding: const EdgeInsets.symmetric(horizontal: 5),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: c.accentStrong,
                      borderRadius: BorderRadius.circular(9),
                      border: Border.all(color: c.panel, width: 2),
                    ),
                    child: Text('$badge', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700)),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
    final tip = tooltip ?? (compact && label.isNotEmpty ? label : null);
    if (tip != null) body = Tooltip(message: tip, child: body);
    return Padding(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1), child: body);
  }
}

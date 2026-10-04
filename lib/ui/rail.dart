import 'package:flutter/material.dart';

import '../state/app_state.dart';
import '../theme.dart';
import '../l10n/l10n.dart';

const _modules = <(Module, IconData)>[
  (Module.chats, Icons.chat_bubble_outline),
  (Module.collections, Icons.grid_view_outlined),
  (Module.tasks, Icons.checklist),
  (Module.calendar, Icons.calendar_today_outlined),
  (Module.notes, Icons.sticky_note_2_outlined),
  (Module.files, Icons.folder_outlined),
  (Module.stats, Icons.bar_chart),
];

/// Module name in the current language.
String moduleLabel(BuildContext context, Module m) {
  final t = context.s.app;
  return switch (m) {
    Module.chats => t.chats,
    Module.collections => t.collections,
    Module.tasks => t.tasks,
    Module.calendar => t.calendar,
    Module.notes => t.notes,
    Module.files => t.files,
    Module.stats => t.stats,
  };
}

/// Narrow vertical panel with the modules. Collections live as tabs above
/// the chat list.
class Rail extends StatelessWidget {
  const Rail({super.key, required this.state, required this.onLogout, required this.onSettings, this.compact = false});

  final AppState state;
  final VoidCallback onLogout;
  final VoidCallback onSettings;

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
              label: moduleLabel(context, m.$1),
              icon: m.$2,
              compact: compact,
              active: state.module == m.$1,
              // Tasks: overdue or due today.
              badge: switch (m.$1) {
                Module.tasks => state.tasks.urgentCount,
                // Calendar: meetings still ahead today.
                Module.calendar => state.events.remainingToday(),
                _ => 0,
              },
              onTap: () => state.openModule(m.$1),
            ),
          const Spacer(),
          _RailItem(
            label: context.s.app.settings,
            icon: Icons.settings_outlined,
            compact: compact,
            height: 44,
            iconSize: 20,
            tooltip: context.s.app.settings,
            onTap: onSettings,
          ),
          _RailItem(
            label: context.s.app.logout,
            icon: Icons.logout,
            compact: compact,
            height: 44,
            iconSize: 20,
            tooltip: context.s.app.logoutTip,
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
                    child: Text(
                      badge > 99 ? '99+' : '$badge',
                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700),
                    ),
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

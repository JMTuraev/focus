import 'package:flutter/material.dart';

import '../state/app_state.dart';
import '../state/settings.dart';
import '../theme.dart';
import 'calendar/calendar_screen.dart';
import 'chats/chats_screen.dart';
import 'collections/collections_screen.dart';
import 'layout.dart';
import 'notes/notes_screen.dart';
import 'rail.dart';
import 'tasks/tasks_screen.dart';
import 'title_bar.dart';
import '../l10n/l10n.dart';

class Shell extends StatelessWidget {
  const Shell({super.key, required this.state, required this.settings, required this.onLogout, required this.onSettings});

  final AppState state;
  final Settings settings;
  final VoidCallback onLogout;
  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) {
    final mode = Breakpoints.of(context);
    return Scaffold(
      body: Column(
        children: [
          FokusTitleBar(settings: settings),
          Expanded(
            child: ListenableBuilder(
              listenable: Listenable.merge([state, state.tasks, state.events, state.notes]),
              builder: (context, _) => Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Rail(state: state, compact: mode == LayoutMode.narrow, onLogout: onLogout, onSettings: onSettings),
                  Expanded(child: _screenFor(context, state, mode)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _screenFor(BuildContext context, AppState s, LayoutMode mode) {
    final t = context.s.app;
    return switch (s.module) {
      Module.chats => ChatsScreen(state: s, mode: mode),
      Module.collections => CollectionsScreen(state: s),
      Module.tasks => TasksScreen(state: s),
      Module.calendar => CalendarScreen(state: s),
      Module.notes => NotesScreen(state: s),
      Module.files => _Planned(t.files, t.filesSubtitle),
      Module.stats => _Planned(t.stats, t.statsSubtitle),
    };
  }
}

class _Planned extends StatelessWidget {
  const _Planned(this.title, this.subtitle);

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final c = context.fc;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(title, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: c.text)),
            const SizedBox(height: 6),
            Text(subtitle, textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: c.text2)),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(color: c.accentSoft, borderRadius: BorderRadius.circular(12)),
              child: Text(context.s.app.comingSoon, style: TextStyle(color: c.accentText, fontWeight: FontWeight.w700, fontSize: 12.5)),
            ),
          ],
        ),
      ),
    );
  }
}

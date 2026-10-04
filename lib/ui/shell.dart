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
                  Expanded(child: _screenFor(state, mode)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _screenFor(AppState s, LayoutMode mode) {
    return switch (s.module) {
      Module.chats => ChatsScreen(state: s, mode: mode),
      Module.collections => CollectionsScreen(state: s),
      Module.tasks => TasksScreen(state: s),
      Module.calendar => CalendarScreen(state: s),
      Module.notes => NotesScreen(state: s),
      Module.files => const _Planned('Fayllar', 'AI bo‘limlari va «AI’dan so‘rang»', 4),
      Module.stats => const _Planned('Statistika', 'Kunlik chatlar, javob vaqti, grafiklar', 4),
    };
  }
}

class _Planned extends StatelessWidget {
  const _Planned(this.title, this.subtitle, this.phase);

  final String title;
  final String subtitle;
  final int phase;

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
              child: Text('$phase-bosqichda', style: TextStyle(color: c.accentText, fontWeight: FontWeight.w700, fontSize: 12.5)),
            ),
          ],
        ),
      ),
    );
  }
}

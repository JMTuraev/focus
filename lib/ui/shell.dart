import 'package:flutter/material.dart';

import '../state/app_state.dart';
import '../state/settings.dart';
import 'calendar/calendar_screen.dart';
import 'chats/chats_screen.dart';
import 'collections/collections_screen.dart';
import 'files/files_screen.dart';
import 'layout.dart';
import 'notes/notes_screen.dart';
import 'stats/stats_screen.dart';
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
    return switch (s.module) {
      Module.chats => ChatsScreen(state: s, mode: mode),
      Module.collections => CollectionsScreen(state: s),
      Module.tasks => TasksScreen(state: s),
      Module.calendar => CalendarScreen(state: s),
      Module.notes => NotesScreen(state: s),
      Module.files => FilesScreen(state: s),
      Module.stats => StatsScreen(state: s),
    };
  }
}

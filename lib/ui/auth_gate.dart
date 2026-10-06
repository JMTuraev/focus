import 'dart:async';

import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

import '../auth/auth.dart';
import '../backup/backup_service.dart';
import '../calendar/event_store.dart';
import '../data/chat_source.dart';
import '../notes/note_store.dart';
import '../reminders/message_notifier.dart';
import '../reminders/notifier.dart';
import '../reminders/taskbar_badge.dart';
import '../reminders/reminder_service.dart';
import '../state/app_state.dart';
import '../state/settings.dart';
import '../tasks/task_store.dart';
import '../theme.dart';
import 'login/login_screen.dart';
import 'settings_dialog.dart';
import 'shell.dart';
import '../l10n/l10n.dart';

/// Login screen until TDLib reports `authorizationStateReady`, then the app
/// with a chat session for that account. Logging out closes the session.
class AuthGate extends StatefulWidget {
  const AuthGate({super.key, required this.auth, required this.settings, this.notifier});

  final AuthService auth;
  final Settings settings;

  /// System notifications; null in tests or when Windows refused them.
  final Notifier? notifier;

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> with WidgetsBindingObserver, WindowListener {
  ChatSession? _session;
  AppState? _state;
  ReminderService? _reminders;
  MessageNotifier? _messages;
  TaskbarBadge? _badge;
  BackupService? _backup;

  /// Focused window (desktop: resumed = focused, inactive = behind others).
  bool _windowActive = true;
  StreamSubscription<String>? _taps;
  bool _opening = false;
  bool _launchHandled = false;

  @override
  void initState() {
    super.initState();
    widget.auth.state.addListener(_onAuth);
    WidgetsBinding.instance.addObserver(this);
    windowManager.addListener(this);
    _taps = widget.notifier?.taps.listen(_openFromNotification);
    _onAuth();
  }

  // Window focus comes from both the Flutter lifecycle and window_manager,
  // whichever the platform reports; toasts are skipped for the open chat
  // only while the window is focused.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _windowActive = true;
    if (state == AppLifecycleState.inactive || state == AppLifecycleState.hidden) _windowActive = false;
  }

  @override
  void onWindowFocus() => _windowActive = true;

  @override
  void onWindowBlur() => _windowActive = false;

  @override
  void onWindowMinimize() => _windowActive = false;

  @override
  void dispose() {
    windowManager.removeListener(this);
    WidgetsBinding.instance.removeObserver(this);
    widget.auth.state.removeListener(_onAuth);
    _taps?.cancel();
    _closeSession();
    super.dispose();
  }

  Future<void> _onAuth() async {
    final ready = widget.auth.state.value.step == AuthStep.ready;
    if (ready && _session == null && !_opening) {
      _opening = true;
      try {
        final session = await widget.auth.openSession();
        if (!mounted || widget.auth.state.value.step != AuthStep.ready) {
          await session.close();
          return;
        }
        setState(() {
          _session = session;
          _state = AppState(
            source: session.source,
            store: session.store,
            tasks: TaskStore(session.db),
            events: EventStore(session.db),
            notes: NoteStore(session.db),
            initialChatId: session.initialChatId,
          );
          _badge = TaskbarBadge(_state!)..start();
          _backup = BackupService(db: session.db, transport: session.backupTransport, keys: session.backupKeys);
          _backup!.init().then((_) => _backup?.startAuto());
          final n = widget.notifier;
          if (n != null) {
            _reminders = ReminderService(notifier: n, events: _state!.events, tasks: _state!.tasks, settings: widget.settings)
              ..start();
            _messages = MessageNotifier(
              notifier: n,
              source: session.source,
              settings: widget.settings,
              windowActive: () => _windowActive,
              activeChatId: () => _state?.activeChatId,
            )..start();
          }
        });
        _handleLaunch();
      } finally {
        _opening = false;
      }
    } else if (!ready && _session != null) {
      setState(_closeSession);
    }
  }

  void _closeSession() {
    _reminders?.dispose();
    _reminders = null;
    _messages?.dispose();
    _messages = null;
    _badge?.dispose();
    _badge = null;
    _backup?.dispose();
    _backup = null;
    _state?.dispose();
    _session?.close();
    _state = null;
    _session = null;
  }

  /// Focus was started by a click on a notification: open its target once.
  Future<void> _handleLaunch() async {
    if (_launchHandled) return;
    _launchHandled = true;
    final p = await widget.notifier?.launchPayload();
    if (p != null) await _openFromNotification(p);
  }

  /// "event:ID" opens the calendar on that meeting's week, "task:ID" the
  /// tasks board, "chat:ID" that chat; the window comes to the front.
  Future<void> _openFromNotification(String payload) async {
    // Not awaited: navigation must not wait for the window (and the window
    // plugin is not there in tests).
    unawaited(windowManager.show().then((_) => windowManager.focus()).catchError((Object _) {}));
    final state = _state;
    if (state == null) return;
    final parts = payload.split(':');
    final id = parts.length == 2 ? int.tryParse(parts[1]) : null;
    if (id == null) return;
    switch (parts[0]) {
      case 'event':
        for (var i = 0; i < 20 && !state.events.loaded; i++) {
          await Future<void>.delayed(const Duration(milliseconds: 50));
        }
        final e = state.events.byId(id);
        state.showCalendarAt(e?.start ?? DateTime.now());
      case 'task':
        state.openModule(Module.tasks);
      case 'chat':
        state.openModule(Module.chats);
        if (state.source.chatById('$id') != null) state.openChat('$id');
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AuthState>(
      valueListenable: widget.auth.state,
      builder: (context, s, _) {
        final state = _state;
        if (s.step == AuthStep.ready && state != null) {
          return Shell(
            state: state,
            settings: widget.settings,
            onLogout: () => _confirmLogout(context),
            onSettings: () => showSettingsDialog(
              context,
              widget.settings,
              notifier: widget.notifier,
              reminders: _reminders,
              backup: _backup,
              onRestored: state.reloadLocalData,
            ),
          );
        }
        return LoginScreen(auth: widget.auth, settings: widget.settings);
      },
    );
  }

  Future<void> _confirmLogout(BuildContext context) async {
    final c = context.fc;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: c.panel,
        title: Text(context.s.app.logoutQuestion, style: TextStyle(color: c.text, fontSize: 18, fontWeight: FontWeight.w700)),
        content: Text(
          context.s.app.logoutBody,
          style: TextStyle(color: c.text2, fontSize: 14, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            style: TextButton.styleFrom(foregroundColor: c.accentText),
            child: Text(context.s.common.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: c.danger),
            child: Text(context.s.app.logout),
          ),
        ],
      ),
    );
    if (ok == true) await widget.auth.logOut();
  }
}

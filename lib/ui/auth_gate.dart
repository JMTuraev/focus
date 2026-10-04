import 'package:flutter/material.dart';

import '../auth/auth.dart';
import '../calendar/event_store.dart';
import '../data/chat_source.dart';
import '../state/app_state.dart';
import '../state/settings.dart';
import '../tasks/task_store.dart';
import '../theme.dart';
import 'login/login_screen.dart';
import 'shell.dart';

/// Login screen until TDLib reports `authorizationStateReady`, then the app
/// with a chat session for that account. Logging out closes the session.
class AuthGate extends StatefulWidget {
  const AuthGate({super.key, required this.auth, required this.settings});

  final AuthService auth;
  final Settings settings;

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  ChatSession? _session;
  AppState? _state;
  bool _opening = false;

  @override
  void initState() {
    super.initState();
    widget.auth.state.addListener(_onAuth);
    _onAuth();
  }

  @override
  void dispose() {
    widget.auth.state.removeListener(_onAuth);
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
            initialChatId: session.initialChatId,
          );
        });
      } finally {
        _opening = false;
      }
    } else if (!ready && _session != null) {
      setState(_closeSession);
    }
  }

  void _closeSession() {
    _state?.dispose();
    _session?.close();
    _state = null;
    _session = null;
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AuthState>(
      valueListenable: widget.auth.state,
      builder: (context, s, _) {
        final state = _state;
        if (s.step == AuthStep.ready && state != null) {
          return Shell(state: state, settings: widget.settings, onLogout: () => _confirmLogout(context));
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
        title: Text('Akkauntdan chiqasizmi?', style: TextStyle(color: c.text, fontSize: 18, fontWeight: FontWeight.w700)),
        content: Text(
          'Fokus’dagi Telegram sessiyasi yopiladi. Telefoningizdagi Telegram ishlashda davom etadi.',
          style: TextStyle(color: c.text2, fontSize: 14, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            style: TextButton.styleFrom(foregroundColor: c.accentText),
            child: const Text('Bekor qilish'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: c.danger),
            child: const Text('Chiqish'),
          ),
        ],
      ),
    );
    if (ok == true) await widget.auth.logOut();
  }
}

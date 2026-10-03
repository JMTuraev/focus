import 'package:flutter/material.dart';

import '../auth/auth.dart';
import '../state/app_state.dart';
import '../state/settings.dart';
import '../theme.dart';
import 'login/login_screen.dart';
import 'shell.dart';

/// Login screen until TDLib reports `authorizationStateReady`, then the app.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key, required this.auth, required this.state, required this.settings});

  final AuthService auth;
  final AppState state;
  final Settings settings;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AuthState>(
      valueListenable: auth.state,
      builder: (context, s, _) => s.step == AuthStep.ready
          ? Shell(state: state, settings: settings, onLogout: () => _confirmLogout(context))
          : LoginScreen(auth: auth, settings: settings),
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
    if (ok == true) await auth.logOut();
  }
}

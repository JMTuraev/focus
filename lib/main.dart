import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:screen_retriever/screen_retriever.dart';
import 'package:window_manager/window_manager.dart';

import 'auth/auth.dart';
import 'auth/mock_auth.dart';
import 'config.dart';
import 'state/app_state.dart';
import 'state/settings.dart';
import 'tdlib/td_auth.dart';
import 'theme.dart';
import 'ui/auth_gate.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await windowManager.ensureInitialized();
  final settings = await Settings.load();

  const options = WindowOptions(
    title: 'Fokus',
    size: Size(1440, 900),
    minimumSize: Size(420, 560),
    center: true,
    titleBarStyle: TitleBarStyle.hidden,
    backgroundColor: Colors.transparent,
  );
  windowManager.waitUntilReadyToShow(options, () async {
    await _fitToScreen();
    await windowManager.show();
    await windowManager.focus();
  });

  // USE_MOCK=true (default): mock login and mock chats, TDLib is not loaded.
  final AuthService auth = AppConfig.useMock ? MockAuth() : TdAuth();
  unawaited(auth.start());

  runApp(FokusApp(state: AppState(), settings: settings, auth: auth));
}

/// Keeps the window (and so the custom title bar) inside the screen's
/// work area on small or highly scaled displays.
Future<void> _fitToScreen() async {
  try {
    final display = await screenRetriever.getPrimaryDisplay();
    final area = display.visibleSize ?? display.size;
    const margin = 24.0;
    final size = Size(
      math.min(1440, area.width - margin * 2),
      math.min(900, area.height - margin * 2),
    );
    await windowManager.setSize(size);
    await windowManager.center();
  } catch (_) {
    // Keep the default size if the screen cannot be queried.
  }
}

class FokusApp extends StatelessWidget {
  const FokusApp({super.key, required this.state, required this.settings, required this.auth});

  final AppState state;
  final Settings settings;
  final AuthService auth;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: settings,
      builder: (context, _) => MaterialApp(
        title: 'Fokus',
        debugShowCheckedModeBanner: false,
        theme: buildTheme(Brightness.light),
        darkTheme: buildTheme(Brightness.dark),
        themeMode: settings.themeMode,
        home: AuthGate(auth: auth, state: state, settings: settings),
      ),
    );
  }
}

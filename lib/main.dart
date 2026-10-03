import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

import 'state/app_state.dart';
import 'theme.dart';
import 'ui/shell.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await windowManager.ensureInitialized();

  const options = WindowOptions(
    title: 'Fokus',
    size: Size(1440, 900),
    minimumSize: Size(1100, 700),
    center: true,
    titleBarStyle: TitleBarStyle.hidden,
    backgroundColor: Colors.transparent,
  );
  windowManager.waitUntilReadyToShow(options, () async {
    await windowManager.show();
    await windowManager.focus();
  });

  runApp(FokusApp(state: AppState()));
}

class FokusApp extends StatelessWidget {
  const FokusApp({super.key, required this.state});

  final AppState state;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Fokus',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      home: Shell(state: state),
    );
  }
}

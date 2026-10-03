import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

/// Small app preferences kept in `settings.json` in the app support folder.
/// Local only; nothing is sent anywhere.
class Settings extends ChangeNotifier {
  Settings._(this._file, this._themeMode);

  final File? _file;
  ThemeMode _themeMode;

  /// [ThemeMode.system] until the user picks a mode in the title bar.
  ThemeMode get themeMode => _themeMode;

  /// Not persisted; for tests.
  @visibleForTesting
  Settings.inMemory([ThemeMode mode = ThemeMode.system]) : this._(null, mode);

  static Future<Settings> load() async {
    File? file;
    var mode = ThemeMode.system;
    try {
      final dir = await getApplicationSupportDirectory();
      file = File('${dir.path}${Platform.pathSeparator}settings.json');
      if (await file.exists()) {
        final json = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
        mode = ThemeMode.values.asNameMap()[json['theme']] ?? ThemeMode.system;
      }
    } catch (_) {
      // Unreadable settings are not fatal: fall back to defaults.
    }
    return Settings._(file, mode);
  }

  /// Switches to the opposite of what is currently shown.
  void toggleTheme(Brightness current) {
    _themeMode = current == Brightness.dark ? ThemeMode.light : ThemeMode.dark;
    notifyListeners();
    _save();
  }

  Future<void> _save() async {
    try {
      await _file?.parent.create(recursive: true);
      await _file?.writeAsString(jsonEncode({'theme': _themeMode.name}));
    } catch (_) {
      // Best effort.
    }
  }
}

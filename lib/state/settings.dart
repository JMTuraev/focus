import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

/// Small app preferences kept in `settings.json` in the app support folder.
/// Local only; nothing is sent anywhere.
class Settings extends ChangeNotifier {
  Settings._(this._file, this._themeMode, this._reminders, this._taskHour);

  /// Not persisted; for tests.
  @visibleForTesting
  Settings.inMemory([ThemeMode mode = ThemeMode.system]) : this._(null, mode, true, 9);

  final File? _file;
  ThemeMode _themeMode;
  bool _reminders;
  int _taskHour;

  /// [ThemeMode.system] until the user picks a mode.
  ThemeMode get themeMode => _themeMode;

  /// Windows notifications for meetings and tasks.
  bool get remindersEnabled => _reminders;

  /// Hour of the day when a task due that day is reminded.
  int get taskReminderHour => _taskHour;

  static Future<Settings> load() async {
    File? file;
    var mode = ThemeMode.system;
    var reminders = true;
    var hour = 9;
    try {
      final dir = await getApplicationSupportDirectory();
      file = File('${dir.path}${Platform.pathSeparator}settings.json');
      if (await file.exists()) {
        final json = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
        mode = ThemeMode.values.asNameMap()[json['theme']] ?? ThemeMode.system;
        reminders = json['reminders'] as bool? ?? true;
        hour = (json['taskHour'] as int? ?? 9).clamp(0, 23);
      }
    } catch (_) {
      // Unreadable settings are not fatal: fall back to defaults.
    }
    return Settings._(file, mode, reminders, hour);
  }

  /// Switches to the opposite of what is currently shown (title bar button).
  void toggleTheme(Brightness current) =>
      setThemeMode(current == Brightness.dark ? ThemeMode.light : ThemeMode.dark);

  void setThemeMode(ThemeMode mode) {
    _themeMode = mode;
    _changed();
  }

  void setRemindersEnabled(bool v) {
    _reminders = v;
    _changed();
  }

  void setTaskReminderHour(int h) {
    _taskHour = h.clamp(0, 23);
    _changed();
  }

  void _changed() {
    notifyListeners();
    _save();
  }

  Future<void> _save() async {
    try {
      await _file?.parent.create(recursive: true);
      await _file?.writeAsString(jsonEncode({
        'theme': _themeMode.name,
        'reminders': _reminders,
        'taskHour': _taskHour,
      }));
    } catch (_) {
      // Best effort.
    }
  }
}

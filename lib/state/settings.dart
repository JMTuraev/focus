import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

import '../l10n/l10n.dart';

/// Small app preferences kept in `settings.json` in the app support folder.
/// Local only; nothing is sent anywhere.
class Settings extends ChangeNotifier {
  Settings._(
    this._file,
    this._themeMode,
    this._reminders,
    this._taskHour,
    this._language, {
    bool messages = true,
    bool channels = false,
    bool showText = true,
  })  : _messages = messages,
        _channels = channels,
        _showText = showText;

  /// Not persisted; for tests.
  @visibleForTesting
  Settings.inMemory([ThemeMode mode = ThemeMode.system, AppLanguage language = AppLanguage.uz])
      : this._(null, mode, true, 9, language);

  final File? _file;
  ThemeMode _themeMode;
  bool _reminders;
  int _taskHour;
  AppLanguage _language;
  bool _messages;
  bool _channels;
  bool _showText;

  /// [ThemeMode.system] until the user picks a mode.
  ThemeMode get themeMode => _themeMode;

  /// Windows notifications for meetings and tasks.
  bool get remindersEnabled => _reminders;

  /// Hour of the day when a task due that day is reminded.
  int get taskReminderHour => _taskHour;

  /// UI language; Uzbek until the user picks another one.
  AppLanguage get language => _language;

  /// Windows toasts for new Telegram messages.
  bool get messageNotifications => _messages;

  /// Toasts for channel posts too (off by default: too many).
  bool get notifyChannels => _channels;

  /// Show the message text in the toast; off shows only the chat name.
  bool get notifyShowText => _showText;

  static Future<Settings> load() async {
    File? file;
    var mode = ThemeMode.system;
    var reminders = true;
    var hour = 9;
    var language = AppLanguage.uz;
    var messages = true;
    var channels = false;
    var showText = true;
    try {
      final dir = await getApplicationSupportDirectory();
      file = File('${dir.path}${Platform.pathSeparator}settings.json');
      if (await file.exists()) {
        final json = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
        mode = ThemeMode.values.asNameMap()[json['theme']] ?? ThemeMode.system;
        reminders = json['reminders'] as bool? ?? true;
        hour = (json['taskHour'] as int? ?? 9).clamp(0, 23);
        language = AppLanguage.byCode(json['language'] as String?) ?? AppLanguage.uz;
        messages = json['messages'] as bool? ?? true;
        channels = json['messageChannels'] as bool? ?? false;
        showText = json['messageText'] as bool? ?? true;
      }
    } catch (_) {
      // Unreadable settings are not fatal: fall back to defaults.
    }
    return Settings._(file, mode, reminders, hour, language, messages: messages, channels: channels, showText: showText);
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

  void setLanguage(AppLanguage l) {
    if (l == _language) return;
    _language = l;
    _changed();
  }

  void setMessageNotifications(bool v) {
    _messages = v;
    _changed();
  }

  void setNotifyChannels(bool v) {
    _channels = v;
    _changed();
  }

  void setNotifyShowText(bool v) {
    _showText = v;
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
        'language': _language.name,
        'messages': _messages,
        'messageChannels': _channels,
        'messageText': _showText,
      }));
    } catch (_) {
      // Best effort.
    }
  }
}

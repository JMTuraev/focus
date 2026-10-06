import 'package:flutter/widgets.dart';

import 'areas/app.dart';
import 'areas/auth.dart';
import 'areas/backup.dart';
import 'areas/calendar.dart';
import 'areas/chats.dart';
import 'areas/common.dart';
import 'areas/files.dart';
import 'areas/notes.dart';
import 'areas/stats.dart';
import 'areas/tasks.dart';

export 'areas/app.dart';
export 'areas/auth.dart';
export 'areas/backup.dart';
export 'areas/calendar.dart';
export 'areas/chats.dart';
export 'areas/common.dart';
export 'areas/files.dart';
export 'areas/notes.dart';
export 'areas/stats.dart';
export 'areas/tasks.dart';

/// Languages of the UI. Uzbek (Latin) is the default.
enum AppLanguage {
  uz('O‘zbekcha'),
  ru('Русский'),
  en('English');

  const AppLanguage(this.nativeName);

  /// The language's own name, shown in the picker.
  final String nativeName;

  Locale get locale => Locale(name);

  static AppLanguage? byCode(String? code) => AppLanguage.values.asNameMap()[code];
}

/// All UI texts of one language, split by area. Every text has a value in
/// every language: a missing translation does not compile.
///
/// Widgets read `context.s` (rebuilds when the language changes); code
/// without a context (data sources, services, formatters) reads [S.current].
class S {
  S._(
    this.language, {
    required this.common,
    required this.app,
    required this.auth,
    required this.chats,
    required this.tasks,
    required this.calendar,
    required this.notes,
    required this.backup,
    required this.files,
    required this.stats,
  });

  final AppLanguage language;
  final CommonStrings common;
  final AppStrings app;
  final AuthStrings auth;
  final ChatStrings chats;
  final TaskStrings tasks;
  final CalendarStrings calendar;
  final NoteStrings notes;
  final BackupStrings backup;
  final FilesStrings files;
  final StatsStrings stats;

  static final uz = S._(
    AppLanguage.uz,
    common: commonUz,
    app: appUz,
    auth: authUz,
    chats: chatsUz,
    tasks: tasksUz,
    calendar: calendarUz,
    notes: notesUz,
    backup: backupUz,
    files: filesUz,
    stats: statsUz,
  );
  static final ru = S._(
    AppLanguage.ru,
    common: commonRu,
    app: appRu,
    auth: authRu,
    chats: chatsRu,
    tasks: tasksRu,
    calendar: calendarRu,
    notes: notesRu,
    backup: backupRu,
    files: filesRu,
    stats: statsRu,
  );
  static final en = S._(
    AppLanguage.en,
    common: commonEn,
    app: appEn,
    auth: authEn,
    chats: chatsEn,
    tasks: tasksEn,
    calendar: calendarEn,
    notes: notesEn,
    backup: backupEn,
    files: filesEn,
    stats: statsEn,
  );

  static S of(AppLanguage l) => switch (l) {
        AppLanguage.uz => uz,
        AppLanguage.ru => ru,
        AppLanguage.en => en,
      };

  /// The language in use; set by [LanguageScope] (Settings).
  static S current = uz;
}

/// Provides [S] to the widget tree and keeps [S.current] in sync.
class LanguageScope extends InheritedWidget {
  LanguageScope({super.key, required AppLanguage language, required super.child}) : s = S.of(language) {
    S.current = s;
  }

  final S s;

  @override
  bool updateShouldNotify(LanguageScope oldWidget) => oldWidget.s != s;
}

extension LanguageContext on BuildContext {
  /// UI texts in the current language. Widgets outside a [LanguageScope]
  /// (some tests) get [S.current].
  S get s => dependOnInheritedWidgetOfExactType<LanguageScope>()?.s ?? S.current;
}

/// Russian plural: 1 файл, 2 файла, 5 файлов (21 файл, 22 файла, 11 файлов).
String ruPlural(int n, String one, String few, String many) {
  final m10 = n.abs() % 10;
  final m100 = n.abs() % 100;
  if (m10 == 1 && m100 != 11) return one;
  if (m10 >= 2 && m10 <= 4 && (m100 < 12 || m100 > 14)) return few;
  return many;
}

/// English plural: 1 file, 2 files.
String enPlural(int n, String one, String other) => n == 1 ? one : other;

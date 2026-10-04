import '../l10n.dart' show ruPlural;

/// Encrypted backup to Saved Messages.
class BackupStrings {
  BackupStrings({
    required this.title,
    required this.intro,
    required this.passwordChangeNote,
    required this.newPasswordHint,
    required this.repeatPasswordHint,
    required this.passwordsDontMatch,
    required this.savePassword,
    required this.noBackupYet,
    required this.lastBackup,
    required this.backupNow,
    required this.autoDaily,
    required this.autoDailyHint,
    required this.changePassword,
    required this.listTitle,
    required this.refresh,
    required this.listEmpty,
    required this.restore,
    required this.restoreTitle,
    required this.restoreBody,
    required this.restored,
    required this.saved,
    required this.passwordTitle,
    required this.askPasswordHint,
    required this.statusPreparing,
    required this.statusUploading,
    required this.statusDownloading,
    required this.statusRestoring,
    required this.caption,
    required this.passwordTooShort,
    required this.setPasswordFirst,
    required this.needPassword,
    required this.backupFailed,
    required this.notABackup,
    required this.newerVersion,
    required this.wrongPassword,
    required this.fileDamaged,
    required this.restoreFailed,
    required this.uploadFailed,
    required this.uploadTimeout,
    required this.listFailed,
    required this.downloadFailed,
  });

  /// Dialog title.
  final String title;

  /// What a backup holds and the warning that a forgotten password cannot
  /// be recovered.
  final String intro;

  /// Shown while changing the password.
  final String passwordChangeNote;

  /// Hint of the new password field; [min] is the minimum length.
  final String Function(int min) newPasswordHint;
  final String repeatPasswordHint;
  final String passwordsDontMatch;
  final String savePassword;
  final String noBackupYet;

  /// [when] is e.g. "Bugun, 12:30".
  final String Function(String when) lastBackup;
  final String backupNow;
  final String autoDaily;
  final String autoDailyHint;
  final String changePassword;

  /// Header of the list of backups found in Saved Messages.
  final String listTitle;

  /// Tooltip of the list's refresh button.
  final String refresh;
  final String listEmpty;

  /// Button: restore a backup.
  final String restore;
  final String restoreTitle;

  /// Confirmation text; [when] is the backup's date and time.
  final String Function(String when) restoreBody;

  /// Toast after a restore.
  final String Function(String when) restored;

  /// Toast after "back up now".
  final String saved;

  /// Title of the dialog that asks for the password of a backup.
  final String passwordTitle;
  final String askPasswordHint;

  final String statusPreparing;
  final String statusUploading;
  final String statusDownloading;
  final String statusRestoring;

  /// Caption of the backup document, after the `#fokus_backup` tag.
  final String Function(String date) caption;

  final String Function(int min) passwordTooShort;
  final String setPasswordFirst;

  /// The backup was made with another password than the one on this PC.
  final String needPassword;
  final String Function(String error) backupFailed;
  final String notABackup;

  /// The backup comes from a newer Focus version.
  final String newerVersion;
  final String wrongPassword;
  final String fileDamaged;
  final String Function(String error) restoreFailed;
  final String Function(String reason) uploadFailed;
  final String uploadTimeout;
  final String Function(String reason) listFailed;

  /// Without a [reason] the text ends with a full stop.
  final String Function(String? reason) downloadFailed;
}

final backupUz = BackupStrings(
  title: 'Zaxira nusxa',
  intro: 'Vazifalar, kalendar, eslatmalar va to‘plamlar shifrlanib, Telegram’dagi Saved Messages’ga saqlanadi. '
      'Ochish uchun alohida zaxira paroli kerak. Uni faqat siz bilasiz: parolni unutsangiz, nusxani hech kim, '
      'hatto biz ham ocha olmaymiz.',
  passwordChangeNote: 'Eski nusxalar eski parol bilan ochiladi.',
  newPasswordHint: (n) => 'Zaxira paroli (kamida $n belgi)',
  repeatPasswordHint: 'Parolni takrorlang',
  passwordsDontMatch: 'Parollar bir xil emas.',
  savePassword: 'Parolni saqlash',
  noBackupYet: 'Hali zaxira nusxa saqlanmagan',
  lastBackup: (w) => 'Oxirgi nusxa: $w',
  backupNow: 'Hozir saqlash',
  autoDaily: 'Har kuni avtomatik saqlash',
  autoDailyHint: 'Focus ochiq bo‘lganda, kuniga bir marta',
  changePassword: 'Parolni o‘zgartirish',
  listTitle: 'Saved Messages’dagi nusxalar',
  refresh: 'Yangilash',
  listEmpty: 'Hali nusxa yo‘q.',
  restore: 'Tiklash',
  restoreTitle: 'Shu nusxani tiklaysizmi?',
  restoreBody: (w) => '$w dagi nusxa. Hozirgi vazifalar, kalendar, eslatmalar va to‘plamlar shu nusxadagisi bilan almashtiriladi. '
      'Telegram chatlariga ta’sir qilmaydi.',
  restored: (w) => '$w dagi nusxa tiklandi',
  saved: 'Zaxira nusxa Saved Messages’ga saqlandi',
  passwordTitle: 'Zaxira paroli',
  askPasswordHint: 'Nusxa yaratilgandagi parol',
  statusPreparing: 'Tayyorlanmoqda…',
  statusUploading: 'Saved Messages’ga yuklanmoqda…',
  statusDownloading: 'Yuklab olinmoqda…',
  statusRestoring: 'Tiklanmoqda…',
  caption: (d) => 'Focus zaxira nusxasi · $d\nShifrlangan: faqat backup parolingiz bilan ochiladi.',
  passwordTooShort: (n) => 'Parol kamida $n ta belgidan iborat bo‘lsin.',
  setPasswordFirst: 'Avval zaxira parolini o‘rnating.',
  needPassword: 'Bu nusxa boshqa parol bilan shifrlangan. Parolni kiriting.',
  backupFailed: (e) => 'Zaxira nusxasini saqlab bo‘lmadi: $e',
  notABackup: 'Bu Focus zaxira nusxasi emas yoki fayl buzilgan.',
  newerVersion: 'Bu zaxira nusxasi Focus’ning yangiroq versiyasida yaratilgan. Ilovani yangilang.',
  wrongPassword: 'Parol noto‘g‘ri yoki zaxira fayli buzilgan.',
  fileDamaged: 'Zaxira fayli buzilgan.',
  restoreFailed: (e) => 'Zaxira nusxasini tiklab bo‘lmadi: $e',
  uploadFailed: (r) => 'Saved Messages’ga yuklab bo‘lmadi: $r',
  uploadTimeout: 'Yuklash juda uzoq davom etdi. Internetni tekshirib, qayta urinib ko‘ring.',
  listFailed: (r) => 'Zaxira nusxalarini olib bo‘lmadi: $r',
  downloadFailed: (r) => r == null ? 'Zaxira faylini yuklab bo‘lmadi.' : 'Zaxira faylini yuklab bo‘lmadi: $r',
);

final backupRu = BackupStrings(
  title: 'Резервная копия',
  intro: 'Задачи, календарь, заметки и коллекции шифруются и сохраняются в Избранное в Telegram. '
      'Чтобы открыть копию, нужен отдельный пароль резервной копии. Его знаете только вы: если вы забудете пароль, '
      'никто, даже мы, не сможет открыть копию.',
  passwordChangeNote: 'Старые копии по-прежнему открываются старым паролем.',
  newPasswordHint: (n) => 'Пароль резервной копии (не менее $n ${ruPlural(n, 'символа', 'символов', 'символов')})',
  repeatPasswordHint: 'Повторите пароль',
  passwordsDontMatch: 'Пароли не совпадают.',
  savePassword: 'Сохранить пароль',
  noBackupYet: 'Резервных копий пока нет',
  lastBackup: (w) => 'Последняя копия: $w',
  backupNow: 'Сохранить сейчас',
  autoDaily: 'Сохранять автоматически каждый день',
  autoDailyHint: 'Раз в день, пока Focus открыт',
  changePassword: 'Изменить пароль',
  listTitle: 'Копии в Избранном',
  refresh: 'Обновить',
  listEmpty: 'Копий пока нет.',
  restore: 'Восстановить',
  restoreTitle: 'Восстановить эту копию?',
  restoreBody: (w) => 'Копия: $w. Текущие задачи, календарь, заметки и коллекции будут заменены данными из этой копии. '
      'Чаты Telegram не затрагиваются.',
  restored: (w) => 'Копия восстановлена ($w)',
  saved: 'Резервная копия сохранена в Избранное',
  passwordTitle: 'Пароль резервной копии',
  askPasswordHint: 'Пароль, заданный при создании копии',
  statusPreparing: 'Подготовка…',
  statusUploading: 'Загрузка в Избранное…',
  statusDownloading: 'Скачивание…',
  statusRestoring: 'Восстановление…',
  caption: (d) => 'Резервная копия Focus · $d\nЗашифровано: открывается только вашим паролем резервной копии.',
  passwordTooShort: (n) => 'Пароль должен содержать не менее $n ${ruPlural(n, 'символа', 'символов', 'символов')}.',
  setPasswordFirst: 'Сначала задайте пароль резервной копии.',
  needPassword: 'Эта копия зашифрована другим паролем. Введите пароль.',
  backupFailed: (e) => 'Не удалось сохранить резервную копию: $e',
  notABackup: 'Это не резервная копия Focus, или файл повреждён.',
  newerVersion: 'Эта копия создана в более новой версии Focus. Обновите приложение.',
  wrongPassword: 'Неверный пароль, или файл копии повреждён.',
  fileDamaged: 'Файл резервной копии повреждён.',
  restoreFailed: (e) => 'Не удалось восстановить резервную копию: $e',
  uploadFailed: (r) => 'Не удалось загрузить в Избранное: $r',
  uploadTimeout: 'Загрузка заняла слишком много времени. Проверьте подключение к интернету и попробуйте ещё раз.',
  listFailed: (r) => 'Не удалось получить список копий: $r',
  downloadFailed: (r) => r == null ? 'Не удалось скачать файл копии.' : 'Не удалось скачать файл копии: $r',
);

final backupEn = BackupStrings(
  title: 'Backup',
  intro: 'Tasks, calendar, notes and collections are encrypted and saved to Saved Messages in Telegram. '
      'Opening a backup needs a separate backup password that only you know: if you forget it, nobody, '
      'not even us, can open your backups.',
  passwordChangeNote: 'Old backups still open with the old password.',
  newPasswordHint: (n) => 'Backup password (at least $n characters)',
  repeatPasswordHint: 'Repeat the password',
  passwordsDontMatch: 'Passwords do not match.',
  savePassword: 'Save password',
  noBackupYet: 'No backup saved yet',
  lastBackup: (w) => 'Last backup: $w',
  backupNow: 'Back up now',
  autoDaily: 'Back up automatically every day',
  autoDailyHint: 'Once a day while Focus is open',
  changePassword: 'Change password',
  listTitle: 'Backups in Saved Messages',
  refresh: 'Refresh',
  listEmpty: 'No backups yet.',
  restore: 'Restore',
  restoreTitle: 'Restore this backup?',
  restoreBody: (w) => 'Backup: $w. Your current tasks, calendar, notes and collections will be replaced with the ones '
      'in this backup. Telegram chats are not affected.',
  restored: (w) => 'Backup restored ($w)',
  saved: 'Backup saved to Saved Messages',
  passwordTitle: 'Backup password',
  askPasswordHint: 'The password used when the backup was made',
  statusPreparing: 'Preparing…',
  statusUploading: 'Uploading to Saved Messages…',
  statusDownloading: 'Downloading…',
  statusRestoring: 'Restoring…',
  caption: (d) => 'Focus backup · $d\nEncrypted: opens only with your backup password.',
  passwordTooShort: (n) => 'The password must have at least $n characters.',
  setPasswordFirst: 'Set a backup password first.',
  needPassword: 'This backup was encrypted with another password. Enter the password.',
  backupFailed: (e) => 'Could not save the backup: $e',
  notABackup: 'This is not a Focus backup, or the file is damaged.',
  newerVersion: 'This backup was made in a newer version of Focus. Please update the app.',
  wrongPassword: 'Wrong password, or the backup file is damaged.',
  fileDamaged: 'The backup file is damaged.',
  restoreFailed: (e) => 'Could not restore the backup: $e',
  uploadFailed: (r) => 'Could not upload to Saved Messages: $r',
  uploadTimeout: 'The upload took too long. Check your internet connection and try again.',
  listFailed: (r) => 'Could not load the backups: $r',
  downloadFailed: (r) => r == null ? 'Could not download the backup file.' : 'Could not download the backup file: $r',
);

import '../l10n.dart' show enPlural, ruPlural;

/// App shell: title bar, rail, settings, donations, logout, placeholders.
class AppStrings {
  AppStrings({
    // title bar
    required this.donate,
    required this.supportFocus,
    required this.lightMode,
    required this.darkMode,
    required this.toLightMode,
    required this.toDarkMode,
    required this.minimize,
    required this.maximize,
    required this.language,
    required this.changeLanguage,
    required this.localMode,
    required this.localModeLong,
    required this.localModeTip,
    // rail
    required this.chats,
    required this.collections,
    required this.tasks,
    required this.calendar,
    required this.notes,
    required this.files,
    required this.stats,
    required this.settings,
    required this.logout,
    required this.logoutTip,
    // placeholders
    required this.filesSubtitle,
    required this.statsSubtitle,
    required this.comingSoon,
    // logout dialog
    required this.logoutQuestion,
    required this.logoutBody,
    // settings
    required this.theme,
    required this.themeSystem,
    required this.themeLight,
    required this.themeDark,
    required this.remindersSection,
    required this.remindersTitle,
    required this.remindersOn,
    required this.remindersUnavailable,
    required this.taskReminderHour,
    required this.noScheduledReminders,
    required this.scheduledReminders,
    required this.testNotification,
    required this.testNotificationBody,
    required this.testNotificationSent,
    required this.backupSection,
    required this.backupTile,
    required this.backupNotSet,
    required this.backupNotYet,
    required this.backupLast,
    required this.about,
    required this.supportSubtitle,
    // donations
    required this.donateIntro,
    required this.donateVoluntary,
    required this.donateSection,
    required this.donateNoMethods,
    required this.bankCard,
    required this.copy,
    required this.copied,
    required this.internationalPayment,
    required this.otherWays,
    required this.starOnGitHub,
    required this.starOnGitHubSubtitle,
    required this.reportIssue,
    required this.newsChannel,
    required this.linkFailed,
    required this.thanks,
    // shared
    required this.waitingReply,
  });

  /// Title bar heart (screen reader label).
  final String donate;

  /// "Focus’ni qo‘llab-quvvatlash": donation dialog title and tooltips.
  final String supportFocus;
  final String lightMode;
  final String darkMode;
  final String toLightMode;
  final String toDarkMode;
  final String minimize;
  final String maximize;
  final String language;
  final String changeLanguage;

  /// Local-mode badge: short, long, and the tooltip that explains it.
  final String localMode;
  final String localModeLong;
  final String localModeTip;

  final String chats;
  final String collections;
  final String tasks;
  final String calendar;
  final String notes;
  final String files;
  final String stats;
  final String settings;
  final String logout;
  final String logoutTip;

  final String filesSubtitle;
  final String statsSubtitle;

  /// Badge on screens that are not built yet.
  final String comingSoon;

  final String logoutQuestion;
  final String logoutBody;

  final String theme;
  final String themeSystem;
  final String themeLight;
  final String themeDark;

  /// Settings section about notifications ("Eslatmalar" in Uzbek).
  final String remindersSection;
  final String remindersTitle;
  final String remindersOn;
  final String remindersUnavailable;
  final String taskReminderHour;
  final String noScheduledReminders;
  final String Function(int n) scheduledReminders;
  final String testNotification;
  final String testNotificationBody;
  final String testNotificationSent;
  final String backupSection;
  final String backupTile;
  final String backupNotSet;
  final String backupNotYet;

  /// "Oxirgi: Bugun, 14:30".
  final String Function(String when) backupLast;
  final String about;
  final String supportSubtitle;

  final String donateIntro;
  final String donateVoluntary;
  final String donateSection;
  final String donateNoMethods;
  final String bankCard;
  final String copy;
  final String copied;

  /// Label of the custom donation link when none is configured.
  final String internationalPayment;
  final String otherWays;
  final String starOnGitHub;
  final String starOnGitHubSubtitle;
  final String reportIssue;
  final String newsChannel;
  final String Function(String host) linkFailed;
  final String thanks;

  /// Tooltip of the orange dot: the chat waits for the user's answer.
  final String waitingReply;
}

final appUz = AppStrings(
  donate: 'Donat',
  supportFocus: 'Focus’ni qo‘llab-quvvatlash',
  lightMode: 'Yorug‘ rejim',
  darkMode: 'Tungi rejim',
  toLightMode: 'Yorug‘ rejimga o‘tish',
  toDarkMode: 'Tungi rejimga o‘tish',
  minimize: 'Yig‘ish',
  maximize: 'Kattalashtirish',
  language: 'Til',
  changeLanguage: 'Tilni o‘zgartirish',
  localMode: 'Lokal rejim',
  localModeLong: 'Lokal rejim · telefon ta’sirlanmaydi',
  localModeTip: 'Focus xabarlarni o‘qilgan deb belgilamaydi va onlayn holatingizni ko‘rsatmaydi',
  chats: 'Chatlar',
  collections: 'To‘plamlar',
  tasks: 'Vazifalar',
  calendar: 'Kalendar',
  notes: 'Eslatmalar',
  files: 'Fayllar',
  stats: 'Statistika',
  settings: 'Sozlamalar',
  logout: 'Chiqish',
  logoutTip: 'Akkauntdan chiqish',
  filesSubtitle: 'AI bo‘limlari va «AI’dan so‘rang»',
  statsSubtitle: 'Kunlik chatlar, javob vaqti, grafiklar',
  comingSoon: 'Tez orada',
  logoutQuestion: 'Akkauntdan chiqasizmi?',
  logoutBody: 'Focus’dagi Telegram sessiyasi yopiladi. Telefoningizdagi Telegram ishlashda davom etadi.',
  theme: 'Mavzu',
  themeSystem: 'Tizimga mos',
  themeLight: 'Yorug‘',
  themeDark: 'Tungi',
  remindersSection: 'Eslatmalar',
  remindersTitle: 'Uchrashuv va vazifa bildirishnomalari',
  remindersOn: 'Windows bildirishnomasi Focus yopiq bo‘lsa ham o‘z vaqtida chiqadi.',
  remindersUnavailable: 'Windows bildirishnomalari bu kompyuterda ishga tushmadi.',
  taskReminderHour: 'Vazifa muddati kuni eslatish vaqti',
  noScheduledReminders: 'Hozircha rejalashtirilgan eslatma yo‘q',
  scheduledReminders: (n) => '$n ta eslatma rejalashtirilgan',
  testNotification: 'Sinab ko‘rish',
  testNotificationBody: 'Bildirishnomalar ishlayapti.',
  testNotificationSent: 'Sinov bildirishnomasi yuborildi',
  backupSection: 'Zaxira nusxa',
  backupTile: 'Shifrlangan zaxira (Saved Messages)',
  backupNotSet: 'Sozlanmagan',
  backupNotYet: 'Hali saqlanmagan',
  backupLast: (w) => 'Oxirgi: $w',
  about: 'Focus haqida',
  supportSubtitle: 'Donat va boshqa yo‘llar bilan yordam',
  donateIntro: 'Focus bepul, reklamasiz va serversiz ishlaydi: ma’lumotlaringiz faqat kompyuteringizda va '
      'Telegram’ingizda turadi. Donatlar yangi imkoniyatlar ustida ishlashga vaqt ajratishga yordam beradi.',
  donateVoluntary: 'Donat ixtiyoriy. Hech bir imkoniyat pullik emas va donatsiz ham yopilmaydi.',
  donateSection: 'Donat qilish',
  donateNoMethods: 'To‘lov usullari hali qo‘shilmagan. Tez orada shu yerda paydo bo‘ladi.',
  bankCard: 'Bank kartasi',
  copy: 'Nusxalash',
  copied: 'Nusxalandi',
  internationalPayment: 'Xalqaro to‘lov',
  otherWays: 'Boshqa yo‘llar bilan yordam',
  starOnGitHub: 'GitHub’da yulduzcha qo‘yish',
  starOnGitHubSubtitle: 'Loyiha ko‘proq odamga ko‘rinadi',
  reportIssue: 'Xato yoki taklif yozish',
  newsChannel: 'Yangiliklar kanali',
  linkFailed: (h) => 'Havolani ochib bo‘lmadi: $h',
  thanks: 'Rahmat!',
  waitingReply: 'Javob kutmoqda',
);

final appRu = AppStrings(
  donate: 'Поддержать',
  supportFocus: 'Поддержать Focus',
  lightMode: 'Светлая тема',
  darkMode: 'Тёмная тема',
  toLightMode: 'Включить светлую тему',
  toDarkMode: 'Включить тёмную тему',
  minimize: 'Свернуть',
  maximize: 'Развернуть',
  language: 'Язык',
  changeLanguage: 'Сменить язык',
  localMode: 'Локальный режим',
  localModeLong: 'Локальный режим · телефон не затронут',
  localModeTip: 'Focus не отмечает сообщения прочитанными и не показывает, что вы в сети',
  chats: 'Чаты',
  collections: 'Коллекции',
  tasks: 'Задачи',
  calendar: 'Календарь',
  notes: 'Заметки',
  files: 'Файлы',
  stats: 'Статистика',
  settings: 'Настройки',
  logout: 'Выйти',
  logoutTip: 'Выйти из аккаунта',
  filesSubtitle: 'Разделы с ИИ и «Спросить ИИ»',
  statsSubtitle: 'Чаты по дням, время ответа, графики',
  comingSoon: 'Скоро',
  logoutQuestion: 'Выйти из аккаунта?',
  logoutBody: 'Сессия Telegram в Focus будет закрыта. Telegram на вашем телефоне продолжит работать.',
  theme: 'Тема',
  themeSystem: 'Как в системе',
  themeLight: 'Светлая',
  themeDark: 'Тёмная',
  remindersSection: 'Напоминания',
  remindersTitle: 'Уведомления о встречах и задачах',
  remindersOn: 'Уведомление Windows придёт вовремя, даже если Focus закрыт.',
  remindersUnavailable: 'Уведомления Windows не запустились на этом компьютере.',
  taskReminderHour: 'Время напоминания в день срока задачи',
  noScheduledReminders: 'Запланированных напоминаний пока нет',
  scheduledReminders: (n) =>
      '$n ${ruPlural(n, 'напоминание запланировано', 'напоминания запланировано', 'напоминаний запланировано')}',
  testNotification: 'Проверить',
  testNotificationBody: 'Уведомления работают.',
  testNotificationSent: 'Тестовое уведомление отправлено',
  backupSection: 'Резервная копия',
  backupTile: 'Зашифрованная копия (Избранное)',
  backupNotSet: 'Не настроено',
  backupNotYet: 'Ещё не сохранялась',
  backupLast: (w) => 'Последняя: $w',
  about: 'О Focus',
  supportSubtitle: 'Пожертвования и другие способы помочь',
  donateIntro: 'Focus бесплатный, без рекламы и без серверов: ваши данные хранятся только на вашем компьютере '
      'и в вашем Telegram. Пожертвования помогают находить время для новых функций.',
  donateVoluntary: 'Пожертвование добровольное. Ни одна функция не платная и не закрывается без него.',
  donateSection: 'Пожертвовать',
  donateNoMethods: 'Способы оплаты пока не добавлены. Скоро они появятся здесь.',
  bankCard: 'Банковская карта',
  copy: 'Копировать',
  copied: 'Скопировано',
  internationalPayment: 'Международный платёж',
  otherWays: 'Другие способы помочь',
  starOnGitHub: 'Поставить звезду на GitHub',
  starOnGitHubSubtitle: 'Так проект увидит больше людей',
  reportIssue: 'Сообщить об ошибке или предложить идею',
  newsChannel: 'Канал новостей',
  linkFailed: (h) => 'Не удалось открыть ссылку: $h',
  thanks: 'Спасибо!',
  waitingReply: 'Ждёт ответа',
);

final appEn = AppStrings(
  donate: 'Donate',
  supportFocus: 'Support Focus',
  lightMode: 'Light mode',
  darkMode: 'Dark mode',
  toLightMode: 'Switch to light mode',
  toDarkMode: 'Switch to dark mode',
  minimize: 'Minimize',
  maximize: 'Maximize',
  language: 'Language',
  changeLanguage: 'Change language',
  localMode: 'Local mode',
  localModeLong: 'Local mode · your phone is not affected',
  localModeTip: 'Focus does not mark messages as read and does not show you as online',
  chats: 'Chats',
  collections: 'Collections',
  tasks: 'Tasks',
  calendar: 'Calendar',
  notes: 'Notes',
  files: 'Files',
  stats: 'Statistics',
  settings: 'Settings',
  logout: 'Log out',
  logoutTip: 'Log out of the account',
  filesSubtitle: 'AI sections and “Ask AI”',
  statsSubtitle: 'Chats per day, reply time, charts',
  comingSoon: 'Coming soon',
  logoutQuestion: 'Log out of your account?',
  logoutBody: 'The Telegram session in Focus will be closed. Telegram on your phone keeps working.',
  theme: 'Theme',
  themeSystem: 'System',
  themeLight: 'Light',
  themeDark: 'Dark',
  remindersSection: 'Reminders',
  remindersTitle: 'Meeting and task notifications',
  remindersOn: 'Windows notifications arrive on time even when Focus is closed.',
  remindersUnavailable: 'Windows notifications could not start on this computer.',
  taskReminderHour: 'Reminder time on a task’s due date',
  noScheduledReminders: 'No reminders scheduled yet',
  scheduledReminders: (n) => '$n ${enPlural(n, 'reminder', 'reminders')} scheduled',
  testNotification: 'Test',
  testNotificationBody: 'Notifications are working.',
  testNotificationSent: 'Test notification sent',
  backupSection: 'Backup',
  backupTile: 'Encrypted backup (Saved Messages)',
  backupNotSet: 'Not set up',
  backupNotYet: 'Not backed up yet',
  backupLast: (w) => 'Last: $w',
  about: 'About Focus',
  supportSubtitle: 'Donations and other ways to help',
  donateIntro: 'Focus is free, ad-free and serverless: your data stays only on your computer and in your '
      'Telegram. Donations help free up time for new features.',
  donateVoluntary: 'Donating is optional. No feature is paid or locked without a donation.',
  donateSection: 'Donate',
  donateNoMethods: 'No payment methods yet. They will appear here soon.',
  bankCard: 'Bank card',
  copy: 'Copy',
  copied: 'Copied',
  internationalPayment: 'International payment',
  otherWays: 'Other ways to help',
  starOnGitHub: 'Star it on GitHub',
  starOnGitHubSubtitle: 'More people will see the project',
  reportIssue: 'Report a bug or suggest an idea',
  newsChannel: 'News channel',
  linkFailed: (h) => 'Could not open the link: $h',
  thanks: 'Thank you!',
  waitingReply: 'Waiting for your reply',
);

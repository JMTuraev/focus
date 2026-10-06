import '../l10n.dart' show enPlural, ruPlural;

/// "Statistika" module: numbers about the chats and Focus work, computed
/// locally from what is already loaded.
class StatsStrings {
  StatsStrings({
    required this.title,
    required this.intro,
    required this.chats,
    required this.unreadChats,
    required this.waitingReplies,
    required this.activeToday,
    required this.openTasks,
    required this.overdueTasks,
    required this.doneTasks,
    required this.meetingsThisWeek,
    required this.notes,
    required this.byCollection,
    required this.byCollectionHint,
    required this.unsorted,
    required this.byType,
    required this.activeByDay,
    required this.activeByDayHint,
    required this.longestWaiting,
    required this.longestWaitingHint,
    required this.noWaiting,
    required this.waitingFor,
    required this.tasksByColumn,
    required this.unreadShort,
    required this.chatsShort,
  });

  final String title;
  final String intro;

  // Stat tiles.
  final String chats;
  final String unreadChats;
  final String waitingReplies;
  final String activeToday;
  final String openTasks;
  final String overdueTasks;
  final String doneTasks;
  final String meetingsThisWeek;
  final String notes;

  // Sections.
  final String byCollection;
  final String byCollectionHint;
  final String unsorted;
  final String byType;
  final String activeByDay;
  final String activeByDayHint;
  final String longestWaiting;
  final String longestWaitingHint;
  final String noWaiting;

  /// "3 soat" / "2 kun" how long a chat has waited for our reply.
  final String Function(Duration d) waitingFor;
  final String tasksByColumn;

  /// Bar value labels: "12 chat · 3 o‘qilmagan".
  final String Function(int n) unreadShort;
  final String Function(int n) chatsShort;
}

String _dur(Duration d, String Function(int) h, String Function(int) days, String minutes) {
  if (d.inHours < 1) return minutes;
  if (d.inHours < 24) return h(d.inHours);
  return days(d.inDays);
}

final statsUz = StatsStrings(
  title: 'Statistika',
  intro: 'Hammasi shu kompyuterda hisoblanadi, Telegramga hech narsa yuborilmaydi.',
  chats: 'Chatlar',
  unreadChats: 'O‘qilmagan chatlar',
  waitingReplies: 'Javob kutmoqda',
  activeToday: 'Bugun faol',
  openTasks: 'Ochiq vazifalar',
  overdueTasks: 'Muddati o‘tgan',
  doneTasks: 'Bajarilgan',
  meetingsThisWeek: 'Shu hafta uchrashuvlar',
  notes: 'Eslatmalar',
  byCollection: 'To‘plamlar bo‘yicha',
  byCollectionHint: 'Har to‘plamdagi chatlar soni; ajralib turgan qism o‘qilmaganlar.',
  unsorted: 'Saralanmagan',
  byType: 'Chat turlari',
  activeByDay: 'Faol chatlar, kunlar bo‘yicha',
  activeByDayHint: 'Oxirgi xabari shu kunga to‘g‘ri kelgan chatlar soni, so‘nggi 7 kun.',
  longestWaiting: 'Eng uzoq javob kutayotganlar',
  longestWaitingHint: 'Oxirgi xabar suhbatdoshdan kelgan va siz hali javob bermagan chatlar.',
  noWaiting: 'Hamma chatga javob berilgan.',
  waitingFor: (d) => _dur(d, (h) => '$h soat', (n) => '$n kun', '1 soatdan kam'),
  tasksByColumn: 'Vazifalar ustunlar bo‘yicha',
  unreadShort: (n) => '$n o‘qilmagan',
  chatsShort: (n) => '$n chat',
);

final statsRu = StatsStrings(
  title: 'Статистика',
  intro: 'Всё считается на этом компьютере, в Telegram ничего не отправляется.',
  chats: 'Чаты',
  unreadChats: 'Непрочитанные чаты',
  waitingReplies: 'Ждут ответа',
  activeToday: 'Активны сегодня',
  openTasks: 'Открытые задачи',
  overdueTasks: 'Просроченные',
  doneTasks: 'Выполненные',
  meetingsThisWeek: 'Встречи на этой неделе',
  notes: 'Заметки',
  byCollection: 'По коллекциям',
  byCollectionHint: 'Сколько чатов в каждой коллекции; выделенная часть — непрочитанные.',
  unsorted: 'Без коллекции',
  byType: 'Типы чатов',
  activeByDay: 'Активные чаты по дням',
  activeByDayHint: 'Сколько чатов получили последнее сообщение в этот день, последние 7 дней.',
  longestWaiting: 'Дольше всего ждут ответа',
  longestWaitingHint: 'Чаты, где последнее сообщение от собеседника, а вы ещё не ответили.',
  noWaiting: 'Во всех чатах отвечено.',
  waitingFor: (d) => _dur(d, (h) => ruPlural(h, '$h час', '$h часа', '$h часов'),
      (n) => ruPlural(n, '$n день', '$n дня', '$n дней'), 'меньше часа'),
  tasksByColumn: 'Задачи по колонкам',
  unreadShort: (n) => ruPlural(n, '$n непрочитанный', '$n непрочитанных', '$n непрочитанных'),
  chatsShort: (n) => ruPlural(n, '$n чат', '$n чата', '$n чатов'),
);

final statsEn = StatsStrings(
  title: 'Statistics',
  intro: 'Everything is computed on this PC; nothing is sent to Telegram.',
  chats: 'Chats',
  unreadChats: 'Unread chats',
  waitingReplies: 'Awaiting reply',
  activeToday: 'Active today',
  openTasks: 'Open tasks',
  overdueTasks: 'Overdue',
  doneTasks: 'Done',
  meetingsThisWeek: 'Meetings this week',
  notes: 'Notes',
  byCollection: 'By collection',
  byCollectionHint: 'Chats in each collection; the highlighted part is unread.',
  unsorted: 'Unsorted',
  byType: 'Chat types',
  activeByDay: 'Active chats by day',
  activeByDayHint: 'Chats whose last message arrived that day, last 7 days.',
  longestWaiting: 'Waiting longest for a reply',
  longestWaitingHint: 'Chats where the last message is theirs and you have not replied yet.',
  noWaiting: 'Every chat has been answered.',
  waitingFor: (d) => _dur(d, (h) => '$h ${enPlural(h, 'hour', 'hours')}', (n) => '$n ${enPlural(n, 'day', 'days')}', 'under an hour'),
  tasksByColumn: 'Tasks by column',
  unreadShort: (n) => '$n unread',
  chatsShort: (n) => '$n ${enPlural(n, 'chat', 'chats')}',
);

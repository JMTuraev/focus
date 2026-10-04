import '../l10n.dart' show enPlural, ruPlural;
import 'common.dart' show commonEn, commonRu, commonUz;

/// Calendar, event editor, meetings, reminders.
class CalendarStrings {
  CalendarStrings({
    required this.title,
    required this.rangeDay,
    required this.rangeWeek,
    required this.remainingToday,
    required this.prevWeek,
    required this.prevDay,
    required this.nextWeek,
    required this.nextDay,
    required this.week,
    required this.day,
    required this.newEventShort,
    required this.newEvent,
    required this.onlyChat,
    required this.chatFallback,
    required this.removeFilter,
    required this.allDay,
    required this.moreCount,
    required this.openChat,
    required this.event,
    required this.eventDeleted,
    required this.undo,
    required this.titleRequired,
    required this.endBeforeStart,
    required this.titleHint,
    required this.when,
    required this.duration,
    required this.reminder,
    required this.note,
    required this.noteHint,
    required this.fromChat,
    required this.minutes,
    required this.hours,
    required this.hoursAndHalf,
    required this.days,
    required this.reminderNone,
    required this.eventWithChat,
    required this.meetingLabel,
    required this.reminderAllDay,
    required this.taskReminderTitle,
    required this.taskReminderDue,
  });

  // ---- Calendar screen header ----

  /// Screen title: "Kalendar".
  final String title;

  /// Day view range: "Payshanba, 8 oktabr 2026". Must end with the year.
  final String Function(String weekday, int day, int month, int year) rangeDay;

  /// Week view range: "6–12 oktabr 2026", "29 sentabr – 5 oktabr 2026".
  /// Must end with the year.
  final String Function(DateTime start, DateTime end) rangeWeek;

  /// Appended to the range: "bugun yana 2 ta uchrashuv".
  final String Function(int n) remainingToday;

  /// Tooltips of the arrows.
  final String prevWeek;
  final String prevDay;
  final String nextWeek;
  final String nextDay;

  /// View switcher.
  final String week;
  final String day;

  /// "New event" button: short form for narrow windows, full form.
  final String newEventShort;
  final String newEvent;

  /// Chat filter chip: "Faqat: Dilshod Karimov".
  final String Function(String chat) onlyChat;

  /// Chat name when the filtered chat is not loaded.
  final String chatFallback;
  final String removeFilter;

  // ---- Grid ----

  /// All-day row label and editor switch: "Kun bo‘yi".
  final String allDay;

  /// Hidden all-day items in a day: "yana 2 ta".
  final String Function(int n) moreCount;

  /// Event context menu.
  final String openChat;

  // ---- Event editor ----

  /// Editor title for an existing event.
  final String event;

  /// Toast: "Uchrashuv o‘chirildi: “Demo”".
  final String Function(String title) eventDeleted;

  /// Toast action that puts a deleted event back.
  final String undo;
  final String titleRequired;
  final String endBeforeStart;
  final String titleHint;

  /// Section labels.
  final String when;
  final String duration;
  final String reminder;
  final String note;
  final String noteHint;
  final String fromChat;

  /// Duration and reminder chips: "30 daqiqa", "1 soat", "1,5 soat", "1 kun".
  final String Function(int n) minutes;
  final String Function(int n) hours;
  final String Function(int whole) hoursAndHalf;
  final String Function(int n) days;

  /// Reminder chip: no reminder.
  final String reminderNone;

  /// Default title of an event created from a chat: "Uchrashuv: Dilshod".
  final String Function(String chat) eventWithChat;

  // ---- Meetings found in messages ----

  /// "Payshanba, 8-okt · 15:00" ([weekday] and [month] are 1-based).
  final String Function(int weekday, int day, int month, String time) meetingLabel;

  // ---- Notifications ----

  /// Body of an all-day meeting reminder: "Bugun, kun bo‘yi".
  final String Function(String day) reminderAllDay;

  /// "Vazifa: Hisobot".
  final String Function(String task) taskReminderTitle;

  /// "Muddati: bugun"; [due] is a due label like "Bugun" or "12-okt".
  final String Function(String due) taskReminderDue;
}

// ---- Uzbek ----

String _uzMonth(int m) => commonUz.months[m - 1];

/// Short months of meeting labels (June and July must differ).
const _uzMonthShort = ['yan', 'fev', 'mar', 'apr', 'may', 'iyun', 'iyul', 'avg', 'sen', 'okt', 'noy', 'dek'];

final calendarUz = CalendarStrings(
  title: 'Kalendar',
  rangeDay: (wd, d, m, y) => '$wd, $d ${_uzMonth(m)} $y',
  rangeWeek: (s, e) {
    if (s.month == e.month) return '${s.day}–${e.day} ${_uzMonth(e.month)} ${e.year}';
    final sameYear = s.year == e.year;
    return '${s.day} ${_uzMonth(s.month)}${sameYear ? '' : ' ${s.year}'} – ${e.day} ${_uzMonth(e.month)} ${e.year}';
  },
  remainingToday: (n) => 'bugun yana $n ta uchrashuv',
  prevWeek: 'Oldingi hafta',
  prevDay: 'Oldingi kun',
  nextWeek: 'Keyingi hafta',
  nextDay: 'Keyingi kun',
  week: 'Hafta',
  day: 'Kun',
  newEventShort: 'Yangi',
  newEvent: 'Yangi uchrashuv',
  onlyChat: (chat) => 'Faqat: $chat',
  chatFallback: 'chat',
  removeFilter: 'Filtrni olib tashlash',
  allDay: 'Kun bo‘yi',
  moreCount: (n) => 'yana $n ta',
  openChat: 'Chatni ochish',
  event: 'Uchrashuv',
  eventDeleted: (t) => 'Uchrashuv o‘chirildi: “$t”',
  undo: 'Qaytarish',
  titleRequired: 'Uchrashuv nomini kiriting.',
  endBeforeStart: 'Tugash vaqti boshlanishdan keyin bo‘lishi kerak.',
  titleHint: 'Nima? Masalan: Demo, «Olimp» bilan',
  when: 'Qachon',
  duration: 'Davomiyligi',
  reminder: 'Eslatma',
  note: 'Izoh',
  noteHint: 'Manzil, havola yoki qo‘shimcha ma’lumot',
  fromChat: 'Chatdan',
  minutes: (n) => '$n daqiqa',
  hours: (n) => '$n soat',
  hoursAndHalf: (h) => '$h,5 soat',
  days: (n) => '$n kun',
  reminderNone: 'Yo‘q',
  eventWithChat: (chat) => 'Uchrashuv: $chat',
  meetingLabel: (wd, d, m, t) => '${commonUz.weekdays[wd - 1]}, $d-${_uzMonthShort[m - 1]} · $t',
  reminderAllDay: (day) => '$day, kun bo‘yi',
  taskReminderTitle: (t) => 'Vazifa: $t',
  taskReminderDue: (due) => 'Muddati: ${due.toLowerCase()}',
);

// ---- Russian ----

String _ruMonth(int m) => commonRu.months[m - 1];

final calendarRu = CalendarStrings(
  title: 'Календарь',
  rangeDay: (wd, d, m, y) => '$wd, $d ${_ruMonth(m)} $y',
  rangeWeek: (s, e) {
    if (s.month == e.month) return '${s.day}–${e.day} ${_ruMonth(e.month)} ${e.year}';
    final sameYear = s.year == e.year;
    return '${s.day} ${_ruMonth(s.month)}${sameYear ? '' : ' ${s.year}'} – ${e.day} ${_ruMonth(e.month)} ${e.year}';
  },
  remainingToday: (n) => 'сегодня ещё $n ${ruPlural(n, 'событие', 'события', 'событий')}',
  prevWeek: 'Предыдущая неделя',
  prevDay: 'Предыдущий день',
  nextWeek: 'Следующая неделя',
  nextDay: 'Следующий день',
  week: 'Неделя',
  day: 'День',
  newEventShort: 'Новое',
  newEvent: 'Новое событие',
  onlyChat: (chat) => 'Только: $chat',
  chatFallback: 'чат',
  removeFilter: 'Убрать фильтр',
  allDay: 'Весь день',
  moreCount: (n) => 'ещё $n',
  openChat: 'Открыть чат',
  event: 'Событие',
  eventDeleted: (t) => 'Событие удалено: «$t»',
  undo: 'Вернуть',
  titleRequired: 'Введите название события.',
  endBeforeStart: 'Время окончания должно быть позже начала.',
  titleHint: 'Что? Например: демо с «Олимпом»',
  when: 'Когда',
  duration: 'Длительность',
  reminder: 'Напоминание',
  note: 'Описание',
  noteHint: 'Адрес, ссылка или другие сведения',
  fromChat: 'Из чата',
  minutes: (n) => '$n ${ruPlural(n, 'минута', 'минуты', 'минут')}',
  hours: (n) => '$n ${ruPlural(n, 'час', 'часа', 'часов')}',
  hoursAndHalf: (h) => '$h,5 часа',
  days: (n) => '$n ${ruPlural(n, 'день', 'дня', 'дней')}',
  reminderNone: 'Нет',
  eventWithChat: (chat) => 'Встреча: $chat',
  meetingLabel: (wd, d, m, t) => '${commonRu.weekdays[wd - 1]}, $d ${commonRu.monthsShort[m - 1]} · $t',
  reminderAllDay: (day) => '$day, весь день',
  taskReminderTitle: (t) => 'Задача: $t',
  taskReminderDue: (due) => 'Срок: ${due.toLowerCase()}',
);

// ---- English ----

String _enMonth(int m) => commonEn.months[m - 1];

final calendarEn = CalendarStrings(
  title: 'Calendar',
  rangeDay: (wd, d, m, y) => '$wd, ${_enMonth(m)} $d, $y',
  rangeWeek: (s, e) {
    if (s.month == e.month) return '${_enMonth(e.month)} ${s.day}–${e.day}, ${e.year}';
    final sameYear = s.year == e.year;
    return '${_enMonth(s.month)} ${s.day}${sameYear ? '' : ', ${s.year}'} – ${_enMonth(e.month)} ${e.day}, ${e.year}';
  },
  remainingToday: (n) => '$n more ${enPlural(n, 'event', 'events')} today',
  prevWeek: 'Previous week',
  prevDay: 'Previous day',
  nextWeek: 'Next week',
  nextDay: 'Next day',
  week: 'Week',
  day: 'Day',
  newEventShort: 'New',
  newEvent: 'New event',
  onlyChat: (chat) => 'Only: $chat',
  chatFallback: 'chat',
  removeFilter: 'Remove filter',
  allDay: 'All day',
  moreCount: (n) => '$n more',
  openChat: 'Open chat',
  event: 'Event',
  eventDeleted: (t) => 'Event deleted: “$t”',
  undo: 'Undo',
  titleRequired: 'Enter a title for the event.',
  endBeforeStart: 'The end time must be after the start time.',
  titleHint: 'What? For example: Demo with Olimp',
  when: 'When',
  duration: 'Duration',
  reminder: 'Reminder',
  note: 'Notes',
  noteHint: 'Address, link or other details',
  fromChat: 'From chat',
  minutes: (n) => '$n ${enPlural(n, 'minute', 'minutes')}',
  hours: (n) => '$n ${enPlural(n, 'hour', 'hours')}',
  hoursAndHalf: (h) => '$h.5 hours',
  days: (n) => '$n ${enPlural(n, 'day', 'days')}',
  reminderNone: 'None',
  eventWithChat: (chat) => 'Meeting: $chat',
  meetingLabel: (wd, d, m, t) => '${commonEn.weekdays[wd - 1]}, ${commonEn.monthsShort[m - 1]} $d · $t',
  reminderAllDay: (day) => '$day, all day',
  taskReminderTitle: (t) => 'Task: $t',
  // "Due: today", but "Due: Oct 12" (month names keep their capital).
  taskReminderDue: (due) =>
      'Due: ${[commonEn.today, commonEn.tomorrow, commonEn.yesterday].contains(due) ? due.toLowerCase() : due}',
);

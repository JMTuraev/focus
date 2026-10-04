import '../l10n.dart' show enPlural, ruPlural;

/// Words used everywhere: buttons, dates, sizes. Area-specific texts live in
/// their own files; reuse these instead of adding near-duplicates.
class CommonStrings {
  CommonStrings({
    required this.cancel,
    required this.save,
    required this.close,
    required this.delete,
    required this.edit,
    required this.create,
    required this.add,
    required this.send,
    required this.open,
    required this.back,
    required this.search,
    required this.yes,
    required this.no,
    required this.ok,
    required this.retry,
    required this.today,
    required this.yesterday,
    required this.tomorrow,
    required this.months,
    required this.monthsShort,
    required this.weekdaysShort,
    required this.weekdays,
    required this.dayMonth,
    required this.dayMonthYear,
    required this.dayMonthShort,
    required this.decimalSeparator,
    required this.bytes,
    required this.kilobytes,
    required this.megabytes,
    required this.gigabytes,
    required this.file,
    required this.lastSeenJustNow,
    required this.lastSeenMinutes,
    required this.lastSeenToday,
    required this.lastSeenYesterday,
    required this.lastSeenOn,
    required this.chatsCount,
    required this.filesCount,
  });

  final String cancel;
  final String save;
  final String close;
  final String delete;
  final String edit;
  final String create;
  final String add;
  final String send;
  final String open;
  final String back;
  final String search;
  final String yes;
  final String no;
  final String ok;
  final String retry;

  /// "Bugun", "Kecha", "Ertaga" (capitalized; lower-case them in sentences).
  final String today;
  final String yesterday;
  final String tomorrow;

  /// Month names as used after a day number: "oktabr", "октября", "October".
  final List<String> months;

  /// "okt", "окт", "Oct".
  final List<String> monthsShort;

  /// Monday first: "Dush", "Пн", "Mon".
  final List<String> weekdaysShort;

  /// Monday first: "Dushanba", "Понедельник", "Monday".
  final List<String> weekdays;

  /// "12-oktabr", "12 октября", "October 12".
  final String Function(int day, int month) dayMonth;

  /// "12-oktabr, 2025", "12 октября 2025", "October 12, 2025".
  final String Function(int day, int month, int year) dayMonthYear;

  /// "12-okt", "12 окт", "Oct 12".
  final String Function(int day, int month) dayMonthShort;

  /// "," in Uzbek and Russian, "." in English.
  final String decimalSeparator;
  final String bytes;
  final String kilobytes;
  final String megabytes;
  final String gigabytes;

  /// "Fayl": a file without a name or extension.
  final String file;

  final String lastSeenJustNow;
  final String Function(int minutes) lastSeenMinutes;
  final String Function(String time) lastSeenToday;
  final String Function(String time) lastSeenYesterday;
  final String Function(String date) lastSeenOn;

  /// "12 ta chat", "12 чатов", "12 chats".
  final String Function(int n) chatsCount;

  /// "3 ta fayl", "3 файла", "3 files".
  final String Function(int n) filesCount;
}

const _uzMonths = [
  'yanvar', 'fevral', 'mart', 'aprel', 'may', 'iyun', //
  'iyul', 'avgust', 'sentabr', 'oktabr', 'noyabr', 'dekabr',
];

// Uzbek short months keep June and July apart ("iyun", "iyul").
const _uzMonthsShort = ['yan', 'fev', 'mar', 'apr', 'may', 'iyun', 'iyul', 'avg', 'sen', 'okt', 'noy', 'dek'];

final commonUz = CommonStrings(
  cancel: 'Bekor qilish',
  save: 'Saqlash',
  close: 'Yopish',
  delete: 'O‘chirish',
  edit: 'Tahrirlash',
  create: 'Yaratish',
  add: 'Qo‘shish',
  send: 'Yuborish',
  open: 'Ochish',
  back: 'Orqaga',
  search: 'Qidiruv',
  yes: 'Ha',
  no: 'Yo‘q',
  ok: 'OK',
  retry: 'Qayta urinish',
  today: 'Bugun',
  yesterday: 'Kecha',
  tomorrow: 'Ertaga',
  months: _uzMonths,
  monthsShort: _uzMonthsShort,
  weekdaysShort: const ['Dush', 'Sesh', 'Chor', 'Pay', 'Jum', 'Shan', 'Yak'],
  weekdays: const ['Dushanba', 'Seshanba', 'Chorshanba', 'Payshanba', 'Juma', 'Shanba', 'Yakshanba'],
  dayMonth: (d, m) => '$d-${_uzMonths[m - 1]}',
  dayMonthYear: (d, m, y) => '$d-${_uzMonths[m - 1]}, $y',
  dayMonthShort: (d, m) => '$d-${_uzMonthsShort[m - 1]}',
  decimalSeparator: ',',
  bytes: 'B',
  kilobytes: 'KB',
  megabytes: 'MB',
  gigabytes: 'GB',
  file: 'Fayl',
  lastSeenJustNow: 'hozirgina onlayn edi',
  lastSeenMinutes: (n) => '$n daqiqa oldin onlayn edi',
  lastSeenToday: (t) => 'bugun $t da onlayn edi',
  lastSeenYesterday: (t) => 'kecha $t da onlayn edi',
  lastSeenOn: (d) => '$d da onlayn edi',
  chatsCount: (n) => '$n ta chat',
  filesCount: (n) => '$n ta fayl',
);

const _ruMonths = [
  'января', 'февраля', 'марта', 'апреля', 'мая', 'июня', //
  'июля', 'августа', 'сентября', 'октября', 'ноября', 'декабря',
];
const _ruMonthsShort = ['янв', 'фев', 'мар', 'апр', 'мая', 'июн', 'июл', 'авг', 'сен', 'окт', 'ноя', 'дек'];

final commonRu = CommonStrings(
  cancel: 'Отмена',
  save: 'Сохранить',
  close: 'Закрыть',
  delete: 'Удалить',
  edit: 'Изменить',
  create: 'Создать',
  add: 'Добавить',
  send: 'Отправить',
  open: 'Открыть',
  back: 'Назад',
  search: 'Поиск',
  yes: 'Да',
  no: 'Нет',
  ok: 'OK',
  retry: 'Повторить',
  today: 'Сегодня',
  yesterday: 'Вчера',
  tomorrow: 'Завтра',
  months: _ruMonths,
  monthsShort: _ruMonthsShort,
  weekdaysShort: const ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'],
  weekdays: const ['Понедельник', 'Вторник', 'Среда', 'Четверг', 'Пятница', 'Суббота', 'Воскресенье'],
  dayMonth: (d, m) => '$d ${_ruMonths[m - 1]}',
  dayMonthYear: (d, m, y) => '$d ${_ruMonths[m - 1]} $y',
  dayMonthShort: (d, m) => '$d ${_ruMonthsShort[m - 1]}',
  decimalSeparator: ',',
  bytes: 'Б',
  kilobytes: 'КБ',
  megabytes: 'МБ',
  gigabytes: 'ГБ',
  file: 'Файл',
  lastSeenJustNow: 'был(а) в сети только что',
  lastSeenMinutes: (n) => 'был(а) в сети $n ${ruPlural(n, 'минуту', 'минуты', 'минут')} назад',
  lastSeenToday: (t) => 'был(а) в сети сегодня в $t',
  lastSeenYesterday: (t) => 'был(а) в сети вчера в $t',
  lastSeenOn: (d) => 'был(а) в сети $d',
  chatsCount: (n) => '$n ${ruPlural(n, 'чат', 'чата', 'чатов')}',
  filesCount: (n) => '$n ${ruPlural(n, 'файл', 'файла', 'файлов')}',
);

const _enMonths = [
  'January', 'February', 'March', 'April', 'May', 'June', //
  'July', 'August', 'September', 'October', 'November', 'December',
];

final commonEn = CommonStrings(
  cancel: 'Cancel',
  save: 'Save',
  close: 'Close',
  delete: 'Delete',
  edit: 'Edit',
  create: 'Create',
  add: 'Add',
  send: 'Send',
  open: 'Open',
  back: 'Back',
  search: 'Search',
  yes: 'Yes',
  no: 'No',
  ok: 'OK',
  retry: 'Try again',
  today: 'Today',
  yesterday: 'Yesterday',
  tomorrow: 'Tomorrow',
  months: _enMonths,
  monthsShort: [for (final m in _enMonths) m.substring(0, 3)],
  weekdaysShort: const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'],
  weekdays: const ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'],
  dayMonth: (d, m) => '${_enMonths[m - 1]} $d',
  dayMonthYear: (d, m, y) => '${_enMonths[m - 1]} $d, $y',
  dayMonthShort: (d, m) => '${_enMonths[m - 1].substring(0, 3)} $d',
  decimalSeparator: '.',
  bytes: 'B',
  kilobytes: 'KB',
  megabytes: 'MB',
  gigabytes: 'GB',
  file: 'File',
  lastSeenJustNow: 'last seen just now',
  lastSeenMinutes: (n) => 'last seen $n ${enPlural(n, 'minute', 'minutes')} ago',
  lastSeenToday: (t) => 'last seen today at $t',
  lastSeenYesterday: (t) => 'last seen yesterday at $t',
  lastSeenOn: (d) => 'last seen $d',
  chatsCount: (n) => '$n ${enPlural(n, 'chat', 'chats')}',
  filesCount: (n) => '$n ${enPlural(n, 'file', 'files')}',
);

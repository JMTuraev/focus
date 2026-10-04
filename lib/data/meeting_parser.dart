/// A meeting time found in a message ("ertaga soat 10:00 da", "завтра в 14:30").
class Meeting {
  const Meeting(this.at, this.label);

  final DateTime at;

  /// e.g. "Payshanba, 8-okt · 15:00".
  final String label;
}

/// Finds a meeting (a day plus a time) in Uzbek (Latin and Cyrillic) or
/// Russian text. Both a day ("ertaga", "payshanba", "12-oktabr", "15.10")
/// and a time ("15:00", "soat 9", "в 14") are required, so prices and
/// deadlines like "15:00 gacha" alone are not taken for meetings.
class MeetingParser {
  static const weekdayNames = ['Dushanba', 'Seshanba', 'Chorshanba', 'Payshanba', 'Juma', 'Shanba', 'Yakshanba'];
  static const _monthShort = ['yan', 'fev', 'mar', 'apr', 'may', 'iyun', 'iyul', 'avg', 'sen', 'okt', 'noy', 'dek'];

  // Words must not be glued to other letters (works for Cyrillic too).
  static RegExp _word(String alts) => RegExp('(?<!\\p{L})(?:$alts)(?!\\p{L})', unicode: true, caseSensitive: false);

  static final _relative = <RegExp, int>{
    _word('indinga|индинга|послезавтра'): 2,
    _word('ertaga|эртага|завтра'): 1,
    _word('bugun|бугун|сегодня'): 0,
  };

  static final _weekdays = <RegExp, int>{
    _word('dushanba|душанба|понедельник\\p{L}*'): 1,
    _word('seshanba|сешанба|вторник\\p{L}*'): 2,
    _word('chorshanba|чоршанба|сред[аеуы]'): 3,
    _word('payshanba|пайшанба|четверг\\p{L}*'): 4,
    _word('juma|жума|пятниц[аеуы]'): 5,
    _word('shanba|шанба|суббот[аеуы]'): 6,
    _word('yakshanba|якшанба|воскресень[еяю]'): 7,
  };

  static const _monthStems = [
    'yanvar|январ\\p{L}*',
    'fevral|феврал\\p{L}*',
    'mart|март\\p{L}*',
    'aprel|апрел\\p{L}*',
    'may|май|мая',
    'iyun|июн\\p{L}*',
    'iyul|июл\\p{L}*',
    'avgust|август\\p{L}*',
    'sentabr|sentyabr|сентябр\\p{L}*',
    'oktabr|октябр\\p{L}*',
    'noyabr|ноябр\\p{L}*',
    'dekabr|декабр\\p{L}*',
  ];

  static final _monthDate = [
    for (final stem in _monthStems)
      RegExp('(?<!\\d)(\\d{1,2})\\s*[-–]?\\s*(?:$stem)(?!\\p{L})', unicode: true, caseSensitive: false),
  ];

  static final _numericDate = RegExp(r'(?<![\d.])(\d{1,2})\.(\d{1,2})(?:\.(\d{2,4}))?(?![\d.])');

  static final _clock = RegExp(r'(?<![\d.:])([01]?\d|2[0-3]):([0-5]\d)(?![\d:])');

  static final _prefixedHour = RegExp(
    '(?<!\\p{L})(?:soat|соат|в)\\s+([01]?\\d|2[0-3])(?:[.:]([0-5]\\d))?(?![\\d:])',
    unicode: true,
    caseSensitive: false,
  );

  static final _afternoon = _word('tushdan keyin|kechqurun|kechki|тушдан кейин|кечқурун|кечкурун|после обеда|вечером|вечера|дня');

  /// The first meeting in [text]; relative days count from [ref]
  /// (usually the message date).
  static Meeting? parse(String text, DateTime ref) {
    if (text.isEmpty) return null;

    // ---- time ----
    int? hour;
    var minute = 0;
    final clock = _clock.firstMatch(text);
    if (clock != null) {
      hour = int.parse(clock.group(1)!);
      minute = int.parse(clock.group(2)!);
    } else {
      final p = _prefixedHour.firstMatch(text);
      if (p != null) {
        hour = int.parse(p.group(1)!);
        minute = int.tryParse(p.group(2) ?? '') ?? 0;
      }
    }
    if (hour == null) return null;
    if (hour < 12 && _afternoon.hasMatch(text)) hour += 12;

    // ---- day ----
    final today = DateTime(ref.year, ref.month, ref.day);
    DateTime? day;
    for (final e in _relative.entries) {
      if (e.key.hasMatch(text)) {
        day = today.add(Duration(days: e.value));
        break;
      }
    }
    if (day == null) {
      for (var m = 0; m < 12 && day == null; m++) {
        final match = _monthDate[m].firstMatch(text);
        if (match != null) day = _dated(int.parse(match.group(1)!), m + 1, null, today);
      }
    }
    if (day == null && clock != null) {
      // "15.10" only next to a real "HH:MM" time, so "12.500" is not a date.
      final n = _numericDate.firstMatch(text.replaceRange(clock.start, clock.end, ' '));
      if (n != null) {
        final month = int.parse(n.group(2)!);
        if (month >= 1 && month <= 12) {
          final y = n.group(3);
          day = _dated(int.parse(n.group(1)!), month, y == null ? null : int.parse(y.length == 2 ? '20$y' : y), today);
        }
      }
    }
    if (day == null) {
      for (final e in _weekdays.entries) {
        if (e.key.hasMatch(text)) {
          var delta = (e.value - ref.weekday + 7) % 7;
          final sameDayPassed = delta == 0 && (hour < ref.hour || (hour == ref.hour && minute <= ref.minute));
          if (sameDayPassed) delta = 7;
          day = today.add(Duration(days: delta));
          break;
        }
      }
    }
    if (day == null) return null;

    final at = DateTime(day.year, day.month, day.day, hour, minute);
    return Meeting(at, label(at));
  }

  /// A day/month without a year: this year, or next year if it is long past.
  static DateTime? _dated(int d, int m, int? y, DateTime today) {
    if (d < 1 || d > 31) return null;
    var date = DateTime(y ?? today.year, m, d);
    if (date.month != m) return null; // e.g. 31-fevral
    if (y == null && today.difference(date).inDays > 30) date = DateTime(today.year + 1, m, d);
    return date;
  }

  /// "Payshanba, 8-okt · 15:00".
  static String label(DateTime at) {
    final hh = at.hour.toString().padLeft(2, '0');
    final mm = at.minute.toString().padLeft(2, '0');
    return '${weekdayNames[at.weekday - 1]}, ${at.day}-${_monthShort[at.month - 1]} · $hh:$mm';
  }
}

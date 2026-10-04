import 'package:flutter/widgets.dart';

/// Uzbek date/time texts and avatar helpers shared by data sources and UI.
class Fmt {
  static const _weekdays = ['Dush', 'Sesh', 'Chor', 'Pay', 'Jum', 'Shan', 'Yak'];
  static const _months = [
    'yanvar', 'fevral', 'mart', 'aprel', 'may', 'iyun', //
    'iyul', 'avgust', 'sentabr', 'oktabr', 'noyabr', 'dekabr',
  ];

  /// "oktabr".
  static String monthName(int month) => _months[month - 1];

  /// "Dush".
  static String weekdayShort(int weekday) => _weekdays[weekday - 1];

  static String two(int n) => n.toString().padLeft(2, '0');

  static String hm(DateTime d) => '${two(d.hour)}:${two(d.minute)}';

  static DateTime _day(DateTime d) => DateTime(d.year, d.month, d.day);

  /// Chat list time: "14:32", "Kecha", "Pay", "12.09.26".
  static String listTime(DateTime d, {DateTime? now}) {
    final today = _day(now ?? DateTime.now());
    final days = today.difference(_day(d)).inDays;
    if (days <= 0) return hm(d);
    if (days == 1) return 'Kecha';
    if (days < 7) return _weekdays[d.weekday - 1];
    return '${two(d.day)}.${two(d.month)}.${two(d.year % 100)}';
  }

  /// Date separator in a chat: "Bugun", "Kecha", "12-oktabr", "12-oktabr, 2025".
  static String dayLabel(DateTime d, {DateTime? now}) {
    final n = now ?? DateTime.now();
    final days = _day(n).difference(_day(d)).inDays;
    if (days == 0) return 'Bugun';
    if (days == 1) return 'Kecha';
    final base = '${d.day}-${_months[d.month - 1]}';
    return d.year == n.year ? base : '$base, ${d.year}';
  }

  /// Due date: "Bugun", "Ertaga", "Kecha", "12-okt", "12-okt 2027".
  static String dueLabel(DateTime d, {DateTime? now}) {
    final n = now ?? DateTime.now();
    final days = _day(d).difference(_day(n)).inDays;
    if (days == 0) return 'Bugun';
    if (days == 1) return 'Ertaga';
    if (days == -1) return 'Kecha';
    final base = '${d.day}-${_months[d.month - 1].substring(0, 3)}';
    return d.year == n.year ? base : '$base ${d.year}';
  }

  static bool sameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;

  /// "3 412" (thin grouping like the mock data).
  static String count(int n) {
    final s = n.toString();
    final b = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) b.write(' ');
      b.write(s[i]);
    }
    return b.toString();
  }

  /// "4,2 MB", "84 KB".
  static String size(int bytes) {
    if (bytes >= 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1).replaceAll('.', ',')} MB';
    }
    if (bytes >= 1024) return '${(bytes / 1024).round()} KB';
    return '$bytes B';
  }

  /// "Last seen" text for a user status, Uzbek.
  static String lastSeen(DateTime wasOnline, {DateTime? now}) {
    final n = now ?? DateTime.now();
    final diff = n.difference(wasOnline);
    if (diff.inMinutes < 1) return 'hozirgina onlayn edi';
    if (diff.inMinutes < 60) return '${diff.inMinutes} daqiqa oldin onlayn edi';
    final days = _day(n).difference(_day(wasOnline)).inDays;
    if (days == 0) return 'bugun ${hm(wasOnline)} da onlayn edi';
    if (days == 1) return 'kecha ${hm(wasOnline)} da onlayn edi';
    return '${two(wasOnline.day)}.${two(wasOnline.month)}.${wasOnline.year} da onlayn edi';
  }

  /// Up to two letters from the first two words ("Dilshod Karimov" → "DK").
  static String initials(String name) {
    final words = name.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    if (words.isEmpty) return '?';
    final first = words[0].characters.first;
    final second = words.length > 1 ? words[1].characters.first : '';
    return (first + second).toUpperCase();
  }

  /// Telegram-like avatar colors, picked from the chat/user id.
  static const avatarColors = [
    Color(0xFFCC4136), // red
    Color(0xFFC2650F), // orange
    Color(0xFF7B55D6), // violet
    Color(0xFF2E7D3A), // green
    Color(0xFF1B7899), // teal
    Color(0xFF2F6FB8), // blue
    Color(0xFFB83A72), // pink
  ];

  static Color avatarColor(int id) => avatarColors[id.abs() % avatarColors.length];
}

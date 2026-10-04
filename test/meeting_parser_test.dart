import 'package:flutter_test/flutter_test.dart';
import 'package:fokus/data/meeting_parser.dart';

void main() {
  // Sunday, 4 October 2026, 10:00.
  final ref = DateTime(2026, 10, 4, 10);

  DateTime? at(String text, [DateTime? r]) => MeetingParser.parse(text, r ?? ref)?.at;

  test('Uzbek Latin', () {
    expect(at('Payshanba soat 15:00 da demo qilsak bo‘ladimi?'), DateTime(2026, 10, 8, 15));
    expect(at('Ertaga soat 10:00 da uchrashamizmi?'), DateTime(2026, 10, 5, 10));
    expect(at('Dushanba tushdan keyin, 14:30 da gaplashsak bo‘ladimi?'), DateTime(2026, 10, 5, 14, 30));
    expect(at('bugun soat 3 da kechqurun kelaman'), DateTime(2026, 10, 4, 15));
    expect(at('indinga 09:15'), DateTime(2026, 10, 6, 9, 15));
    expect(at('12-oktabr soat 11:00'), DateTime(2026, 10, 12, 11));
    expect(at('Shanba 18:00'), DateTime(2026, 10, 10, 18));
  });

  test('Uzbek Cyrillic and Russian', () {
    expect(at('эртага соат 9 да'), DateTime(2026, 10, 5, 9));
    expect(at('Пайшанба 16:00 да учрашамиз'), DateTime(2026, 10, 8, 16));
    expect(at('Завтра в 14:30 созвон'), DateTime(2026, 10, 5, 14, 30));
    expect(at('12 октября в 18'), DateTime(2026, 10, 12, 18));
    expect(at('в среду в 10'), DateTime(2026, 10, 7, 10));
    expect(at('послезавтра в 11:00'), DateTime(2026, 10, 6, 11));
    expect(at('в пятницу в 3 часа дня'), DateTime(2026, 10, 9, 15));
  });

  test('numeric dates only next to a clock time', () {
    expect(at('15.10 da 16:00 da kelaman'), DateTime(2026, 10, 15, 16));
    expect(at('Narxi 12.500 so‘m, 15:00 gacha to‘lang'), isNull);
  });

  test('no meeting without both a day and a time', () {
    expect(at('Hisobotni 15:00 gacha yuboring'), isNull);
    expect(at('Ertaga gaplashamiz'), isNull);
    expect(at('Средства поступят в 10:00'), isNull, reason: '"Средства" is not "среда"');
    expect(at('Sotuvlar 2 baravar oshdi'), isNull);
    expect(at(''), isNull);
  });

  test('same weekday: today if still ahead, otherwise next week', () {
    final thursday = DateTime(2026, 10, 8, 12);
    expect(at('payshanba 15:00', thursday), DateTime(2026, 10, 8, 15));
    expect(at('payshanba 11:00', thursday), DateTime(2026, 10, 15, 11));
  });

  test('dates long past roll over to next year', () {
    expect(at('5-yanvar 10:00', DateTime(2026, 12, 20)), DateTime(2027, 1, 5, 10));
  });

  test('label', () {
    expect(MeetingParser.parse('Payshanba soat 15:00 da', ref)!.label, 'Payshanba, 8-okt · 15:00');
  });
}

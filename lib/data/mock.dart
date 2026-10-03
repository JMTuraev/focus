import 'package:flutter/material.dart';

import 'models.dart';

const kCollections = <Collection>[
  Collection('all', 'Hammasi', Icons.forum_outlined),
  Collection('mijoz', 'Mijozlar', Icons.person_outline),
  Collection('ish', 'Ish', Icons.work_outline),
  Collection('jamoa', 'Jamoa', Icons.groups_outlined),
  Collection('hamkor', 'Hamkorlar', Icons.handshake_outlined),
  Collection('moliya', 'Moliya', Icons.account_balance_wallet_outlined),
  Collection('oila', 'Oila', Icons.home_outlined),
  Collection('hamjam', 'Hamjamiyatlar', Icons.public),
];

const _orange = Color(0xFFC2650F);
const _violet = Color(0xFF7B55D6);
const _blue = Color(0xFF2F6FB8);
const _green = Color(0xFF2E7D3A);
const _pink = Color(0xFFB83A72);
const _teal = Color(0xFF1B7899);
const _red = Color(0xFFCC4136);

const kChats = <Chat>[
  Chat(id: 'dilshod', name: 'Dilshod Karimov', initials: 'DK', color: _orange, collection: 'mijoz', last: 'Narxlarni PDF’da yuboring, iltimos', time: '14:32', unread: 2, waiting: true, online: true, status: 'online', phone: '+998 90 512 34 67', about: '«Olimp» fitnes klublari, 3 ta filial'),
  Chat(id: 'madina', name: 'Madina Rahimova', initials: 'MR', color: _violet, collection: 'ish', last: 'Ertaga soat 10:00 da uchrashamizmi?', time: '14:05', unread: 1, waiting: true, online: true, status: 'online', phone: '+998 91 220 18 05', about: 'Dizayner, Xposter loyihasi'),
  Chat(id: 'team', name: 'AllClubs jamoasi', initials: 'AC', color: _blue, collection: 'jamoa', last: 'Sardor: Reliz tayyor, test qilyapmiz', time: '13:48', unread: 5, status: '8 a’zo, 3 tasi online', about: 'AllClubs ishlab chiqish jamoasi'),
  Chat(id: 'bekzod', name: 'Bekzod Toshmatov', initials: 'BT', color: _green, collection: 'hamkor', last: 'Shartnoma loyihasini ko‘rib chiqdim', time: '12:20', waiting: true, status: '1 soat oldin onlayn edi', phone: '+998 93 471 09 22', about: 'Hamkor, «Buxoro Sport Invest»'),
  Chat(id: 'onam', name: 'Onam', initials: 'O', color: _pink, collection: 'oila', last: 'Kechqurun kelasanmi?', time: '11:57', unread: 1, waiting: true, status: 'yaqinda onlayn edi', phone: '+998 90 700 11 22', about: 'Oila'),
  Chat(id: 'buxg', name: 'Buxgalteriya', initials: 'BX', color: _teal, collection: 'moliya', last: 'Oktabr hisob-fakturasi ilova qilindi', time: '11:10', status: '4 a’zo', about: 'Moliya va hisob-kitob'),
  Chat(id: 'nodira', name: 'Nodira Yusupova', initials: 'NY', color: _red, collection: 'mijoz', last: 'Rahmat, hammasi aniq bo‘ldi', time: '10:42', online: true, status: 'online', phone: '+998 97 330 45 12', about: '«Fit Lady» studiyasi'),
  Chat(id: 'flutter', name: 'Flutter Uzbekistan', initials: 'FU', color: _teal, collection: 'hamjam', last: 'Aziz: Riverpod 3 haqida kim yozadi?', time: '10:15', unread: 24, muted: true, status: '3 412 a’zo', about: 'Flutter dasturchilar hamjamiyati'),
  Chat(id: 'sardor', name: 'Sardor Aliyev', initials: 'SA', color: _blue, collection: 'jamoa', last: 'Build Codemagic’da o‘tdi', time: '09:30', status: '20 daqiqa oldin onlayn edi', phone: '+998 99 811 62 40', about: 'Backend dasturchi'),
  Chat(id: 'jasur', name: 'Jasur Ergashev', initials: 'JE', color: _violet, collection: 'hamkor', last: 'Siz: Kelishdik, dushanba kuni', time: 'Kecha', status: 'kecha onlayn edi', phone: '+998 94 116 72 08', about: 'Hamkor, reklama agentligi'),
  Chat(id: 'kamola', name: 'Kamola Nurmatova', initials: 'KN', color: _orange, collection: 'mijoz', last: 'To‘lov qilindi, chekni yubordim', time: 'Kecha', waiting: true, status: 'kecha onlayn edi', phone: '+998 90 245 80 31', about: '«Energy Gym» egasi'),
  Chat(id: 'rustam', name: 'Rustam akam', initials: 'RA', color: _green, collection: 'oila', last: 'Rasmlarni yubordim', time: 'Kecha', status: 'yaqinda onlayn edi', phone: '+998 91 404 22 19', about: 'Oila'),
  Chat(id: 'shahzod', name: 'Shahzod Qodirov', initials: 'SQ', color: _red, collection: 'moliya', last: 'Siz: Kredit jadvalini yubordim', time: 'Pay', status: '2 kun oldin onlayn edi', phone: '+998 93 551 07 66', about: 'Bank menejeri'),
  Chat(id: 'itpark', name: 'Buxoro IT Park', initials: 'IT', color: _blue, collection: 'hamjam', last: 'Hackathon 12-oktabrda bo‘ladi', time: 'Pay', unread: 3, muted: true, status: '1 208 obunachi', about: 'Rasmiy kanal'),
];

const kMessages = <String, List<Message>>{
  'dilshod': [
    Message(id: 'd1', text: 'Assalomu alaykum, Jafar aka! Zalimiz uchun AllClubs tizimini ko‘rib chiqyapmiz.', time: '13:58'),
    Message(id: 'd2', text: 'Bizda 3 ta filial bor, 450 ga yaqin a’zo. Abonement va kirish nazorati kerak.', time: '13:59'),
    Message(id: 'd3', out: true, text: 'Va alaykum assalom! 3 ta filial uchun «Biznes» tarifi to‘g‘ri keladi. Demo ko‘rsatib beraman.', time: '14:10'),
    Message(id: 'd4', out: true, text: 'Qisqacha taqdimot:', time: '14:11', fileName: 'AllClubs_taqdimot.pdf', fileMeta: '2,4 MB · PDF'),
    Message(id: 'd5', text: 'Zo‘r. Payshanba soat 15:00 da demo qilsak bo‘ladimi?', time: '14:25', meeting: 'Payshanba, 8-okt · 15:00'),
    Message(id: 'd6', text: 'Narxlarni PDF’da yuboring, iltimos. Rahbariyatga ko‘rsataman.', time: '14:32'),
  ],
  'madina': [
    Message(id: 'm1', out: true, text: 'Madina, Xposter menyusi uchun yangi kartochka dizayni kerak bo‘ladi.', time: '13:40'),
    Message(id: 'm2', text: 'Tushundim, eskizlarni tayyorlab qo‘ydim.', time: '13:52', fileName: 'menyu_eskiz_v2.png', fileMeta: '1,1 MB · Rasm'),
    Message(id: 'm3', text: 'Ertaga soat 10:00 da uchrashamizmi?', time: '14:05', meeting: 'Yakshanba, 4-okt · 10:00'),
  ],
  'team': [
    Message(id: 't1', from: 'Sardor Aliyev', text: 'Codemagic’da build o‘tdi, TestFlight’ga yuklandi.', time: '13:20'),
    Message(id: 't2', from: 'Malika Jo‘rayeva', text: 'Kirish nazorati moduli bo‘yicha 2 ta xato yopildi.', time: '13:31'),
    Message(id: 't3', out: true, text: 'Zo‘r! Bugun kechgacha reliz qilamiz.', time: '13:40'),
    Message(id: 't4', from: 'Sardor Aliyev', text: 'Reliz tayyor, test qilyapmiz.', time: '13:48'),
  ],
  'bekzod': [
    Message(id: 'b1', out: true, text: 'Bekzod aka, hamkorlik shartnomasining yangi variantini yubordim.', time: '11:30', fileName: 'Hamkorlik_shartnomasi_v3.docx', fileMeta: '84 KB · Shartnoma'),
    Message(id: 'b2', text: 'Dushanba tushdan keyin, 14:30 da gaplashsak bo‘ladimi?', time: '12:15', meeting: 'Dushanba, 5-okt · 14:30'),
    Message(id: 'b3', text: 'Shartnoma loyihasini ko‘rib chiqdim, 2 ta izohim bor.', time: '12:20'),
  ],
};

/// Fallback conversation for chats without scripted messages.
List<Message> fallbackMessages(Chat c) {
  var text = c.last;
  var out = false;
  String? from;
  if (text.startsWith('Siz: ')) {
    text = text.substring(5);
    out = true;
  } else if (c.status.contains('a’zo') && text.contains(': ')) {
    final i = text.indexOf(': ');
    from = text.substring(0, i);
    text = text.substring(i + 2);
  }
  final time = c.time.contains(':') ? c.time : '18:40';
  return [
    Message(id: '${c.id}0', text: 'Assalomu alaykum!', time: '09:02'),
    Message(id: '${c.id}1', text: text, time: time, out: out, from: from),
  ];
}

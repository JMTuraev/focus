// Text formatting, media mapping and group sender layout.
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fokus/auth/mock_auth.dart';
import 'package:fokus/data/chat_source.dart';
import 'package:fokus/data/local_store.dart';
import 'package:fokus/data/models.dart';
import 'package:fokus/main.dart';
import 'package:fokus/state/settings.dart';
import 'package:fokus/tdlib/td_chats.dart';
import 'package:fokus/theme.dart';
import 'package:fokus/ui/chats/message_text.dart';

import 'helpers/fonts.dart';
import 'td_chats_test.dart' show FakeTd, groupChat, me, privateChat, started, text, user;

/// Packs 5-bit values the way Telegram does, to test the decoder.
String encodeWaveform(List<int> values) {
  final bytes = Uint8List((values.length * 5 + 7) ~/ 8);
  for (var i = 0; i < values.length; i++) {
    final bit = i * 5;
    final v = values[i] << (bit & 7);
    bytes[bit >> 3] |= v & 0xFF;
    if ((bit >> 3) + 1 < bytes.length) bytes[(bit >> 3) + 1] |= (v >> 8) & 0xFF;
  }
  return base64Encode(bytes);
}

Widget _themed(Widget child) => MaterialApp(theme: buildTheme(Brightness.light), home: Scaffold(body: Center(child: child)));

void main() {
  setUpAll(loadSegoeUi);

  group('entities', () {
    test('Telegram entity types map to formatting', () {
      final list = TdChatSource.entitiesOf({
        'text': 'x',
        'entities': [
          {'offset': 0, 'length': 4, 'type': {'@type': 'textEntityTypeBold'}},
          {'offset': 5, 'length': 3, 'type': {'@type': 'textEntityTypeTextUrl', 'url': 'https://t.me'}},
          {'offset': 9, 'length': 2, 'type': {'@type': 'textEntityTypeSpoiler'}},
          {'offset': 12, 'length': 5, 'type': {'@type': 'textEntityTypeCustomEmoji', 'custom_emoji_id': '1'}},
          {'offset': 18, 'length': 9, 'type': {'@type': 'textEntityTypeEmailAddress'}},
        ],
      });
      expect(list.map((e) => e.kind), [EntityKind.bold, EntityKind.textUrl, EntityKind.spoiler, EntityKind.url]);
      expect(list[1].url, 'https://t.me');
      expect(list[3].url, 'mailto:');
    });

    test('voice waveform is unpacked from 5-bit values', () {
      final values = [0, 31, 5, 17, 8, 30, 1, 22, 9, 12];
      expect(TdChatSource.decodeWaveform(encodeWaveform(values)).take(values.length), values);
      expect(TdChatSource.decodeWaveform(null), isEmpty);
    });

    test('only safe link schemes are opened', () {
      const url = TextEntity(0, 10, EntityKind.url);
      expect(linkTarget(url, 'allclubs.uz')!.toString(), 'https://allclubs.uz');
      expect(linkTarget(const TextEntity(0, 1, EntityKind.textUrl, url: 'javascript:alert(1)'), 'bosing'), isNull);
      expect(linkTarget(const TextEntity(0, 1, EntityKind.textUrl, url: 'file:///C:/x.exe'), 'bosing'), isNull);
      expect(linkTarget(const TextEntity(0, 1, EntityKind.url, url: 'mailto:'), 'a@b.uz')!.scheme, 'mailto');
    });
  });

  group('MessageText', () {
    testWidgets('bold, link and a spoiler that opens on tap', (tester) async {
      const t = 'Salom dunyo havola yashirin';
      await tester.pumpWidget(_themed(const MessageText(
        t,
        entities: [
          TextEntity(0, 5, EntityKind.bold),
          TextEntity(12, 6, EntityKind.url),
          TextEntity(19, 8, EntityKind.spoiler),
        ],
        style: TextStyle(fontSize: 14),
      )));
      final rich = tester.widget<RichText>(find.byType(RichText).last);
      final spans = <TextSpan>[];
      rich.text.visitChildren((s) {
        if (s is TextSpan && s.text != null) spans.add(s);
        return true;
      });
      final bold = spans.firstWhere((s) => s.text == 'Salom');
      expect(bold.style!.fontWeight, FontWeight.w700);
      expect(spans.firstWhere((s) => s.text == 'havola').recognizer, isNotNull);
      final spoiler = spans.firstWhere((s) => s.text == 'yashirin');
      expect(spoiler.style!.color, Colors.transparent);

      await tester.tapOnText(find.textRange.ofSubstring('yashirin'));
      await tester.pump();
      final after = <TextSpan>[];
      tester.widget<RichText>(find.byType(RichText).last).text.visitChildren((s) {
        if (s is TextSpan && s.text != null) after.add(s);
        return true;
      });
      expect(after.firstWhere((s) => s.text == 'yashirin').style!.color, isNot(Colors.transparent));
    });
  });

  group('media mapping', () {
    test('photo picks a ~800px preview and the largest file, progress follows updateFile', () async {
      final (td, source) = await started(setup: (td) {
        td.handlers['getChatHistory'] = (r) => r['from_message_id'] == 0
            ? {
                'messages': [
                  {
                    ...text(1, 5, ''),
                    'content': {
                      '@type': 'messagePhoto',
                      'caption': {'text': 'Zal', 'entities': []},
                      'photo': {
                        'minithumbnail': {'width': 40, 'height': 30, 'data': base64Encode([1, 2, 3])},
                        'sizes': [
                          {'type': 'm', 'width': 320, 'height': 240, 'photo': {'id': 1, 'size': 10, 'local': {}}},
                          {'type': 'x', 'width': 800, 'height': 600, 'photo': {'id': 2, 'size': 80, 'local': {}}},
                          {'type': 'y', 'width': 1280, 'height': 960, 'photo': {'id': 3, 'size': 200, 'local': {}}},
                        ],
                      },
                    },
                  },
                  {
                    ...text(1, 4, ''),
                    'content': {
                      '@type': 'messageVoiceNote',
                      'voice_note': {
                        'duration': 7,
                        'waveform': encodeWaveform([3, 9, 27]),
                        'voice': {'id': 9, 'size': 5000, 'local': {}},
                      },
                    },
                  },
                ],
              }
            : {'messages': []};
      });
      td.push({'@type': 'updateNewChat', 'chat': privateChat(1, 'Dilshod', order: 10)});
      await source.open('1');

      final photo = source.messagesOf('1').last;
      expect(photo.text, 'Zal');
      expect(photo.info!.kind, MediaKind.photo);
      expect(photo.info!.previewFileId, 2);
      expect(photo.info!.fileId, 3);
      expect(photo.info!.aspect, closeTo(4 / 3, 0.001));
      expect(photo.info!.mini, isNotNull);

      final voice = source.messagesOf('1').first;
      expect(voice.info!.kind, MediaKind.voice);
      expect(voice.info!.duration, 7);
      expect(voice.info!.waveform.take(3), [3, 9, 27]);

      td.push({
        '@type': 'updateFile',
        'file': {'id': 9, 'size': 5000, 'local': {'downloaded_size': 2500, 'is_downloading_active': true}},
      });
      expect(source.messagesOf('1').first.info!.progress, 0.5);
      td.push({
        '@type': 'updateFile',
        'file': {'id': 9, 'size': 5000, 'local': {'downloaded_size': 5000, 'is_downloading_completed': true, 'path': r'C:\v.oga'}},
      });
      expect(source.messagesOf('1').first.info!.filePath, r'C:\v.oga');

      source.download(3, priority: 32);
      await Future<void>.delayed(Duration.zero);
      final req = td.sent('downloadFile').where((r) => r['file_id'] == 3).single;
      expect(req['priority'], 32);
    });

    test('group messages carry sender id, color and initials', () async {
      final (td, source) = await started(setup: (td) {
        td.handlers['getChatHistory'] = (r) => r['from_message_id'] == 0
            ? {'messages': [text(-9, 2, 'Salom', sender: 5)]}
            : {'messages': []};
      });
      td.push({'@type': 'updateUser', 'user': {...user(5, 'Sardor', last: 'Aliyev'), 'accent_color_id': 3}});
      td.push({'@type': 'updateNewChat', 'chat': groupChat(-9, 'Jamoa', order: 5)});
      await source.open('-9');
      final m = source.messagesOf('-9').single;
      expect(m.senderId, '5');
      expect(m.senderColor, 3);
      expect(m.senderInitials, 'SA');
      expect(me, isNonZero);
    });
  });

  testWidgets('group chat shows colored names once per run and avatars', (tester) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(FokusApp(settings: Settings.inMemory(ThemeMode.light), auth: MockAuth(loggedIn: true)));
    await tester.pumpAndSettle();
    await tester.tap(find.text('AllClubs jamoasi').first);
    await tester.pumpAndSettle();

    // Malika wrote two messages in a row: her name is shown once.
    expect(find.text('Malika Jo‘rayeva'), findsOneWidget);
    // Avatars: Sardor (t1), Malika (end of her run), Sardor (t4).
    Finder inChat(String t) => find.descendant(of: find.byType(SelectionArea), matching: find.text(t));
    expect(inChat('MJ'), findsOneWidget);
    expect(inChat('SA'), findsNWidgets(2));
    expect(tester.takeException(), isNull);
  });

  testWidgets('photo viewer opens on click and closes with Escape', (tester) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final td = FakeTd();
    td.handlers['getMe'] = (_) => user(me, 'Men');
    td.handlers['loadChats'] = (_) => throw Exception('done');
    td.handlers['getChatHistory'] = (r) => r['from_message_id'] == 0
        ? {
            'messages': [
              {
                ...text(1, 3, ''),
                'content': {
                  '@type': 'messagePhoto',
                  'photo': {
                    'sizes': [
                      {'width': 800, 'height': 600, 'photo': {'id': 1, 'local': <String, dynamic>{}}},
                    ],
                  },
                  'caption': {'text': 'Rasm izohi'},
                },
              },
            ],
          }
        : {'messages': []};
    await tester.pumpWidget(FokusApp(settings: Settings.inMemory(ThemeMode.light), auth: _TdMockAuth(td)));
    await tester.pumpAndSettle();
    td.push({'@type': 'updateNewChat', 'chat': privateChat(1, 'Rasmli chat', order: 5)});
    await tester.pumpAndSettle();
    await tester.tap(find.text('Rasmli chat').first);
    await tester.pumpAndSettle();

    await tester.tap(find.byType(ClipRRect).last);
    // The viewer shows a spinner while the full photo loads: no pumpAndSettle.
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byTooltip('Yopish (Esc)'), findsOneWidget);

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byTooltip('Yopish (Esc)'), findsNothing);

    // Clicking the dark area around the photo closes it as well.
    await tester.tap(find.byType(ClipRRect).last);
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byTooltip('Yopish (Esc)'), findsOneWidget);
    await tester.tapAt(const Offset(10, 400));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byTooltip('Yopish (Esc)'), findsNothing);
  });

  for (final size in const [Size(1440, 900), Size(800, 600), Size(420, 560)]) {
    testWidgets('media messages lay out at ${size.width.toInt()}x${size.height.toInt()}', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final td = FakeTd();
      td.handlers['getMe'] = (_) => user(me, 'Men');
      td.handlers['loadChats'] = (_) => throw Exception('done');
      final media = [
        {'@type': 'messagePhoto', 'photo': {'sizes': [{'width': 1280, 'height': 400, 'photo': {'id': 1, 'local': {}}}]}, 'caption': {'text': ''}},
        {'@type': 'messageVideo', 'video': {'duration': 75, 'width': 720, 'height': 1280, 'video': {'id': 2, 'local': {}}}, 'caption': {'text': 'Video'}},
        {'@type': 'messageVoiceNote', 'voice_note': {'duration': 12, 'waveform': '', 'voice': {'id': 3, 'local': {}}}},
        {'@type': 'messageSticker', 'sticker': {'width': 512, 'height': 512, 'format': {'@type': 'stickerFormatWebp'}, 'sticker': {'id': 4, 'local': {}}}},
        {'@type': 'messageVideoNote', 'video_note': {'duration': 9, 'length': 240, 'video': {'id': 5, 'local': {}}}},
      ];
      td.handlers['getChatHistory'] = (r) => r['from_message_id'] == 0
          ? {
              'messages': [
                for (var i = 0; i < media.length; i++) {...text(-9, 10 - i, '', sender: 5), 'content': media[i]},
              ],
            }
          : {'messages': []};
      final auth = _TdMockAuth(td);
      await tester.pumpWidget(FokusApp(settings: Settings.inMemory(ThemeMode.dark), auth: auth));
      await tester.pumpAndSettle();
      td.push({'@type': 'updateUser', 'user': user(5, 'Sardor')});
      td.push({'@type': 'updateNewChat', 'chat': groupChat(-9, 'Media guruhi', order: 5)});
      await tester.pumpAndSettle();
      await tester.tap(find.text('Media guruhi').first);
      await tester.pumpAndSettle();
      expect(find.text('1:15'), findsOneWidget, reason: 'video duration');
      // Small windows: scroll up to the voice message first.
      await tester.scrollUntilVisible(
        find.text('0:12'),
        150,
        scrollable: find.descendant(of: find.byType(SelectionArea), matching: find.byType(Scrollable)).first,
      );
      expect(find.text('0:12'), findsOneWidget, reason: 'voice duration');
      expect(tester.takeException(), isNull);
    });
  }
}

/// MockAuth that is logged in and serves chats from a fake TDLib.
class _TdMockAuth extends MockAuth {
  _TdMockAuth(this.td) : super(loggedIn: true, delay: Duration.zero);

  final FakeTd td;

  @override
  Future<ChatSession> openSession() async {
    final source = TdChatSource(td);
    await source.start(pages: 1);
    return ChatSession(source: source, store: LocalStore.memory());
  }
}

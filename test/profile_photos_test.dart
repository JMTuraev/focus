import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fokus/data/local_store.dart';
import 'package:fokus/data/mock_source.dart';
import 'package:fokus/data/models.dart';
import 'package:fokus/l10n/l10n.dart';
import 'package:fokus/state/app_state.dart';
import 'package:fokus/tdlib/td_client.dart';
import 'package:fokus/theme.dart';
import 'package:fokus/ui/chats/chat_view.dart';
import 'package:fokus/ui/chats/info_panel.dart';
import 'package:fokus/ui/chats/profile_photos.dart';

import 'helpers/fonts.dart';
import 'td_chats_test.dart' as fake;

TdObject _file(int id, {String? path}) => {
      'id': id,
      'size': 100,
      'local': {'path': path ?? '', 'is_downloading_completed': path != null},
    };
TdObject _photo(String id, int fileId) => {
      'id': id,
      'added_date': 1700000000,
      'sizes': [
        {'width': 160, 'height': 160, 'photo': _file(fileId)},
        {'width': 1280, 'height': 1280, 'photo': _file(fileId + 1)},
      ]
    };

const _pixel =
    'iVBORw0KGgoAAAANSUhEUgAAAAgAAAAICAYAAADED76LAAAAAXNSR0IArs4c6QAAAARnQU1BAACxjwv8YQUAAAAJcEhZcwAADsMAAA7DAcdvqGQAAAAWSURBVChTY3DMfPgfH2ZAF0DHw0MBAHmlooHA5OB1AAAAAElFTkSuQmCC';
ProfilePhoto _uiPhoto(int id, {String? path, bool remote = false}) =>
    ProfilePhoto(
        id: '$id',
        media: MediaInfo(
            kind: MediaKind.photo,
            fileId: remote ? id : null,
            filePath: path,
            mini: base64Decode(_pixel)));

class _Source extends MockChatSource {
  final requests = <String>[];
  Future<ProfilePhotoPage> Function(String cursor)? load;
  Future<void> Function(int id)? fetch;
  ProfilePhoto? current;
  final paths = <int, String>{};
  @override
  ProfilePhoto? currentProfilePhoto(String chatId) => current;
  @override
  Future<ProfilePhotoPage> profilePhotos(String chatId,
      {String cursor = ''}) async {
    requests.add('$chatId:$cursor');
    return load != null
        ? await load!(cursor)
        : const ProfilePhotoPage(photos: [], total: 0);
  }

  @override
  Future<void> downloadProfilePhoto(int fileId) async {
    await fetch?.call(fileId);
  }

  @override
  ProfilePhoto refreshProfilePhoto(ProfilePhoto photo) {
    final path = paths[photo.media.fileId];
    return path == null
        ? photo
        : _uiPhoto(int.parse(photo.id), path: path, remote: true);
  }
}

Future<AppState> _pump(WidgetTester tester, _Source source,
    {bool panel = true,
    bool narrow = false,
    AppLanguage language = AppLanguage.uz}) async {
  tester.view.physicalSize =
      narrow ? const Size(420, 560) : const Size(1100, 780);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final state = AppState(
      source: source, store: LocalStore.memory(), initialChatId: 'dilshod');
  addTearDown(() async {
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
    state.dispose();
    source.dispose();
    S.current = S.uz;
  });
  await tester.pumpWidget(LanguageScope(
      language: language,
      child: MaterialApp(
          theme: buildTheme(narrow ? Brightness.dark : Brightness.light),
          home: Scaffold(
              body: ListenableBuilder(
                  listenable: state,
                  builder: (_, __) => panel
                      ? InfoPanel(
                          state: state, onClose: () {}, width: double.infinity)
                      : ChatView(
                          state: state, infoActive: false, onInfo: () {}))))));
  await tester.pumpAndSettle();
  return state;
}

void main() {
  late Directory images;
  late String imagePath;
  setUpAll(() async {
    await loadSegoeUi();
    final codec = await ui.instantiateImageCodec(base64Decode(_pixel));
    final frame = await codec.getNextFrame();
    frame.image.dispose();
    codec.dispose();
    images = await Directory.systemTemp.createTemp('focus_profile_test_');
    final image = File('${images.path}/photo.png');
    await image.writeAsBytes(base64Decode(_pixel));
    imagePath = image.path;
  });
  tearDownAll(() async {
    final prefix =
        '${Directory.systemTemp.absolute.path}${Platform.pathSeparator}focus_profile_test_';
    if (!images.absolute.path.startsWith(prefix)) {
      throw StateError('Unexpected fixture directory');
    }
    await images.delete(recursive: true);
  });
  setUp(() => S.current = S.uz);

  test(
      'private profile photos use the chat user ID, preserve personal photo and paginate raw offsets',
      () async {
    final (td, source) = await fake.started();
    addTearDown(source.dispose);
    td.push({
      '@type': 'updateNewChat',
      'chat': {
        ...fake.privateChat(7, 'Customer'),
        'type': {'@type': 'chatTypePrivate', 'user_id': 81}
      }
    });
    td.handlers['getUserFullInfo'] =
        (_) => {'personal_photo': _photo('personal', 100)};
    td.handlers['getUserProfilePhotos'] = (r) => {
          'total_count': 3,
          'photos': r['offset'] == 0
              ? [_photo('one', 200), _photo('two', 300)]
              : [_photo('three', 400)]
        };
    final first = await source.profilePhotos('7');
    expect(first.photos.map((p) => p.id), ['personal', 'one', 'two']);
    expect(first.total, 4);
    expect(first.nextCursor, '2');
    expect(first.photos.first.media.fileId, 101);
    expect(first.photos.first.date, isNotNull);
    final second = await source.profilePhotos('7', cursor: first.nextCursor);
    expect(second.photos.single.id, 'three');
    expect(second.nextCursor, isEmpty);
    expect(td.sent('getUserProfilePhotos').map((r) => r['offset']), [0, 2]);
    expect(
        td
            .sent('getUserProfilePhotos')
            .every((r) => r['user_id'] == 81 && r['limit'] == 20),
        isTrue);
    expect(td.sent('getUserFullInfo').single['user_id'], 81);
    expect(td.sent('downloadFile'), isEmpty);
    expect(td.sent('viewMessages'), isEmpty);
    expect(td.sent('sendChatAction'), isEmpty);
  });

  test(
      'public fallback, empty profile and secret chat all respect visible user photos',
      () async {
    final (td, source) = await fake.started();
    addTearDown(source.dispose);
    td.push({
      '@type': 'updateNewChat',
      'chat': {
        ...fake.privateChat(1, 'Hidden'),
        'type': {'@type': 'chatTypeSecret', 'user_id': 8, 'secret_chat_id': 90}
      }
    });
    td.handlers['getUserFullInfo'] =
        (_) => {'public_photo': _photo('public', 10)};
    td.handlers['getUserProfilePhotos'] =
        (_) => {'total_count': 0, 'photos': []};
    expect((await source.profilePhotos('1')).photos.single.id, 'public');
    expect(td.sent('getUserProfilePhotos').single['user_id'], 8);
    td.handlers['getUserFullInfo'] = (_) => {};
    expect((await source.profilePhotos('1')).photos, isEmpty);
  });

  test(
      'group gallery uses photo service messages, deduplicates current and follows the server cursor',
      () async {
    final (td, source) = await fake.started();
    addTearDown(source.dispose);
    td.push({'@type': 'updateNewChat', 'chat': fake.groupChat(-10, 'Group')});
    td.handlers['getSupergroupFullInfo'] = (_) => {'photo': _photo('one', 10)};
    td.handlers['searchChatMessages'] = (r) => {
          'total_count': 2,
          'next_from_message_id': r['from_message_id'] == 0 ? 50 : 0,
          'messages': [
            {
              'content': {
                '@type': 'messageChatChangePhoto',
                'photo': _photo(r['from_message_id'] == 0 ? 'one' : 'two', 10)
              }
            }
          ]
        };
    final first = await source.profilePhotos('-10');
    expect(first.photos.single.id, 'one');
    expect(first.nextCursor, '50');
    final second = await source.profilePhotos('-10', cursor: first.nextCursor);
    expect(second.photos.single.id, 'two');
    expect(second.nextCursor, isEmpty);
    expect(td.sent('searchChatMessages').last['from_message_id'], 50);
    expect(td.sent('searchChatMessages').first['filter'],
        {'@type': 'searchMessagesFilterChatPhoto'});
    expect(td.sent('getUserProfilePhotos'), isEmpty);
    expect(td.sent('viewMessages'), isEmpty);
  });

  test(
      'file updates refresh previews and full resolution; failures can retry without new history',
      () async {
    final (td, source) = await fake.started();
    addTearDown(source.dispose);
    td.push({
      '@type': 'updateNewChat',
      'chat': {
        ...fake.privateChat(1, 'Customer'),
        'photo': {'small': _file(10, path: 'small.png'), 'big': _file(11)}
      }
    });
    final current = source.currentProfilePhoto('1')!;
    expect(current.media.previewPath, 'small.png');
    expect(current.media.filePath, isNull);
    td.handlers['downloadFile'] =
        (_) => throw TdError(500, 'Synthetic failure');
    await expectLater(source.downloadProfilePhoto(11), throwsA(isA<TdError>()));
    td.handlers['downloadFile'] = (_) => _file(11, path: 'full.png');
    await source.downloadProfilePhoto(11);
    expect(source.refreshProfilePhoto(current).media.filePath, 'full.png');
    expect(td.sent('downloadFile').last['priority'], 32);
    expect(td.sent('downloadFile').last['synchronous'], isTrue);
    await source.downloadProfilePhoto(11);
    expect(td.sent('downloadFile'), hasLength(2));
    expect(td.sent('viewMessages'), isEmpty);
  });

  test('a closed account discards pending photos and starts no second request',
      () async {
    final (td, source) = await fake.started();
    td.push(
        {'@type': 'updateNewChat', 'chat': fake.privateChat(1, 'Customer')});
    final pending = Completer<TdObject>();
    td.handlers['getUserFullInfo'] = (_) => pending.future;
    final load = source.profilePhotos('1');
    source.dispose();
    pending.complete({'photo': _photo('old account', 10)});
    expect((await load).photos, isEmpty);
    await source.downloadProfilePhoto(11);
    expect(td.sent('getUserProfilePhotos'), isEmpty);
    expect(td.sent('downloadFile'), isEmpty);
  });

  for (final panel in [true, false]) {
    testWidgets(
        '${panel ? 'info panel' : 'chat header'} avatar opens photos, pages, zooms and closes with keyboard',
        (tester) async {
      final source = _Source()
        ..load = (cursor) async => cursor.isEmpty
            ? ProfilePhotoPage(
                photos: [_uiPhoto(1), _uiPhoto(2)], total: 3, nextCursor: '2')
            : ProfilePhotoPage(photos: [_uiPhoto(2), _uiPhoto(3)], total: 3);
      await _pump(tester, source, panel: panel);
      await tester.tap(find.byType(ProfilePhotoButton));
      await tester.pumpAndSettle();
      expect(find.text('1/3'), findsOneWidget);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pumpAndSettle();
      expect(find.text('2/3'), findsOneWidget);
      await tester.tap(find.byTooltip(S.uz.chats.nextPhoto));
      await tester.pumpAndSettle();
      expect(find.text('3/3'), findsOneWidget);
      expect(source.requests, ['dilshod:', 'dilshod:2']);
      final viewport = find.byType(InteractiveViewer);
      final transform =
          find.descendant(of: viewport, matching: find.byType(Transform));
      final beforeZoom =
          tester.widget<Transform>(transform).transform.getMaxScaleOnAxis();
      await tester.sendEventToBinding(PointerScrollEvent(
          position: tester.getCenter(viewport),
          scrollDelta: const Offset(0, -120),
          kind: PointerDeviceKind.mouse));
      await tester.pumpAndSettle();
      expect(tester.widget<Transform>(transform).transform.getMaxScaleOnAxis(),
          greaterThan(beforeZoom));
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.pumpAndSettle();
      expect(find.text('2/3'), findsOneWidget);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.byType(ProfilePhotoViewer), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('empty, failed and retry states; mouse close remains available',
      (tester) async {
    final source = _Source()
      ..load = (_) async => throw StateError('Synthetic failure');
    await _pump(tester, source);
    await tester.tap(find.byType(ProfilePhotoButton));
    await tester.pumpAndSettle();
    expect(find.text(S.uz.chats.profilePhotosFailed), findsOneWidget);
    source.load = (_) async => const ProfilePhotoPage(photos: [], total: 0);
    await tester.tap(find.text(S.uz.common.retry));
    await tester.pumpAndSettle();
    expect(find.text(S.uz.chats.noProfilePhotos), findsOneWidget);
    await tester.tap(find.byTooltip(S.uz.chats.closeEsc));
    await tester.pumpAndSettle();
    expect(find.byType(ProfilePhotoViewer), findsNothing);
  });

  testWidgets('download failure retries and displays the full local image',
      (tester) async {
    final source = _Source()
      ..load = (_) async =>
          ProfilePhotoPage(photos: [_uiPhoto(1, remote: true)], total: 1);
    source.fetch = (_) async => throw StateError('Synthetic failure');
    await _pump(tester, source);
    await tester.tap(find.byType(ProfilePhotoButton));
    await tester.pumpAndSettle();
    expect(find.text(S.uz.chats.profilePhotosFailed), findsOneWidget);
    source.fetch = (id) async {
      source.paths[id] = imagePath;
    };
    await tester.tap(find.text(S.uz.common.retry));
    await tester.pumpAndSettle();
    expect(find.text(S.uz.chats.profilePhotosFailed), findsNothing);
    expect(find.byWidgetPredicate((w) => w is Image && w.image is FileImage),
        findsOneWidget);
    expect(find.text(S.uz.chats.profilePhotoUnavailable), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('switching chat removes the gallery and ignores a late response',
      (tester) async {
    final pending = Completer<ProfilePhotoPage>();
    final source = _Source()..load = (_) => pending.future;
    final state = await _pump(tester, source);
    await tester.tap(find.byType(ProfilePhotoButton));
    await tester.pump();
    state.openChat('madina');
    await tester.pumpAndSettle();
    expect(find.byType(ProfilePhotoViewer), findsNothing);
    pending.complete(ProfilePhotoPage(photos: [_uiPhoto(1)], total: 1));
    await tester.pumpAndSettle();
    expect(find.byType(ProfilePhotoViewer), findsNothing);
    expect(tester.takeException(), isNull);
  });

  for (final language in AppLanguage.values) {
    testWidgets('profile gallery fits a narrow dark window in ${language.name}',
        (tester) async {
      final source = _Source()
        ..load = (_) async => ProfilePhotoPage(photos: [_uiPhoto(1)], total: 1);
      await _pump(tester, source, narrow: true, language: language);
      await tester.tap(find.byType(ProfilePhotoButton));
      await tester.pumpAndSettle();
      expect(find.byType(ProfilePhotoViewer), findsOneWidget);
      expect(tester.takeException(), isNull);
      final close = tester.getRect(find.byTooltip(S.current.chats.closeEsc));
      expect(close.top, greaterThanOrEqualTo(36));
    });
  }
}

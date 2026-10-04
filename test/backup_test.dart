// Encrypted backups: crypto format, database snapshots, the service,
// the Telegram transport (fake TDLib) and the dialog.
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fokus/auth/mock_auth.dart';
import 'package:fokus/backup/backup_crypto.dart';
import 'package:fokus/backup/backup_key_store.dart';
import 'package:fokus/backup/backup_service.dart';
import 'package:fokus/backup/backup_transport.dart';
import 'package:fokus/backup/snapshot.dart';
import 'package:fokus/data/chat_source.dart';
import 'package:fokus/data/local_store.dart';
import 'package:fokus/data/mock_source.dart';
import 'package:fokus/db/database.dart';
import 'package:fokus/main.dart';
import 'package:fokus/notes/note_store.dart';
import 'package:fokus/state/settings.dart';
import 'package:fokus/tasks/task_store.dart';
import 'package:fokus/tdlib/td_backup.dart';
import 'package:sqlite3/sqlite3.dart';

import 'helpers/fonts.dart';
import 'td_chats_test.dart' show FakeTd;

const light = KdfParams(memoryKiB: 1024, iterations: 1);

Future<AppDatabase> _withData() async {
  final db = AppDatabase.memory();
  final tasks = TaskStore(db);
  await tasks.add(title: 'Hisobot', due: DateTime(2026, 10, 7));
  tasks.dispose();
  final notes = NoteStore(db);
  await notes.add(title: 'Ro‘yxat', checklist: true, items: const [NoteItem('sut', done: true)]);
  notes.dispose();
  final store = await LocalStore.openDb(db);
  store
    ..setCollection('42', 'oila')
    ..setSeen('42', 3);
  await store.flush();
  return db;
}

void main() {
  setUpAll(() async {
    BackupService.kdf = light;
    await loadSegoeUi();
  });

  group('BackupCrypto', () {
    test('round trip; wrong password, tampering and other files are refused', () async {
      final key = await BackupCrypto.deriveKey('to‘g‘ri-parol', params: light);
      final plain = Uint8List.fromList(utf8.encode('Fokus ma’lumotlari 🔐'));
      final data = await BackupCrypto.encrypt(plain, key);

      expect(ascii.decode(data.sublist(0, 8)), 'FOKUSBAK');
      expect(utf8.decode(await BackupCrypto.decrypt(data, key)), 'Fokus ma’lumotlari 🔐');
      expect(utf8.decode(await BackupCrypto.decryptWithPassword(data, 'to‘g‘ri-parol')), 'Fokus ma’lumotlari 🔐');

      expect(() => BackupCrypto.decryptWithPassword(data, 'notogri-parol'),
          throwsA(isA<BackupException>().having((e) => e.message, 'message', contains('Parol noto‘g‘ri'))));

      final flipped = Uint8List.fromList(data)..[data.length - 20] ^= 1;
      expect(() => BackupCrypto.decrypt(flipped, key), throwsA(isA<BackupException>()));
      final header = Uint8List.fromList(data)..[12] ^= 1; // KDF memory in the header
      expect(() => BackupCrypto.decrypt(header, key), throwsA(isA<BackupException>()));

      expect(() => BackupCrypto.readHeader(Uint8List.fromList(utf8.encode('PK not a backup at all, really not'))),
          throwsA(isA<BackupException>().having((e) => e.message, 'message', contains('zaxira nusxasi emas'))));
      final newer = Uint8List.fromList(data)..[8] = 9;
      expect(() => BackupCrypto.readHeader(newer),
          throwsA(isA<BackupException>().having((e) => e.message, 'message', contains('yangiroq'))));
    });

    test('salt and settings come from the file', () async {
      final key = await BackupCrypto.deriveKey('parol1234', params: light);
      final data = await BackupCrypto.encrypt(Uint8List(10), key);
      final (salt, params) = BackupCrypto.readHeader(data);
      expect(salt, key.salt);
      expect(params, light);
    });
  });

  group('Snapshot', () {
    test('restores every table and replaces what was there', () async {
      final source = await _withData();
      final snap = await Snapshot.capture(source);

      final target = AppDatabase.memory();
      await TaskStore(target).add(title: 'O‘chib ketadi');
      await Snapshot.restore(target, snap);

      expect((await target.select(target.tasks).get()).map((t) => t.title), ['Hisobot']);
      final note = (await target.select(target.notes).get()).single;
      expect(note.items, const [NoteItem('sut', done: true)]);
      final store = await LocalStore.openDb(target);
      expect(store.collectionOf('42'), 'oila');
      expect(store.seenOf('42'), 3);
      await source.close();
      await target.close();
    });

    test('a backup from an older schema is upgraded first', () async {
      final dir = Directory.systemTemp.createTempSync('fokus_old');
      addTearDown(() => dir.deleteSync(recursive: true));
      final probe = AppDatabase.memory();
      final createTasks = (await probe.customSelect("SELECT sql FROM sqlite_master WHERE name = 'tasks'").getSingle()).read<String>('sql');
      await probe.close();
      final file = File('${dir.path}${Platform.pathSeparator}old.sqlite');
      final raw = await _sqlite(file, [
        createTasks,
        "INSERT INTO tasks (title, note, status, important, position, created_at, updated_at) VALUES ('v1 vazifa', '', 'planned', 0, 1, 0, 0)",
        'PRAGMA user_version = 1',
      ]);
      final target = AppDatabase.memory();
      await Snapshot.restore(target, Uint8List.fromList(gzip.encode(raw)));
      expect((await target.select(target.tasks).get()).single.title, 'v1 vazifa');
      expect(await target.select(target.notes).get(), isEmpty);
      await target.close();
    });

    test('garbage is refused without touching the data', () async {
      final db = await _withData();
      expect(() => Snapshot.restore(db, Uint8List.fromList([1, 2, 3])), throwsA(isA<BackupException>()));
      expect(() => Snapshot.restore(db, Uint8List.fromList(gzip.encode(utf8.encode('not sqlite')))), throwsA(isA<BackupException>()));
      expect((await db.select(db.tasks).get()).length, 1);
      await db.close();
    });
  });

  group('BackupService', () {
    test('password rules, backup, and restore on this PC', () async {
      final db = await _withData();
      final transport = MemoryBackupTransport();
      final s = BackupService(db: db, transport: transport, keys: MemoryBackupKeyStore(), clock: () => DateTime(2026, 10, 4, 12, 30));
      await s.init();
      expect(s.hasPassword, isFalse);
      expect(() => s.setPassword('qisqa'), throwsA(isA<BackupException>()));
      await s.setPassword('uzun-parol-2026');

      final progress = <double>[];
      s.addListener(() {
        if (s.progress != null) progress.add(s.progress!);
      });
      await s.backupNow();
      final entry = (await s.list()).single;
      expect(entry.name, 'fokus-backup-2026-10-04_1230.fokusbak');
      expect(ascii.decode(transport.files.values.single.sublist(0, 8)), 'FOKUSBAK');
      expect(progress, contains(1.0));
      expect(s.lastBackupAt, DateTime(2026, 10, 4, 12, 30));

      // Change local data, then restore: back to the backup.
      await TaskStore(db).add(title: 'Keyin qo‘shilgan');
      await s.restore(entry);
      expect((await db.select(db.tasks).get()).map((t) => t.title), ['Hisobot']);
      expect(s.lastBackupAt, DateTime(2026, 10, 4, 12, 30), reason: 'local backup info kept');
      await db.close();
    });

    test('on another PC the password is needed', () async {
      final db = await _withData();
      final transport = MemoryBackupTransport();
      final first = BackupService(db: db, transport: transport, keys: MemoryBackupKeyStore());
      await first.init();
      await first.setPassword('birinchi-parol');
      await first.backupNow();

      final fresh = AppDatabase.memory();
      final other = BackupService(db: fresh, transport: transport, keys: MemoryBackupKeyStore());
      await other.init();
      final entry = (await other.list()).single;
      await expectLater(other.restore(entry), throwsA(isA<NeedPasswordException>()));
      await expectLater(other.restore(entry, password: 'boshqa-parol'),
          throwsA(isA<BackupException>().having((e) => e.message, 'message', contains('Parol noto‘g‘ri'))));
      await other.restore(entry, password: 'birinchi-parol');
      expect((await fresh.select(fresh.tasks).get()).single.title, 'Hisobot');
      await db.close();
      await fresh.close();
    });

    test('daily backup only when a day has passed', () async {
      var now = DateTime(2026, 10, 4, 9);
      final db = AppDatabase.memory();
      final transport = MemoryBackupTransport();
      final s = BackupService(db: db, transport: transport, keys: MemoryBackupKeyStore(), clock: () => now);
      await s.init();
      await s.setPassword('kunlik-parol');
      await s.maybeAutoBackup();
      expect(transport.files, isEmpty, reason: 'off by default');
      await s.setAutoDaily(true);
      for (var i = 0; i < 50 && transport.files.isEmpty; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 20));
      }
      expect(transport.files.length, 1, reason: 'turning it on backs up at once');
      now = now.add(const Duration(hours: 5));
      await s.maybeAutoBackup();
      expect(transport.files.length, 1);
      now = now.add(const Duration(hours: 20));
      await s.maybeAutoBackup();
      expect(transport.files.length, 2);
      s.dispose();
      await db.close();
    });
  });

  group('TdBackupTransport', () {
    test('uploads to Saved Messages with progress, lists and downloads', () async {
      final td = FakeTd();
      td.handlers['getMe'] = (_) => {'id': 1000};
      td.handlers['createPrivateChat'] = (r) => {'id': r['user_id']};
      td.handlers['sendMessage'] = (r) {
        // TDLib answers with the pending message, then sends updates.
        Future<void>.delayed(const Duration(milliseconds: 5), () {
          td.push({'@type': 'updateFile', 'file': {'id': 55, 'size': 100, 'remote': {'uploaded_size': 50}}});
          td.push({'@type': 'updateMessageSendSucceeded', 'old_message_id': 900001, 'message': {'id': 77}});
        });
        return {
          'id': 900001,
          'content': {
            '@type': 'messageDocument',
            'document': {'document': {'id': 55}},
          },
        };
      };
      final transport = TdBackupTransport(td);
      final progress = <double>[];
      await transport.upload(Uint8List(100), fileName: 'fokus-backup-x.fokusbak', caption: '#fokus_backup test', progress: progress.add);
      final send = td.sent('sendMessage').single;
      expect(send['chat_id'], 1000);
      final content = send['input_message_content'] as Map;
      expect(content['@type'], 'inputMessageDocument');
      // TDLib 1.8.6x: inputMessageDocument.document is an inputDocument.
      final doc = content['document'] as Map;
      expect(doc['@type'], 'inputDocument');
      expect((doc['document'] as Map)['@type'], 'inputFileLocal');
      expect(doc['disable_content_type_detection'], isTrue);
      expect((content['caption'] as Map)['text'], '#fokus_backup test');
      expect(progress, [0.5, 1.0]);

      final dir = Directory.systemTemp.createTempSync('fokus_dl');
      addTearDown(() => dir.deleteSync(recursive: true));
      final downloaded = File('${dir.path}${Platform.pathSeparator}b.fokusbak')..writeAsBytesSync([9, 9, 9]);
      td.handlers['searchChatMessages'] = (_) => {
            'messages': [
              {
                'id': 77,
                'date': 1790000000,
                'content': {
                  '@type': 'messageDocument',
                  'caption': {'text': '#fokus_backup Fokus zaxira nusxasi'},
                  'document': {'file_name': 'fokus-backup-x.fokusbak', 'document': {'id': 55, 'size': 3}},
                },
              },
              {
                'id': 78,
                'date': 1790000100,
                'content': {'@type': 'messageDocument', 'caption': {'text': 'boshqa fayl'}, 'document': {'document': {'id': 56}}},
              },
            ],
          };
      td.handlers['getMessage'] = (_) => {
            'content': {
              '@type': 'messageDocument',
              'document': {'document': {'id': 55}},
            },
          };
      td.handlers['downloadFile'] = (_) => {'id': 55, 'local': {'path': downloaded.path, 'is_downloading_completed': true}};
      final list = await transport.list();
      expect(list.map((e) => e.id), ['77'], reason: 'only tagged backups');
      expect(await transport.download(list.single), [9, 9, 9]);
      expect(td.sent('downloadFile').single['synchronous'], isTrue);
    });

    test('a failed send is reported in Uzbek', () async {
      final td = FakeTd();
      td.handlers['getMe'] = (_) => {'id': 1000};
      td.handlers['createPrivateChat'] = (r) => {'id': r['user_id']};
      td.handlers['sendMessage'] = (_) {
        Future<void>.delayed(const Duration(milliseconds: 5), () {
          td.push({
            '@type': 'updateMessageSendFailed',
            'old_message_id': 1,
            'error': {'code': 429, 'message': 'Too Many Requests: retry after 30'},
          });
        });
        return {'id': 1, 'content': {'@type': 'messageDocument', 'document': {'document': {'id': 2}}}};
      };
      await expectLater(
        TdBackupTransport(td).upload(Uint8List(1), fileName: 'f', caption: '#fokus_backup'),
        throwsA(isA<BackupException>().having((e) => e.message, 'message', contains('30 soniyadan'))),
      );
    });
  });

  testWidgets('settings → backup: set password, back up, restore', (tester) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final db = await tester.runAsync(_withData);
    final transport = MemoryBackupTransport();
    await tester.pumpWidget(FokusApp(settings: Settings.inMemory(ThemeMode.light), auth: _Auth(db!, transport)));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Sozlamalar'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Shifrlangan zaxira (Saved Messages)'));
    await tester.pumpAndSettle();
    expect(find.textContaining('hatto biz ham'), findsOneWidget);

    Finder field(int i) => find.descendant(of: find.byType(AlertDialog).last, matching: find.byType(TextField)).at(i);
    await tester.enterText(field(0), 'mening-parolim');
    await tester.enterText(field(1), 'boshqacha');
    await tester.tap(find.text('Parolni saqlash'));
    await tester.pumpAndSettle();
    expect(find.text('Parollar bir xil emas.'), findsOneWidget);
    await tester.enterText(field(1), 'mening-parolim');
    await tester.runAsync(() async {
      await tester.tap(find.text('Parolni saqlash'));
      await Future<void>.delayed(const Duration(milliseconds: 300));
    });
    await tester.pumpAndSettle();
    expect(find.text('Hozir saqlash'), findsOneWidget);

    await tester.runAsync(() async {
      await tester.tap(find.text('Hozir saqlash'));
      await Future<void>.delayed(const Duration(milliseconds: 300));
    });
    await tester.pumpAndSettle();
    expect(transport.files.length, 1);
    expect(find.text('Tiklash'), findsOneWidget);

    await tester.tap(find.text('Tiklash'));
    await tester.pumpAndSettle();
    expect(find.text('Shu nusxani tiklaysizmi?'), findsOneWidget);
    await tester.tap(find.widgetWithText(TextButton, 'Tiklash').last);
    // Restoring does file IO: let real time pass between frames.
    for (var i = 0; i < 40 && find.textContaining('nusxa tiklandi').evaluate().isEmpty; i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
      await tester.pump(const Duration(milliseconds: 50));
    }
    expect(find.textContaining('nusxa tiklandi'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

class _Auth extends MockAuth {
  _Auth(this.db, this.transport) : super(loggedIn: true, delay: Duration.zero);

  final AppDatabase db;
  final BackupTransport transport;

  @override
  Future<ChatSession> openSession() async => ChatSession(
        source: MockChatSource(),
        store: await LocalStore.openDb(db),
        db: db,
        backupTransport: transport,
        initialChatId: 'dilshod',
      );
}

/// Writes a raw SQLite file with [statements] and returns its bytes.
Future<List<int>> _sqlite(File file, List<String> statements) async {
  final raw = sqlite3.open(file.path);
  for (final s in statements) {
    raw.execute(s);
  }
  raw.close();
  return file.readAsBytes();
}

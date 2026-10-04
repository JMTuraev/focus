import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import '../backup/backup_crypto.dart' show BackupException;
import '../backup/backup_transport.dart';
import 'td_auth.dart' show authErrorText;
import 'td_client.dart';

/// Backups as documents in the user's own Saved Messages (the chat with
/// themselves). Only that chat is touched; nothing is marked as read.
class TdBackupTransport implements BackupTransport {
  TdBackupTransport(this.td);

  final TdApi td;

  /// Every backup caption starts with this tag; it is also the search query.
  static const tag = '#fokus_backup';

  Future<int> _savedMessagesId() async {
    final me = await td.query({'@type': 'getMe'});
    final chat = await td.query({'@type': 'createPrivateChat', 'user_id': me['id'], 'force': false});
    return chat['id'] as int;
  }

  @override
  Future<void> upload(Uint8List data, {required String fileName, required String caption, void Function(double)? progress}) async {
    final dir = await Directory.systemTemp.createTemp('fokus_upload');
    final file = File('${dir.path}${Platform.pathSeparator}$fileName');
    await file.writeAsBytes(data, flush: true);
    StreamSubscription<TdObject>? sub;
    try {
      final chatId = await _savedMessagesId();
      final done = Completer<void>();
      int? tempId;
      int? fileId;
      final early = <TdObject>[];
      void onUpdate(TdObject u) {
        if (tempId == null) {
          early.add(u); // may arrive before sendMessage answers
          return;
        }
        switch (u['@type']) {
          case 'updateFile':
            final f = u['file'] as TdObject;
            if (f['id'] != fileId) return;
            final remote = f['remote'] as TdObject?;
            final total = (f['size'] as int?) ?? data.length;
            final sent = (remote?['uploaded_size'] as int?) ?? 0;
            if (total > 0) progress?.call((sent / total).clamp(0, 1).toDouble());
          case 'updateMessageSendSucceeded':
            if (u['old_message_id'] == tempId && !done.isCompleted) done.complete();
          case 'updateMessageSendFailed':
            if (u['old_message_id'] == tempId && !done.isCompleted) {
              final err = u['error'] as TdObject?;
              done.completeError(BackupException(
                  'Saved Messages’ga yuklab bo‘lmadi: ${authErrorText(TdError((err?['code'] as int?) ?? 0, (err?['message'] as String?) ?? ''))}'));
            }
        }
      }

      sub = td.updates.listen(onUpdate);
      final msg = await td.query({
        '@type': 'sendMessage',
        'chat_id': chatId,
        'input_message_content': {
          '@type': 'inputMessageDocument',
          'document': {
            '@type': 'inputDocument',
            'document': {'@type': 'inputFileLocal', 'path': file.path},
            'disable_content_type_detection': true,
          },
          'caption': {'@type': 'formattedText', 'text': caption},
        },
      });
      tempId = msg['id'] as int;
      fileId = ((msg['content'] as TdObject?)?['document'] as TdObject?)?['document']?['id'] as int?;
      early.forEach(onUpdate);
      await done.future.timeout(const Duration(minutes: 10), onTimeout: () {
        throw BackupException('Yuklash juda uzoq davom etdi. Internetni tekshirib, qayta urinib ko‘ring.');
      });
      progress?.call(1);
    } on BackupException {
      rethrow;
    } catch (e) {
      throw BackupException('Saved Messages’ga yuklab bo‘lmadi: ${authErrorText(e)}');
    } finally {
      await sub?.cancel();
      // TDLib has its own copy once the message is sent.
      try {
        await dir.delete(recursive: true);
      } catch (_) {}
    }
  }

  @override
  Future<List<BackupEntry>> list() async {
    try {
      final chatId = await _savedMessagesId();
      final r = await td.query({
        '@type': 'searchChatMessages',
        'chat_id': chatId,
        'query': tag,
        'from_message_id': 0,
        'offset': 0,
        'limit': 50,
        'filter': {'@type': 'searchMessagesFilterDocument'},
      });
      final out = <BackupEntry>[];
      for (final m in (r['messages'] as List? ?? const []).whereType<Map<String, dynamic>>()) {
        final content = m['content'] as TdObject?;
        if (content?['@type'] != 'messageDocument') continue;
        final caption = ((content!['caption'] as TdObject?)?['text'] as String?) ?? '';
        if (!caption.startsWith(tag)) continue;
        final doc = content['document'] as TdObject;
        final file = doc['document'] as TdObject;
        out.add(BackupEntry(
          id: '${m['id']}',
          date: DateTime.fromMillisecondsSinceEpoch((m['date'] as int) * 1000),
          size: (file['size'] as int?) ?? 0,
          name: (doc['file_name'] as String?) ?? 'fokus-backup',
        ));
      }
      out.sort((a, b) => b.date.compareTo(a.date));
      return out;
    } catch (e) {
      throw BackupException('Zaxira nusxalarini olib bo‘lmadi: ${authErrorText(e)}');
    }
  }

  @override
  Future<Uint8List> download(BackupEntry entry) async {
    try {
      final chatId = await _savedMessagesId();
      final m = await td.query({'@type': 'getMessage', 'chat_id': chatId, 'message_id': int.parse(entry.id)});
      final file = ((m['content'] as TdObject)['document'] as TdObject)['document'] as TdObject;
      final f = await td.query({
        '@type': 'downloadFile',
        'file_id': file['id'],
        'priority': 32,
        'offset': 0,
        'limit': 0,
        'synchronous': true,
      }, timeout: const Duration(minutes: 10));
      final path = (f['local'] as TdObject?)?['path'] as String?;
      if (path == null || path.isEmpty) throw BackupException('Zaxira faylini yuklab bo‘lmadi.');
      return File(path).readAsBytes();
    } on BackupException {
      rethrow;
    } catch (e) {
      throw BackupException('Zaxira faylini yuklab bo‘lmadi: ${authErrorText(e)}');
    }
  }
}

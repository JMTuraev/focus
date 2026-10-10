import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:fokus/data/models.dart';
import 'package:fokus/tdlib/td_client.dart';

import 'td_chats_test.dart' as fake;

void main() {
  test('text, documents and albums use the 1.8.67 reply envelope', () async {
    final (td, source) = await fake.started();
    addTearDown(source.dispose);
    await source.sendReply('1', 'Answer', '777');
    final dir = Directory.systemTemp.createTempSync('focus_reply_files');
    addTearDown(() => dir.deleteSync(recursive: true));
    OutgoingFile file(String name) {
      final f = File('${dir.path}/$name')..writeAsStringSync('synthetic test');
      return OutgoingFile(path: f.path, name: name, size: f.lengthSync());
    }

    await source.sendFilesReply('1', [file('a.pdf')], '777', caption: 'Report');
    await source.sendFilesReply('1', [file('b.pdf'), file('c.pdf')], '777');
    expect(td.sent('sendMessage'), hasLength(2));
    expect(td.sent('sendMessageAlbum'), hasLength(1));
    for (final r in [...td.sent('sendMessage'), ...td.sent('sendMessageAlbum')]) {
      expect(r['chat_id'], 1);
      expect(r['reply_to'], {'@type': 'inputMessageReplyToMessage', 'message_id': 777});
    }
  });

  test('forward retains author and caption and propagates protected-content failure', () async {
    final (td, source) = await fake.started();
    addTearDown(source.dispose);
    await source.forwardMessages('2', '1', ['10', '11']);
    expect(td.sent('forwardMessages').single, {
      '@type': 'forwardMessages',
      'chat_id': 2,
      'from_chat_id': 1,
      'message_ids': [10, 11],
      'send_copy': false,
      'remove_caption': false,
    });
    td.handlers['forwardMessages'] = (_) => throw TdError(400, 'MESSAGE_CANT_BE_FORWARDED');
    await expectLater(source.forwardMessages('2', '1', ['12']), throwsA(isA<TdError>()));
    expect(td.sent('sendMessage'), isEmpty, reason: 'no copy fallback for protected content');
  });

  test('reply/forward permissions come from Telegram', () async {
    final (td, source) = await fake.started();
    addTearDown(source.dispose);
    td.handlers['getMessageProperties'] = (_) => {'can_be_replied': true, 'can_be_forwarded': false};
    final rights = await source.rightsOf('1', '10');
    expect(rights.canReply, isTrue);
    expect(rights.canForward, isFalse);
  });

  test('search fetches unloaded history and uses the returned cursor', () async {
    final (td, source) = await fake.started();
    addTearDown(source.dispose);
    td.push({'@type': 'updateNewChat', 'chat': fake.privateChat(1, 'Customer', order: 10)});
    td.handlers['searchChatMessages'] = (r) => {
          'total_count': 2,
          'messages': [fake.text(1, r['from_message_id'] == 0 ? 99 : 30, 'Invoice')],
          'next_from_message_id': r['from_message_id'] == 0 ? 50 : 0,
        };
    final first = await source.searchMessages('1', ' Invoice ');
    expect(first.messages.single.id, '99');
    expect(first.total, 2);
    expect(first.nextFromMessageId, '50');
    expect(source.messagesOf('1'), isEmpty, reason: 'search does not merge disjoint history');
    final second = await source.searchMessages('1', 'Invoice', fromMessageId: first.nextFromMessageId);
    expect(second.messages.single.id, '30');
    expect(second.nextFromMessageId, '');
    expect(td.sent('searchChatMessages').last['from_message_id'], 50);
    expect(td.sent('searchChatMessages').last['filter'], {'@type': 'searchMessagesFilterEmpty'});
    await source.searchMessages('1', '  ');
    expect(td.sent('searchChatMessages'), hasLength(2));
    expect(td.sent('viewMessages'), isEmpty);
  });

  test('jump replaces history with a contiguous window and fetches a missing original', () async {
    final (td, source) = await fake.started();
    addTearDown(source.dispose);
    td.push({'@type': 'updateNewChat', 'chat': fake.privateChat(1, 'Customer', order: 10)});
    td.handlers['getChatHistory'] = (_) => {
          'messages': [fake.text(1, 8, 'Before'), fake.text(1, 12, 'After')]
        };
    td.handlers['getMessage'] = (_) => fake.text(1, 10, 'Original');
    await source.historyAround('1', '10');
    expect(source.messagesOf('1').map((m) => m.id), ['8', '10', '12']);
    expect(td.sent('getChatHistory').single['offset'], -20);
    td.push({'@type': 'updateNewMessage', 'message': fake.text(1, 500, 'New live message')});
    expect(source.messagesOf('1').map((m) => m.id), ['8', '10', '12'], reason: 'no gap from old result to newest message');
    td.handlers['getChatHistory'] = (r) => {
          'messages': r['from_message_id'] == 0 ? [fake.text(1, 500, 'Latest')] : []
        };
    await source.historyAround('1', '0');
    expect(source.messagesOf('1').single.id, '500');
    td.push({'@type': 'updateNewMessage', 'message': fake.text(1, 501, 'Live again')});
    expect(source.messagesOf('1').last.id, '501');
    expect(td.sent('viewMessages'), isEmpty);
  });

  test('late history requests cannot replace a newer jump', () async {
    final (td, source) = await fake.started();
    addTearDown(source.dispose);
    td.push({'@type': 'updateNewChat', 'chat': fake.privateChat(1, 'Customer', order: 10)});
    final first = Completer<TdObject>();
    td.handlers['getChatHistory'] = (r) => r['from_message_id'] == 10
        ? first.future
        : {
            'messages': [fake.text(1, 20, 'Second selection')]
          };
    final oldJump = source.historyAround('1', '10');
    await source.historyAround('1', '20');
    first.complete({
      'messages': [fake.text(1, 10, 'First selection')]
    });
    await oldJump;
    expect(source.messagesOf('1').single.id, '20');
  });

  test('reply quotes and forward origins survive mapping and edited copies', () async {
    final (td, source) = await fake.started();
    addTearDown(source.dispose);
    td.push({'@type': 'updateUser', 'user': fake.user(1, 'Customer')});
    td.push({'@type': 'updateNewChat', 'chat': fake.privateChat(1, 'Customer', order: 10)});
    td.handlers['getChatHistory'] = (_) => {
          'messages': [
            {
              ...fake.text(1, 20, 'Answer'),
              'reply_to': {
                '@type': 'messageReplyToMessage',
                'chat_id': 1,
                'message_id': 10,
                'quote': {
                  'text': {'text': 'Quoted words'}
                },
                'origin': {'@type': 'messageOriginUser', 'sender_user_id': 1}
              },
              'forward_info': {
                'origin': {'@type': 'messageOriginHiddenUser', 'sender_name': 'Hidden author'}
              },
            }
          ]
        };
    await source.historyAround('1', '20');
    final message = source.messagesOf('1').single;
    expect(message.reply!.messageId, '10');
    expect(message.reply!.text, 'Quoted words');
    expect(message.reply!.author, 'Customer');
    expect(message.forwardedFrom, 'Hidden author');
    expect(message.withText('Edited').reply, same(message.reply));
    expect(message.withMeeting(null, null).forwardedFrom, 'Hidden author');
  });

  test('returning to latest waits out stale paging and fills a short cached window', () async {
    final (td, source) = await fake.started();
    addTearDown(source.dispose);
    td.push({'@type': 'updateNewChat', 'chat': fake.privateChat(1, 'Customer', order: 10)});
    final oldPage = Completer<TdObject>();
    td.handlers['getChatHistory'] = (r) {
      final from = r['from_message_id'];
      if (from == 10) {
        return {
          'messages': [fake.text(1, 10, 'Old search result')]
        };
      }
      return oldPage.future;
    };
    await source.historyAround('1', '10');
    final paging = source.loadOlder('1');
    await Future<void>.delayed(Duration.zero);
    td.handlers['getChatHistory'] = (r) => {
          'messages': r['from_message_id'] == 0
              ? [fake.text(1, 500, 'Latest')]
              : r['from_message_id'] == 500
                  ? [fake.text(1, 499, 'Before latest')]
                  : []
        };
    await source.historyAround('1', '0');
    oldPage.complete({
      'messages': [fake.text(1, 9, 'Old page')]
    });
    await paging;
    await Future<void>.delayed(Duration.zero);
    expect(source.messagesOf('1').map((m) => m.id), ['499', '500']);
  });
}

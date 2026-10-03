// TdChatSource against a fake TDLib: chat list, previews, history, sending,
// local "seen" counters, and the local-mode guarantee (no viewMessages).
import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:fokus/data/local_store.dart';
import 'package:fokus/data/models.dart';
import 'package:fokus/state/app_state.dart';
import 'package:fokus/tdlib/td_auth.dart';
import 'package:fokus/tdlib/td_chats.dart';
import 'package:fokus/tdlib/td_client.dart';

const me = 1000;

class FakeTd implements TdApi {
  final _updates = StreamController<TdObject>.broadcast(sync: true);
  final requests = <TdObject>[];
  final handlers = <String, FutureOr<TdObject> Function(TdObject)>{};

  @override
  Stream<TdObject> get updates => _updates.stream;

  @override
  Future<TdObject> query(TdObject request, {Duration timeout = const Duration(seconds: 30)}) async {
    TdClient.checkAllowed(request);
    requests.add(request);
    final h = handlers[request['@type']];
    if (h == null) return {'@type': 'ok'};
    return await h(request);
  }

  void push(TdObject u) => _updates.add(u);

  List<TdObject> sent(String type) => requests.where((r) => r['@type'] == type).toList();
}

TdObject privateChat(int id, String title, {int order = 0, TdObject? last, int unread = 0, bool muted = false}) => {
      '@type': 'chat',
      'id': id,
      'type': {'@type': 'chatTypePrivate', 'user_id': id},
      'title': title,
      'positions': [
        if (order > 0)
          {
            '@type': 'chatPosition',
            'list': {'@type': 'chatListMain'},
            'order': '$order',
            'is_pinned': false,
          },
      ],
      'last_message': last,
      'unread_count': unread,
      'unread_mention_count': 0,
      'last_read_outbox_message_id': 0,
      'notification_settings': {'mute_for': muted ? 999999 : 0},
    };

TdObject groupChat(int id, String title, {int order = 0, TdObject? last, int mentions = 0}) => {
      '@type': 'chat',
      'id': id,
      'type': {'@type': 'chatTypeSupergroup', 'supergroup_id': 77, 'is_channel': false},
      'title': title,
      'positions': [
        {'@type': 'chatPosition', 'list': {'@type': 'chatListMain'}, 'order': '$order'},
      ],
      'last_message': last,
      'unread_count': 0,
      'unread_mention_count': mentions,
      'notification_settings': {'mute_for': 0},
    };

TdObject user(int id, String first, {String last = '', TdObject? status, String phone = ''}) => {
      '@type': 'user',
      'id': id,
      'first_name': first,
      'last_name': last,
      'phone_number': phone,
      'type': {'@type': 'userTypeRegular'},
      'status': status ?? {'@type': 'userStatusRecently'},
    };

// One day ago, so test messages are inside the 7-day "waiting" window.
final int _date = DateTime.now().millisecondsSinceEpoch ~/ 1000 - 86400;

TdObject text(int chatId, int id, String body, {bool out = false, int sender = 0, TdObject? sending}) => {
      '@type': 'message',
      'id': id,
      'chat_id': chatId,
      'is_outgoing': out,
      'date': _date + id,
      'sender_id': {'@type': 'messageSenderUser', 'user_id': out ? me : (sender == 0 ? chatId : sender)},
      'content': {
        '@type': 'messageText',
        'text': {'@type': 'formattedText', 'text': body},
      },
      if (sending != null) 'sending_state': sending,
    };

Future<(FakeTd, TdChatSource)> started({void Function(FakeTd td)? setup}) async {
  final td = FakeTd();
  td.handlers['getMe'] = (_) => user(me, 'Men');
  td.handlers['loadChats'] = (_) => throw TdError(404, 'Not Found');
  setup?.call(td);
  final source = TdChatSource(td);
  await source.start();
  return (td, source);
}

void main() {
  test('chat list follows Telegram order and drops chats without a position', () async {
    final (td, source) = await started();
    td.push({'@type': 'updateUser', 'user': user(1, 'Dilshod', last: 'Karimov')});
    td.push({'@type': 'updateNewChat', 'chat': privateChat(1, 'Dilshod Karimov', order: 300)});
    td.push({'@type': 'updateNewChat', 'chat': privateChat(2, 'Madina', order: 500)});
    td.push({'@type': 'updateNewChat', 'chat': privateChat(3, 'Arxivdagi', order: 0)});
    td.push({'@type': 'updateNewChat', 'chat': privateChat(me, 'Men', order: 100)});

    expect(source.loading, isFalse);
    expect(source.chats.map((c) => c.id), ['2', '1', '$me']);
    expect(source.chats.last.name, 'Saqlangan xabarlar');
    expect(source.chats.last.kind, ChatKind.saved);
    expect(source.chats[1].initials, 'DK');

    td.push({
      '@type': 'updateChatPosition',
      'chat_id': 1,
      'position': {'@type': 'chatPosition', 'list': {'@type': 'chatListMain'}, 'order': '900'},
    });
    expect(source.chats.first.id, '1');

    td.push({
      '@type': 'updateChatPosition',
      'chat_id': 2,
      'position': {'@type': 'chatPosition', 'list': {'@type': 'chatListMain'}, 'order': '0'},
    });
    expect(source.chats.map((c) => c.id), ['1', '$me']);
  });

  test('previews, waiting flag, unread, mute and status', () async {
    final (td, source) = await started();
    td.push({'@type': 'updateUser', 'user': user(1, 'Dilshod', status: {'@type': 'userStatusOnline', 'expires': 0})});
    td.push({'@type': 'updateUser', 'user': user(5, 'Sardor', last: 'Aliyev')});
    td.push({'@type': 'updateSupergroup', 'supergroup': {'@type': 'supergroup', 'id': 77, 'member_count': 3412}});
    td.push({'@type': 'updateNewChat', 'chat': privateChat(1, 'Dilshod', order: 10, last: text(1, 1, 'Narxlar?'), unread: 2, muted: true)});
    td.push({'@type': 'updateNewChat', 'chat': groupChat(-9, 'Jamoa', order: 5, last: text(-9, 1, 'Reliz tayyor', sender: 5), mentions: 1)});

    final dilshod = source.chatById('1')!;
    expect(dilshod.last, 'Narxlar?');
    expect(dilshod.waiting, isTrue);
    expect(dilshod.unread, 2);
    expect(dilshod.muted, isTrue);
    expect(dilshod.online, isTrue);
    expect(dilshod.status, 'online');

    final group = source.chatById('-9')!;
    expect(group.last, 'Sardor: Reliz tayyor');
    expect(group.waiting, isTrue, reason: 'unread mention');
    expect(group.status, '3 412 a’zo');

    td.push({'@type': 'updateChatLastMessage', 'chat_id': 1, 'last_message': text(1, 2, 'Yubordim', out: true), 'positions': []});
    expect(source.chatById('1')!.last, 'Siz: Yubordim');
    expect(source.chatById('1')!.waiting, isFalse);

    td.push({'@type': 'updateChatReadInbox', 'chat_id': 1, 'last_read_inbox_message_id': 2, 'unread_count': 0});
    expect(source.chatById('1')!.unread, 0);

    td.push({
      '@type': 'updateChatLastMessage',
      'chat_id': 1,
      'last_message': {
        ...text(1, 3, ''),
        'content': {
          '@type': 'messagePhoto',
          'caption': {'@type': 'formattedText', 'text': ''},
        },
      },
      'positions': [],
    });
    expect(source.chatById('1')!.last, 'Rasm');
  });

  test('history loads in pages, oldest first, and new messages are appended', () async {
    final (td, source) = await started(setup: (td) {
      var round = 0;
      td.handlers['getChatHistory'] = (r) {
        round++;
        // TDLib often answers with one local message first.
        if (round == 1) return {'messages': [text(1, 50, 'oxirgi')]};
        final from = r['from_message_id'] as int;
        if (from <= 10) return {'messages': []};
        return {
          'messages': [for (var id = from - 1; id > from - 41 && id > 9; id--) text(1, id, 'xabar $id')],
        };
      };
    });
    td.push({'@type': 'updateNewChat', 'chat': privateChat(1, 'Dilshod', order: 10)});

    await source.open('1');
    expect(td.sent('openChat').single['chat_id'], 1);
    final msgs = source.messagesOf('1');
    expect(msgs.length, greaterThanOrEqualTo(40));
    expect(msgs.last.text, 'oxirgi');
    expect(int.parse(msgs.first.id), lessThan(int.parse(msgs.last.id)));
    expect(msgs.first.date, isNotNull);

    await source.loadOlder('1');
    expect(source.messagesOf('1').first.id, '10');
    final calls = td.sent('getChatHistory').length;
    await source.loadOlder('1');
    expect(td.sent('getChatHistory').length, calls, reason: 'history end reached, no more requests');

    td.push({'@type': 'updateNewMessage', 'message': text(1, 51, 'yangi')});
    expect(source.messagesOf('1').last.text, 'yangi');
  });

  test('sending: pending, then sent, then read', () async {
    final (td, source) = await started(setup: (td) {
      td.handlers['getChatHistory'] = (_) => {'messages': []};
    });
    td.push({'@type': 'updateNewChat', 'chat': privateChat(1, 'Dilshod', order: 10)});
    await source.open('1');

    await source.send('1', '  Salom  ');
    final req = td.sent('sendMessage').single;
    expect(req['chat_id'], 1);
    expect(((req['input_message_content'] as TdObject)['text'] as TdObject)['text'], 'Salom');

    td.push({'@type': 'updateNewMessage', 'message': text(1, 9000001, 'Salom', out: true, sending: {'@type': 'messageSendingStatePending'})});
    expect(source.messagesOf('1').single.pending, isTrue);

    td.push({'@type': 'updateMessageSendSucceeded', 'old_message_id': 9000001, 'message': text(1, 60, 'Salom', out: true)});
    final sent = source.messagesOf('1').single;
    expect(sent.id, '60');
    expect(sent.pending, isFalse);
    expect(sent.read, isFalse);

    td.push({'@type': 'updateChatReadOutbox', 'chat_id': 1, 'last_read_outbox_message_id': 60});
    expect(source.messagesOf('1').single.read, isTrue);
  });

  test('service messages, documents and sender names in groups', () async {
    final (td, source) = await started(setup: (td) {
      td.handlers['getChatHistory'] = (r) => r['from_message_id'] == 0
          ? {
              'messages': [
                {
                  ...text(-9, 3, ''),
                  'content': {
                    '@type': 'messageDocument',
                    'document': {
                      'file_name': 'taqdimot.pdf',
                      'document': {'size': 2516582},
                    },
                    'caption': {'text': 'Mana'},
                  },
                },
                text(-9, 2, 'Salom', sender: 5),
                {...text(-9, 1, '', sender: 5), 'content': {'@type': 'messageChatJoinByLink'}},
              ],
            }
          : {'messages': []};
    });
    td.push({'@type': 'updateUser', 'user': user(5, 'Sardor', last: 'Aliyev')});
    td.push({'@type': 'updateNewChat', 'chat': groupChat(-9, 'Jamoa', order: 5)});
    await source.open('-9');

    final msgs = source.messagesOf('-9');
    expect(msgs[0].service, isTrue);
    expect(msgs[0].text, 'Sardor Aliyev guruhga qo‘shildi');
    expect(msgs[1].from, 'Sardor Aliyev');
    expect(msgs[2].fileName, 'taqdimot.pdf');
    expect(msgs[2].fileMeta, '2,4 MB · PDF');
    expect(msgs[2].text, 'Mana');
  });

  test('profile photos are downloaded once and shown when ready', () async {
    final (td, source) = await started(setup: (td) {
      td.handlers['downloadFile'] = (r) => {
            'id': r['file_id'],
            'local': {'is_downloading_completed': false, 'path': ''},
          };
    });
    td.push({
      '@type': 'updateNewChat',
      'chat': {
        ...privateChat(1, 'Dilshod', order: 10),
        'photo': {
          'small': {
            'id': 42,
            'local': {'is_downloading_completed': false, 'path': ''},
          },
        },
      },
    });
    expect(source.chats.single.photo, isNull);
    source.chats;
    await Future<void>.delayed(Duration.zero);
    expect(td.sent('downloadFile').length, 1);

    td.push({
      '@type': 'updateFile',
      'file': {
        'id': 42,
        'local': {'is_downloading_completed': true, 'path': r'C:\tdlib\files\photo.jpg'},
      },
    });
    expect(source.chats.single.photo, r'C:\tdlib\files\photo.jpg');
    expect(td.sent('downloadFile').length, 1);
  });

  test('pinned chats, and where the composer is shown', () async {
    final (td, source) = await started();
    td.push({
      '@type': 'updateNewChat',
      'chat': {
        ...privateChat(1, 'Dilshod'),
        'positions': [
          {'@type': 'chatPosition', 'list': {'@type': 'chatListMain'}, 'order': '9', 'is_pinned': true},
        ],
      },
    });
    expect(source.chatById('1')!.pinned, isTrue);
    expect(source.chatById('1')!.canSend, isTrue);

    TdObject channel(int id, int supergroupId) => {
          ...groupChat(id, 'Kanal', order: 3),
          'type': {'@type': 'chatTypeSupergroup', 'supergroup_id': supergroupId, 'is_channel': true},
        };
    td.push({
      '@type': 'updateSupergroup',
      'supergroup': {'id': 11, 'status': {'@type': 'chatMemberStatusMember'}},
    });
    td.push({
      '@type': 'updateSupergroup',
      'supergroup': {
        'id': 12,
        'status': {
          '@type': 'chatMemberStatusAdministrator',
          'rights': {'can_post_messages': true},
        },
      },
    });
    td.push({'@type': 'updateNewChat', 'chat': channel(-11, 11)});
    td.push({'@type': 'updateNewChat', 'chat': channel(-12, 12)});
    expect(source.chatById('-11')!.canSend, isFalse, reason: 'subscriber of a channel');
    expect(source.chatById('-12')!.canSend, isTrue, reason: 'admin who may post');

    td.push({'@type': 'updateNewChat', 'chat': groupChat(-9, 'Jamoa', order: 5)});
    expect(source.chatById('-9')!.canSend, isTrue);
    td.push({
      '@type': 'updateChatPermissions',
      'chat_id': -9,
      'permissions': {'can_send_basic_messages': false},
    });
    expect(source.chatById('-9')!.canSend, isFalse, reason: 'group closed for members');
  });

  test('waiting ignores Telegram notifications and old messages', () async {
    final (td, source) = await started();
    td.push({'@type': 'updateNewChat', 'chat': privateChat(777000, 'Telegram', order: 9, last: text(777000, 1, 'Login code'))});
    final old = {...text(2, 1, 'Eski savol'), 'date': DateTime.now().millisecondsSinceEpoch ~/ 1000 - 30 * 86400};
    td.push({'@type': 'updateNewChat', 'chat': privateChat(2, 'Eski', order: 8, last: old)});
    td.push({'@type': 'updateNewChat', 'chat': privateChat(3, 'Yangi', order: 7, last: text(3, 1, 'Savol'))});
    expect(source.chatById('777000')!.waiting, isFalse);
    expect(source.chatById('2')!.waiting, isFalse);
    expect(source.chatById('3')!.waiting, isTrue);
  });

  test('Fokus-only seen counter hides badges without telling Telegram', () async {
    final (td, source) = await started(setup: (td) {
      td.handlers['getChatHistory'] = (_) => {'messages': []};
    });
    td.push({'@type': 'updateNewChat', 'chat': privateChat(1, 'Dilshod', order: 10, unread: 3)});
    td.push({'@type': 'updateNewChat', 'chat': privateChat(2, 'Madina', order: 5, unread: 1)});
    final state = AppState(source: source, store: LocalStore.memory());

    expect(state.unreadOf(source.chatById('1')!), 3);
    state.openChat('1');
    expect(state.unreadOf(source.chatById('1')!), 0);

    // A new message while the chat is open counts as seen.
    td.push({'@type': 'updateChatReadInbox', 'chat_id': 1, 'last_read_inbox_message_id': 0, 'unread_count': 4});
    expect(state.unreadOf(source.chatById('1')!), 0);

    // After switching away, new messages show up again.
    state.openChat('2');
    td.push({'@type': 'updateChatReadInbox', 'chat_id': 1, 'last_read_inbox_message_id': 0, 'unread_count': 6});
    expect(state.unreadOf(source.chatById('1')!), 2);

    // Read on the phone: Telegram's counter drops, the local mark follows.
    td.push({'@type': 'updateChatReadInbox', 'chat_id': 1, 'last_read_inbox_message_id': 9, 'unread_count': 0});
    expect(state.unreadOf(source.chatById('1')!), 0);
    td.push({'@type': 'updateChatReadInbox', 'chat_id': 1, 'last_read_inbox_message_id': 9, 'unread_count': 1});
    expect(state.unreadOf(source.chatById('1')!), 1);

    // Nothing that marks messages as read ever reached TDLib.
    final types = td.requests.map((r) => r['@type']).toSet();
    expect(types.intersection(LocalMode.forbiddenRequests), isEmpty);
    expect(types, isNot(contains('viewMessages')));
    state.dispose();
  });
}

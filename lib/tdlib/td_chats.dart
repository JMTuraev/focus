import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import '../auth/auth.dart' show formatPhone;
import '../data/chat_source.dart';
import '../data/format.dart';
import '../data/models.dart';
import 'td_client.dart';

/// Chats and messages from TDLib, kept up to date from `update*` objects.
///
/// Local mode: this class opens and closes chats and reads history, but never
/// calls viewMessages, so nothing is marked as read on other devices.
class TdChatSource extends ChatSource {
  TdChatSource(this.td) {
    _sub = td.updates.listen(_onUpdate);
  }

  final TdApi td;
  late final StreamSubscription<TdObject> _sub;

  int _myId = 0;
  bool _loading = true;
  bool _disposed = false;

  final _chats = <int, TdObject>{};
  final _users = <int, TdObject>{};
  final _basicGroups = <int, TdObject>{};
  final _supergroups = <int, TdObject>{};
  final _about = <int, String>{};
  final _messages = <int, List<TdObject>>{};
  final _historyLoading = <int>{};
  final _historyDone = <int>{};
  final _files = <int, _FileState>{};
  final _downloads = <int>{};
  final _userRequests = <int>{};
  List<Chat>? _sorted;

  static const _mainList = 'chatListMain';

  /// Loads the current user and the first pages of the main chat list.
  Future<void> start({int pages = 3}) async {
    try {
      final me = await td.query({'@type': 'getMe'});
      _myId = me['id'] as int;
    } catch (e) {
      debugPrint('getMe: $e');
    }
    try {
      for (var i = 0; i < pages; i++) {
        await td.query({
          '@type': 'loadChats',
          'chat_list': {'@type': _mainList},
          'limit': 100,
        });
      }
    } on TdError catch (e) {
      // 404: every chat is already loaded.
      if (e.code != 404) debugPrint('loadChats: $e');
    } catch (e) {
      debugPrint('loadChats: $e');
    }
    _loading = false;
    _changed();
  }

  void _changed() {
    if (_disposed) return;
    _sorted = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _sub.cancel();
    super.dispose();
  }

  // ------------------------------------------------------------------ updates

  void _onUpdate(TdObject u) {
    final chatId = u['chat_id'] as int?;
    final chat = chatId == null ? null : _chats[chatId];
    switch (u['@type']) {
      case 'updateNewChat':
        final c = Map<String, dynamic>.of(u['chat'] as TdObject);
        _chats[c['id'] as int] = c;
      case 'updateChatTitle':
        chat?['title'] = u['title'];
      case 'updateChatPhoto':
        chat?['photo'] = u['photo'];
      case 'updateChatLastMessage':
        if (chat == null) return;
        chat['last_message'] = u['last_message'];
        for (final p in (u['positions'] as List? ?? const [])) {
          _setPosition(chat, p as TdObject);
        }
      case 'updateChatPosition':
        if (chat == null) return;
        _setPosition(chat, u['position'] as TdObject);
      case 'updateChatDraftMessage':
        if (chat == null) return;
        for (final p in (u['positions'] as List? ?? const [])) {
          _setPosition(chat, p as TdObject);
        }
      case 'updateChatReadInbox':
        chat?['last_read_inbox_message_id'] = u['last_read_inbox_message_id'];
        chat?['unread_count'] = u['unread_count'];
      case 'updateChatReadOutbox':
        chat?['last_read_outbox_message_id'] = u['last_read_outbox_message_id'];
      case 'updateChatUnreadMentionCount':
        chat?['unread_mention_count'] = u['unread_mention_count'];
      case 'updateChatNotificationSettings':
        chat?['notification_settings'] = u['notification_settings'];
      case 'updateChatPermissions':
        chat?['permissions'] = u['permissions'];
      case 'updateChatIsMarkedAsUnread':
        chat?['is_marked_as_unread'] = u['is_marked_as_unread'];
      case 'updateUser':
        final user = u['user'] as TdObject;
        _users[user['id'] as int] = Map<String, dynamic>.of(user);
      case 'updateUserStatus':
        final user = _users[u['user_id'] as int];
        if (user == null) return;
        user['status'] = u['status'];
      case 'updateBasicGroup':
        final g = u['basic_group'] as TdObject;
        _basicGroups[g['id'] as int] = g;
      case 'updateSupergroup':
        final g = u['supergroup'] as TdObject;
        _supergroups[g['id'] as int] = g;
      case 'updateNewMessage':
        final m = u['message'] as TdObject;
        _insert(m['chat_id'] as int, m);
      case 'updateMessageSendSucceeded' || 'updateMessageSendFailed':
        final m = u['message'] as TdObject;
        _replace(m['chat_id'] as int, u['old_message_id'] as int, m);
      case 'updateMessageContent':
        final m = _find(chatId!, u['message_id'] as int);
        if (m == null) return;
        m['content'] = u['new_content'];
      case 'updateDeleteMessages':
        if (u['is_permanent'] != true) return;
        final ids = (u['message_ids'] as List).cast<int>().toSet();
        _messages[chatId]?.removeWhere((m) => ids.contains(m['id']));
      case 'updateFile':
        final f = u['file'] as TdObject;
        _files[f['id'] as int] = _stateOf(f);
      default:
        return;
    }
    _changed();
  }

  static bool _sameList(TdObject a, TdObject b) =>
      a['@type'] == b['@type'] && a['chat_folder_id'] == b['chat_folder_id'];

  void _setPosition(TdObject chat, TdObject position) {
    final list = (chat['positions'] as List? ?? const []).cast<TdObject>().toList();
    list.removeWhere((p) => _sameList(p['list'] as TdObject, position['list'] as TdObject));
    if (position['order'] != '0' && position['order'] != 0) list.add(position);
    chat['positions'] = list;
  }

  static bool _mainPinned(TdObject chat) {
    for (final p in (chat['positions'] as List? ?? const [])) {
      final pos = p as TdObject;
      if ((pos['list'] as TdObject)['@type'] == _mainList) return pos['is_pinned'] == true;
    }
    return false;
  }

  static int _mainOrder(TdObject chat) {
    for (final p in (chat['positions'] as List? ?? const [])) {
      final pos = p as TdObject;
      if ((pos['list'] as TdObject)['@type'] == _mainList) {
        return int.tryParse('${pos['order']}') ?? 0;
      }
    }
    return 0;
  }

  TdObject? _find(int chatId, int messageId) {
    for (final m in _messages[chatId] ?? const <TdObject>[]) {
      if (m['id'] == messageId) return m;
    }
    return null;
  }

  void _insert(int chatId, TdObject m) {
    final list = _messages[chatId];
    if (list == null) return; // history not loaded yet; open() will fetch it
    if (list.any((x) => x['id'] == m['id'])) return;
    list.add(Map<String, dynamic>.of(m));
    list.sort((a, b) => (a['id'] as int).compareTo(b['id'] as int));
  }

  void _replace(int chatId, int oldId, TdObject m) {
    final list = _messages[chatId];
    if (list == null) return;
    list.removeWhere((x) => x['id'] == oldId);
    _insert(chatId, m);
  }

  static _FileState _stateOf(TdObject f) {
    final local = f['local'] as Map?;
    final done = local?['is_downloading_completed'] == true;
    final path = local?['path'] as String? ?? '';
    final size = (f['size'] as int?) ?? 0;
    return _FileState(
      path: done && path.isNotEmpty ? path : null,
      downloaded: (local?['downloaded_size'] as int?) ?? 0,
      total: size > 0 ? size : ((f['expected_size'] as int?) ?? 0),
      active: local?['is_downloading_active'] == true,
    );
  }

  /// Latest known state of a file. File objects inside messages can be
  /// older than `updateFile`, so the first one seen only seeds the map.
  _FileState _file(TdObject f) => _files.putIfAbsent(f['id'] as int, () => _stateOf(f));

  // ------------------------------------------------------------------ chats

  @override
  bool get loading => _loading;

  @override
  List<Chat> get chats => _sorted ??= _buildChats();

  List<Chat> _buildChats() {
    final entries = _chats.values.where((c) => _mainOrder(c) > 0).toList()
      ..sort((a, b) => _mainOrder(b).compareTo(_mainOrder(a)));
    return [for (final c in entries) _toChat(c)];
  }

  @override
  Chat? chatById(String id) {
    final c = _chats[int.tryParse(id)];
    return c == null ? null : _toChat(c);
  }

  TdObject? _userOf(TdObject chat) {
    final type = chat['type'] as TdObject;
    final userId = type['user_id'] as int?;
    if (userId == null) return null;
    final user = _users[userId];
    if (user == null) _requestUser(userId);
    return user;
  }

  ChatKind _kind(TdObject chat) {
    final type = chat['type'] as TdObject;
    switch (type['@type']) {
      case 'chatTypePrivate' || 'chatTypeSecret':
        if (type['user_id'] == _myId && _myId != 0) return ChatKind.saved;
        final user = _users[type['user_id']];
        return (user?['type'] as TdObject?)?['@type'] == 'userTypeBot' ? ChatKind.bot : ChatKind.private;
      case 'chatTypeSupergroup':
        return type['is_channel'] == true ? ChatKind.channel : ChatKind.group;
      default:
        return ChatKind.group;
    }
  }

  Chat _toChat(TdObject c) {
    final id = c['id'] as int;
    final kind = _kind(c);
    final user = _userOf(c);
    final last = c['last_message'] as TdObject?;
    final date = last == null ? null : DateTime.fromMillisecondsSinceEpoch((last['date'] as int) * 1000);
    final name = kind == ChatKind.saved ? 'Saqlangan xabarlar' : (c['title'] as String? ?? '');
    final muteFor = ((c['notification_settings'] as TdObject?)?['mute_for'] as int?) ?? 0;
    final phone = user?['phone_number'] as String? ?? '';
    return Chat(
      id: '$id',
      name: name,
      initials: Fmt.initials(name),
      color: Fmt.avatarColor(id),
      collection: '',
      last: last == null ? '' : _preview(last, kind),
      time: date == null ? '' : Fmt.listTime(date),
      status: _status(c, kind, user),
      unread: (c['unread_count'] as int?) ?? 0,
      waiting: _waiting(c, kind, last),
      online: kind == ChatKind.private && (user?['status'] as TdObject?)?['@type'] == 'userStatusOnline',
      muted: muteFor > 0,
      phone: phone.isEmpty ? '' : formatPhone(phone),
      about: _about[id] ?? '',
      photo: _photo(c['photo'] as TdObject?),
      kind: kind,
      pinned: _mainPinned(c),
      canSend: _canSend(c, kind, user),
    );
  }

  /// Telegram's own service account (login codes, security notices).
  static const _serviceUserId = 777000;

  /// Older incoming messages no longer count as "waiting for a reply".
  static const waitingWindow = Duration(days: 7);

  /// Private chats whose last message is a recent one from a real person,
  /// and groups where we were mentioned and have not looked yet.
  bool _waiting(TdObject chat, ChatKind kind, TdObject? last) {
    if (kind == ChatKind.group) return ((chat['unread_mention_count'] as int?) ?? 0) > 0;
    if (kind != ChatKind.private || last == null) return false;
    if (last['is_outgoing'] == true) return false;
    final userId = (chat['type'] as TdObject)['user_id'];
    if (userId == _serviceUserId) return false;
    final user = _users[userId];
    if ((user?['type'] as TdObject?)?['@type'] == 'userTypeDeleted') return false;
    final date = DateTime.fromMillisecondsSinceEpoch((last['date'] as int) * 1000);
    if (DateTime.now().difference(date) > waitingWindow) return false;
    return !_isService((last['content'] as TdObject)['@type'] as String);
  }

  /// Whether the composer should be shown: channels only for admins who may
  /// post, groups unless we left, were banned or are restricted.
  bool _canSend(TdObject chat, ChatKind kind, TdObject? user) {
    final type = chat['type'] as TdObject;
    switch (kind) {
      case ChatKind.private || ChatKind.bot || ChatKind.saved:
        return (user?['type'] as TdObject?)?['@type'] != 'userTypeDeleted';
      case ChatKind.channel || ChatKind.group:
        final g = type['@type'] == 'chatTypeBasicGroup'
            ? _basicGroups[type['basic_group_id']]
            : _supergroups[type['supergroup_id']];
        final status = g?['status'] as TdObject?;
        final st = status?['@type'];
        if (st == 'chatMemberStatusCreator') return true;
        if (st == 'chatMemberStatusAdministrator') {
          if (kind == ChatKind.group) return true;
          final rights = status!['rights'] as TdObject?;
          return rights?['can_post_messages'] == true;
        }
        if (kind == ChatKind.channel) return false;
        if (st == 'chatMemberStatusLeft' || st == 'chatMemberStatusBanned') return false;
        if (st == 'chatMemberStatusRestricted') {
          return (status!['permissions'] as TdObject?)?['can_send_basic_messages'] == true;
        }
        return (chat['permissions'] as TdObject?)?['can_send_basic_messages'] != false;
    }
  }

  String _status(TdObject chat, ChatKind kind, TdObject? user) {
    final type = chat['type'] as TdObject;
    switch (kind) {
      case ChatKind.saved:
        return 'shaxsiy bulut';
      case ChatKind.bot:
        return 'bot';
      case ChatKind.private:
        return _userStatus(user);
      case ChatKind.group || ChatKind.channel:
        final g = type['@type'] == 'chatTypeBasicGroup'
            ? _basicGroups[type['basic_group_id']]
            : _supergroups[type['supergroup_id']];
        final n = (g?['member_count'] as int?) ?? 0;
        if (n == 0) return kind == ChatKind.channel ? 'kanal' : 'guruh';
        return '${Fmt.count(n)} ${kind == ChatKind.channel ? 'obunachi' : 'a’zo'}';
    }
  }

  static String _userStatus(TdObject? user) {
    if (user == null) return '';
    if ((user['type'] as TdObject?)?['@type'] == 'userTypeDeleted') return 'o‘chirilgan akkaunt';
    final s = user['status'] as TdObject?;
    return switch (s?['@type']) {
      'userStatusOnline' => 'online',
      'userStatusOffline' => Fmt.lastSeen(DateTime.fromMillisecondsSinceEpoch((s!['was_online'] as int) * 1000)),
      'userStatusRecently' => 'yaqinda onlayn edi',
      'userStatusLastWeek' => 'shu hafta onlayn edi',
      'userStatusLastMonth' => 'shu oy onlayn edi',
      _ => 'uzoq vaqt oldin onlayn edi',
    };
  }

  /// Small profile photo path; starts the download the first time.
  String? _photo(TdObject? photo) {
    final small = photo?['small'] as TdObject?;
    if (small == null) return null;
    final state = _file(small);
    if (state.path == null) download(small['id'] as int);
    return state.path;
  }

  @override
  void download(int fileId, {int priority = 1}) {
    if (!_downloads.add(fileId)) return;
    if (_files[fileId]?.path != null) return;
    td.query({
      '@type': 'downloadFile',
      'file_id': fileId,
      'priority': priority,
      'offset': 0,
      'limit': 0,
      'synchronous': false,
    }).then<void>(
      (f) {
        if (f['id'] == fileId) {
          _files[fileId] = _stateOf(f);
          _changed();
        }
      },
      onError: (Object e) {
        _downloads.remove(fileId);
        debugPrint('downloadFile: $e');
      },
    );
  }

  void _requestUser(int userId) {
    if (!_userRequests.add(userId)) return;
    td.query({'@type': 'getUser', 'user_id': userId}).then<void>(
      (user) {
        _users[userId] = Map<String, dynamic>.of(user);
        _changed();
      },
      onError: (Object e) => debugPrint('getUser: $e'),
    );
  }

  String _senderName(TdObject m, {bool full = false}) {
    final s = m['sender_id'] as TdObject?;
    if (s == null) return '';
    if (s['@type'] == 'messageSenderChat') {
      return (_chats[s['chat_id']]?['title'] as String?) ?? '';
    }
    final userId = s['user_id'] as int;
    final user = _users[userId];
    if (user == null) {
      _requestUser(userId);
      return '';
    }
    final first = user['first_name'] as String? ?? '';
    final last = user['last_name'] as String? ?? '';
    return full && last.isNotEmpty ? '$first $last' : first;
  }

  String _preview(TdObject m, ChatKind kind) {
    final content = m['content'] as TdObject;
    final type = content['@type'] as String;
    final text = _contentText(content);
    if (_isService(type)) {
      final who = _senderName(m);
      return who.isEmpty ? text : '$who $text';
    }
    if (kind == ChatKind.channel || kind == ChatKind.saved) return text;
    if (m['is_outgoing'] == true) return 'Siz: $text';
    if (kind == ChatKind.group) {
      final who = _senderName(m);
      return who.isEmpty ? text : '$who: $text';
    }
    return text;
  }

  // ------------------------------------------------------------------ content

  static const _serviceTypes = {
    'messageChatAddMembers',
    'messageChatJoinByLink',
    'messageChatJoinByRequest',
    'messageChatDeleteMember',
    'messageChatChangeTitle',
    'messageChatChangePhoto',
    'messageChatDeletePhoto',
    'messagePinMessage',
    'messageBasicGroupChatCreate',
    'messageSupergroupChatCreate',
    'messageChatUpgradeTo',
    'messageChatUpgradeFrom',
    'messageContactRegistered',
    'messageChatSetMessageAutoDeleteTime',
    'messageScreenshotTaken',
    'messageCustomServiceAction',
  };

  static bool _isService(String type) => _serviceTypes.contains(type);

  static String _formatted(Object? f) {
    if (f is String) return f;
    if (f is Map) return (f['text'] as String?) ?? '';
    return '';
  }

  static String _caption(TdObject content) => _formatted(content['caption']);

  /// Short Uzbek text for any message content (used for previews too).
  static String _contentText(TdObject content) {
    String withCaption(String label) {
      final c = _caption(content);
      return c.isEmpty ? label : c;
    }

    return switch (content['@type']) {
      'messageText' => _formatted(content['text']),
      'messagePhoto' => withCaption('Rasm'),
      'messageVideo' => withCaption('Video'),
      'messageAnimation' => withCaption('GIF'),
      'messageSticker' => '${((content['sticker'] as TdObject?)?['emoji'] as String?) ?? ''} Stiker'.trim(),
      'messageVoiceNote' => withCaption('Ovozli xabar'),
      'messageVideoNote' => 'Video xabar',
      'messageAudio' => withCaption(((content['audio'] as TdObject?)?['title'] as String?)?.isNotEmpty == true
          ? (content['audio'] as TdObject)['title'] as String
          : 'Audio'),
      'messageDocument' => withCaption(((content['document'] as TdObject?)?['file_name'] as String?) ?? 'Fayl'),
      'messageLocation' => 'Joylashuv',
      'messageVenue' => 'Joy: ${((content['venue'] as TdObject?)?['title'] as String?) ?? ''}',
      'messageContact' => 'Kontakt',
      'messagePoll' => 'So‘rovnoma: ${_formatted((content['poll'] as TdObject?)?['question'])}',
      'messageCall' => 'Qo‘ng‘iroq',
      'messageDice' => (content['emoji'] as String?) ?? '🎲',
      'messageStory' => 'Hikoya',
      'messageChatAddMembers' => 'guruhga qo‘shildi',
      'messageChatJoinByLink' || 'messageChatJoinByRequest' => 'guruhga qo‘shildi',
      'messageChatDeleteMember' => 'guruhdan chiqdi',
      'messageChatChangeTitle' => 'guruh nomini «${content['title'] ?? ''}» ga o‘zgartirdi',
      'messageChatChangePhoto' => 'guruh rasmini o‘zgartirdi',
      'messageChatDeletePhoto' => 'guruh rasmini o‘chirdi',
      'messagePinMessage' => 'xabarni qadadi',
      'messageBasicGroupChatCreate' || 'messageSupergroupChatCreate' => 'guruh yaratdi',
      'messageChatUpgradeTo' || 'messageChatUpgradeFrom' => 'guruh superguruhga aylantirildi',
      'messageContactRegistered' => 'Telegram’ga qo‘shildi',
      'messageChatSetMessageAutoDeleteTime' => 'xabarlarni avtomatik o‘chirishni sozladi',
      'messageScreenshotTaken' => 'skrinshot oldi',
      'messageCustomServiceAction' => (content['text'] as String?) ?? '',
      _ => 'Xabar',
    };
  }

  static MediaKind? _mediaKind(String type) => switch (type) {
        'messagePhoto' => MediaKind.photo,
        'messageVideo' => MediaKind.video,
        'messageAnimation' => MediaKind.gif,
        'messageSticker' => MediaKind.sticker,
        'messageVoiceNote' => MediaKind.voice,
        'messageVideoNote' => MediaKind.videoNote,
        'messageLocation' || 'messageVenue' => MediaKind.location,
        'messageContact' => MediaKind.contact,
        'messagePoll' => MediaKind.poll,
        'messageCall' => MediaKind.call,
        'messageText' || 'messageDocument' || 'messageAudio' => null,
        _ => MediaKind.other,
      };

  Message _toMessage(TdObject m, TdObject chat, ChatKind kind) {
    final content = m['content'] as TdObject;
    final type = content['@type'] as String;
    final date = DateTime.fromMillisecondsSinceEpoch((m['date'] as int) * 1000);
    final out = m['is_outgoing'] == true && kind != ChatKind.channel;
    final sending = (m['sending_state'] as TdObject?)?['@type'];
    final readUpTo = (chat['last_read_outbox_message_id'] as int?) ?? 0;
    final id = m['id'] as int;

    if (_isService(type)) {
      final who = _senderName(m, full: true);
      final text = _contentText(content);
      return Message(id: '$id', text: who.isEmpty ? text : '$who $text', time: Fmt.hm(date), date: date, service: true);
    }

    String? fileName;
    String? fileMeta;
    if (type == 'messageDocument') {
      final doc = content['document'] as TdObject;
      fileName = (doc['file_name'] as String?) ?? 'Fayl';
      final size = ((doc['document'] as TdObject?)?['size'] as int?) ?? 0;
      final ext = fileName.contains('.') ? fileName.split('.').last.toUpperCase() : 'Fayl';
      fileMeta = '${Fmt.size(size)} · $ext';
    } else if (type == 'messageAudio') {
      final a = content['audio'] as TdObject;
      final title = (a['title'] as String?) ?? '';
      fileName = title.isNotEmpty ? title : ((a['file_name'] as String?) ?? 'Audio');
      final size = ((a['audio'] as TdObject?)?['size'] as int?) ?? 0;
      fileMeta = '${Fmt.size(size)} · Audio';
    }

    final media = _mediaKind(type);
    final formatted = type == 'messageText' ? content['text'] : content['caption'];
    final text = switch (type) {
      'messageText' => _formatted(content['text']),
      'messageDocument' || 'messageAudio' => _caption(content),
      _ => media == null ? '' : _caption(content),
    };
    final inGroup = kind == ChatKind.group && !out;
    final sender = inGroup ? _sender(m) : null;

    return Message(
      id: '$id',
      text: text,
      time: Fmt.hm(date),
      date: date,
      out: out,
      from: inGroup ? _senderName(m, full: true) : null,
      fileName: fileName,
      fileMeta: fileMeta,
      media: media,
      mediaLabel: media == null ? null : _contentText({...content, 'caption': null}),
      pending: sending == 'messageSendingStatePending',
      failed: sending == 'messageSendingStateFailed',
      read: out && id <= readUpTo,
      entities: text.isEmpty ? const [] : entitiesOf(formatted),
      info: _mediaInfo(content),
      senderId: sender?.id,
      senderInitials: sender?.initials ?? '',
      senderColor: sender?.color ?? 0,
      senderPhoto: sender?.photo,
    );
  }

  /// Who wrote a group message: id, initials, name color index, photo.
  ({String id, String initials, int color, String? photo})? _sender(TdObject m) {
    final s = m['sender_id'] as TdObject?;
    if (s == null) return null;
    final isChat = s['@type'] == 'messageSenderChat';
    final id = (isChat ? s['chat_id'] : s['user_id']) as int;
    final obj = isChat ? _chats[id] : _users[id];
    final name = isChat ? (obj?['title'] as String? ?? '') : _senderName(m, full: true);
    // Telegram's accent colors 0..6 are the classic peer colors; higher ids
    // are custom palettes, which fall back to the id-based color.
    final accent = obj?['accent_color_id'] as int?;
    final color = accent != null && accent >= 0 && accent < 7 ? accent : id.abs() % 7;
    final TdObject? photo;
    if (isChat) {
      photo = obj?['photo'] as TdObject?;
    } else {
      photo = obj?['profile_photo'] as TdObject?;
    }
    return (id: '$id', initials: Fmt.initials(name.isEmpty ? '?' : name), color: color, photo: _photo(photo));
  }

  /// Telegram text entities → [TextEntity] (offsets are UTF-16, like Dart).
  @visibleForTesting
  static List<TextEntity> entitiesOf(Object? formatted) {
    if (formatted is! Map) return const [];
    final list = formatted['entities'] as List? ?? const [];
    final out = <TextEntity>[];
    for (final e in list) {
      final type = (e as TdObject)['type'] as TdObject;
      final (EntityKind? kind, String? url) = switch (type['@type']) {
        'textEntityTypeBold' => (EntityKind.bold, null),
        'textEntityTypeItalic' => (EntityKind.italic, null),
        'textEntityTypeUnderline' => (EntityKind.underline, null),
        'textEntityTypeStrikethrough' => (EntityKind.strike, null),
        'textEntityTypeCode' => (EntityKind.code, null),
        'textEntityTypePre' || 'textEntityTypePreCode' => (EntityKind.pre, null),
        'textEntityTypeSpoiler' => (EntityKind.spoiler, null),
        'textEntityTypeBlockQuote' || 'textEntityTypeExpandableBlockQuote' => (EntityKind.quote, null),
        'textEntityTypeUrl' => (EntityKind.url, null),
        'textEntityTypeEmailAddress' => (EntityKind.url, 'mailto:'),
        'textEntityTypePhoneNumber' => (EntityKind.url, 'tel:'),
        'textEntityTypeTextUrl' => (EntityKind.textUrl, type['url'] as String?),
        'textEntityTypeMention' || 'textEntityTypeMentionName' => (EntityKind.mention, null),
        'textEntityTypeHashtag' || 'textEntityTypeCashtag' || 'textEntityTypeBotCommand' => (EntityKind.hashtag, null),
        _ => (null, null),
      };
      if (kind == null) continue;
      out.add(TextEntity(e['offset'] as int, e['length'] as int, kind, url: url));
    }
    return out;
  }

  static Uint8List? _mini(TdObject? o) {
    final data = (o?['minithumbnail'] as TdObject?)?['data'] as String?;
    if (data == null || data.isEmpty) return null;
    try {
      return base64Decode(data);
    } catch (_) {
      return null;
    }
  }

  /// Telegram packs voice waveforms as 5-bit values.
  @visibleForTesting
  static List<int> decodeWaveform(String? b64) {
    if (b64 == null || b64.isEmpty) return const [];
    final Uint8List bytes;
    try {
      bytes = base64Decode(b64);
    } catch (_) {
      return const [];
    }
    final count = bytes.length * 8 ~/ 5;
    return List.generate(count, (i) {
      final bit = i * 5;
      final byte = bit >> 3;
      final shift = bit & 7;
      final lo = bytes[byte];
      final hi = byte + 1 < bytes.length ? bytes[byte + 1] : 0;
      return ((lo | (hi << 8)) >> shift) & 31;
    });
  }

  /// Picks the photo size shown in the chat (about 800 px) and the largest
  /// one for the viewer.
  static (TdObject?, TdObject?) _photoSizes(List sizes) {
    final list = sizes.cast<TdObject>().where((s) => s['photo'] != null).toList()
      ..sort((a, b) => ((a['width'] as int) * (a['height'] as int)).compareTo((b['width'] as int) * (b['height'] as int)));
    if (list.isEmpty) return (null, null);
    final preview = list.firstWhere(
      (s) => math.max(s['width'] as int, s['height'] as int) >= 640,
      orElse: () => list.last,
    );
    return (preview, list.last);
  }

  MediaInfo? _mediaInfo(TdObject content) {
    MediaInfo build(
      MediaKind kind, {
      TdObject? owner,
      TdObject? preview,
      TdObject? file,
      int width = 0,
      int height = 0,
      int duration = 0,
      List<int> waveform = const [],
    }) {
      final p = preview == null ? null : _file(preview);
      final f = file == null ? null : _file(file);
      return MediaInfo(
        kind: kind,
        width: width,
        height: height,
        mini: _mini(owner),
        previewFileId: preview?['id'] as int?,
        previewPath: p?.path,
        fileId: file?['id'] as int?,
        filePath: f?.path,
        progress: f?.progress ?? 0,
        downloading: f?.active ?? false,
        duration: duration,
        waveform: waveform,
        size: f?.total ?? 0,
      );
    }

    // Only still images can be previews (video thumbnails may be MPEG-4).
    TdObject? stillThumb(TdObject? owner) {
      final t = owner?['thumbnail'] as TdObject?;
      final format = (t?['format'] as TdObject?)?['@type'];
      if (format == 'thumbnailFormatJpeg' || format == 'thumbnailFormatPng' || format == 'thumbnailFormatWebp') {
        return t!['file'] as TdObject?;
      }
      return null;
    }

    switch (content['@type']) {
      case 'messagePhoto':
        final photo = content['photo'] as TdObject;
        final (preview, largest) = _photoSizes(photo['sizes'] as List? ?? const []);
        if (preview == null) return null;
        return build(
          MediaKind.photo,
          owner: photo,
          preview: preview['photo'] as TdObject,
          file: largest!['photo'] as TdObject,
          width: preview['width'] as int,
          height: preview['height'] as int,
        );
      case 'messageVideo':
        final v = content['video'] as TdObject;
        return build(MediaKind.video,
            owner: v,
            preview: stillThumb(v),
            file: v['video'] as TdObject?,
            width: (v['width'] as int?) ?? 0,
            height: (v['height'] as int?) ?? 0,
            duration: (v['duration'] as int?) ?? 0);
      case 'messageAnimation':
        final a = content['animation'] as TdObject;
        return build(MediaKind.gif,
            owner: a,
            preview: stillThumb(a),
            file: a['animation'] as TdObject?,
            width: (a['width'] as int?) ?? 0,
            height: (a['height'] as int?) ?? 0,
            duration: (a['duration'] as int?) ?? 0);
      case 'messageVideoNote':
        final n = content['video_note'] as TdObject;
        final side = (n['length'] as int?) ?? 240;
        return build(MediaKind.videoNote,
            owner: n,
            preview: stillThumb(n),
            file: n['video'] as TdObject?,
            width: side,
            height: side,
            duration: (n['duration'] as int?) ?? 0);
      case 'messageVoiceNote':
        final v = content['voice_note'] as TdObject;
        return build(MediaKind.voice,
            file: v['voice'] as TdObject?,
            duration: (v['duration'] as int?) ?? 0,
            waveform: decodeWaveform(v['waveform'] as String?));
      case 'messageSticker':
        final s = content['sticker'] as TdObject;
        final webp = (s['format'] as TdObject?)?['@type'] == 'stickerFormatWebp';
        return build(MediaKind.sticker,
            owner: s,
            // Animated stickers (TGS/WebM) show their still thumbnail.
            preview: webp ? s['sticker'] as TdObject? : stillThumb(s),
            width: (s['width'] as int?) ?? 512,
            height: (s['height'] as int?) ?? 512);
      default:
        return null;
    }
  }

  // ------------------------------------------------------------------ messages

  @override
  List<Message> messagesOf(String chatId) {
    final id = int.tryParse(chatId);
    final chat = _chats[id];
    final list = _messages[id];
    if (chat == null || list == null) return const [];
    final kind = _kind(chat);
    return [for (final m in list) _toMessage(m, chat, kind)];
  }

  @override
  bool loadingHistory(String chatId) => _historyLoading.contains(int.tryParse(chatId));

  @override
  Future<void> open(String chatId) async {
    final id = int.parse(chatId);
    td.query({'@type': 'openChat', 'chat_id': id}).catchError((Object e) => <String, dynamic>{});
    if (!_messages.containsKey(id)) await _loadHistory(id);
  }

  @override
  void close(String chatId) {
    final id = int.tryParse(chatId);
    if (id == null) return;
    td.query({'@type': 'closeChat', 'chat_id': id}).catchError((Object e) => <String, dynamic>{});
  }

  @override
  Future<void> loadOlder(String chatId) => _loadHistory(int.parse(chatId));

  /// Fetches about [want] older messages. TDLib may answer with only a few
  /// messages from its local database first, so it is asked repeatedly.
  Future<void> _loadHistory(int chatId, {int want = 40}) async {
    if (_historyLoading.contains(chatId) || _historyDone.contains(chatId)) return;
    _historyLoading.add(chatId);
    final list = _messages[chatId] ??= [];
    _changed();
    try {
      var from = list.isEmpty ? 0 : list.first['id'] as int;
      var got = 0;
      for (var round = 0; round < 6 && got < want; round++) {
        final r = await td.query({
          '@type': 'getChatHistory',
          'chat_id': chatId,
          'from_message_id': from,
          'offset': 0,
          'limit': 50,
          'only_local': false,
        });
        final batch = (r['messages'] as List? ?? const []).whereType<Map<String, dynamic>>().toList();
        if (batch.isEmpty) {
          _historyDone.add(chatId);
          break;
        }
        for (final m in batch) {
          if (!list.any((x) => x['id'] == m['id'])) list.add(Map<String, dynamic>.of(m));
        }
        from = batch.last['id'] as int;
        got += batch.length;
      }
      list.sort((a, b) => (a['id'] as int).compareTo(b['id'] as int));
    } catch (e) {
      debugPrint('getChatHistory: $e');
    } finally {
      _historyLoading.remove(chatId);
      _changed();
    }
  }

  @override
  Future<void> loadDetails(String chatId) async {
    final id = int.parse(chatId);
    final chat = _chats[id];
    if (chat == null || _about.containsKey(id)) return;
    _about[id] = '';
    final type = chat['type'] as TdObject;
    try {
      switch (type['@type']) {
        case 'chatTypePrivate' || 'chatTypeSecret':
          final info = await td.query({'@type': 'getUserFullInfo', 'user_id': type['user_id']});
          _about[id] = _formatted(info['bio']);
        case 'chatTypeSupergroup':
          final info = await td.query({'@type': 'getSupergroupFullInfo', 'supergroup_id': type['supergroup_id']});
          _about[id] = (info['description'] as String?) ?? '';
          final g = _supergroups[type['supergroup_id']];
          if (g != null && info['member_count'] is int) {
            _supergroups[type['supergroup_id'] as int] = {...g, 'member_count': info['member_count']};
          }
        case 'chatTypeBasicGroup':
          final info = await td.query({'@type': 'getBasicGroupFullInfo', 'basic_group_id': type['basic_group_id']});
          _about[id] = (info['description'] as String?) ?? '';
      }
    } catch (e) {
      debugPrint('loadDetails: $e');
    }
    _changed();
  }

  @override
  Future<void> send(String chatId, String text) async {
    final t = text.trim();
    if (t.isEmpty) return;
    await td.query({
      '@type': 'sendMessage',
      'chat_id': int.parse(chatId),
      'input_message_content': {
        '@type': 'inputMessageText',
        'text': {'@type': 'formattedText', 'text': t},
        'clear_draft': true,
      },
    });
  }
}

class _FileState {
  const _FileState({this.path, this.downloaded = 0, this.total = 0, this.active = false});

  /// Set once the download is complete.
  final String? path;
  final int downloaded;
  final int total;
  final bool active;

  double get progress => path != null ? 1 : (total > 0 ? downloaded / total : 0);
}

import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import '../auth/auth.dart' show formatPhone;
import '../data/chat_source.dart';
import '../data/format.dart';
import '../data/meeting_parser.dart';
import '../data/models.dart';
import '../data/send_plan.dart';
import '../l10n/l10n.dart';
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
  final _incoming = StreamController<IncomingMessage>.broadcast();

  @override
  Stream<IncomingMessage> get incoming => _incoming.stream;

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

  /// Parsed meetings by "chatId:messageId" (message ids are unique per chat).
  final _meetings = <String, Meeting?>{};

  /// Raw messages of loaded saved items, so that [refreshFound] can
  /// rebuild them with the current download state.
  final _found = <String, TdObject>{};

  /// Who is typing (or recording, uploading) where: chat → sender → action.
  final _actions = <int, Map<int, ({String type, DateTime at})>>{};
  Timer? _actionSweep;

  /// Telegram clients drop a chat action this long after the last update.
  static const _actionTtl = Duration(seconds: 6);

  /// Telegram's clock minus this PC's clock (TDLib option `unix_time`), so
  /// that message freshness does not depend on the PC clock being right.
  Duration _serverOffset = Duration.zero;
  List<Chat>? _sorted;

  /// Language [_sorted] and [_meetings] were built in; both hold UI texts.
  S? _builtIn;

  static const _mainList = 'chatListMain';

  /// Loads the current user and the first pages of the main chat list.
  Future<void> start({int pages = 3}) async {
    try {
      final me = await td.query({'@type': 'getMe'});
      _myId = me['id'] as int;
      _users[_myId] = me;
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
    _actionSweep?.cancel();
    _incoming.close();
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
      case 'updateOption':
        if (u['name'] == 'unix_time') {
          final v = int.tryParse('${(u['value'] as TdObject?)?['value']}');
          if (v != null) _serverOffset = DateTime.fromMillisecondsSinceEpoch(v * 1000).difference(DateTime.now());
        }
        return;
      case 'updateChatAction':
        if ((u['message_thread_id'] as int? ?? 0) != 0) return;
        _onChatAction(chatId!, u['sender_id'] as TdObject, (u['action'] as TdObject)['@type'] as String);
      case 'updateBasicGroup':
        final g = u['basic_group'] as TdObject;
        _basicGroups[g['id'] as int] = g;
      case 'updateSupergroup':
        final g = u['supergroup'] as TdObject;
        _supergroups[g['id'] as int] = g;
      case 'updateNewMessage':
        final m = u['message'] as TdObject;
        _insert(m['chat_id'] as int, m);
        _announce(m);
      case 'updateMessageSendSucceeded' || 'updateMessageSendFailed':
        final m = u['message'] as TdObject;
        _replace(m['chat_id'] as int, u['old_message_id'] as int, m);
      case 'updateMessageContent':
        _meetings.remove('$chatId:${u['message_id']}');
        final m = _find(chatId!, u['message_id'] as int);
        if (m == null) return;
        m['content'] = u['new_content'];
      case 'updateMessageEdited':
        final m = _find(chatId!, u['message_id'] as int);
        if (m == null) return;
        m['edit_date'] = u['edit_date'];
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

  static bool _sameList(TdObject a, TdObject b) => a['@type'] == b['@type'] && a['chat_folder_id'] == b['chat_folder_id'];

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
    return _found['$chatId:$messageId'];
  }

  void _insert(int chatId, TdObject m) {
    if (_historical.contains(chatId)) {
      _found['$chatId:${m['id']}'] = Map<String, dynamic>.of(m);
      return;
    }
    final list = _messages[chatId];
    if (list == null) return; // history not loaded yet; open() will fetch it
    if (list.any((x) => x['id'] == m['id'])) return;
    list.add(Map<String, dynamic>.of(m));
    list.sort((a, b) => (a['id'] as int).compareTo(b['id'] as int));
  }

  // ------------------------------------------------------------ chat actions

  void _onChatAction(int chatId, TdObject sender, String type) {
    final isChat = sender['@type'] == 'messageSenderChat';
    final senderId = (isChat ? sender['chat_id'] : sender['user_id']) as int;
    if (!isChat && senderId == _myId) return;
    final map = _actions.putIfAbsent(chatId, () => {});
    if (type == 'chatActionCancel') {
      map.remove(senderId);
      if (map.isEmpty) _actions.remove(chatId);
    } else {
      map[senderId] = (type: type, at: DateTime.now());
    }
    if (_actions.isNotEmpty) {
      _actionSweep ??= Timer.periodic(const Duration(seconds: 2), (_) => _sweepActions());
    }
  }

  /// Drops actions nobody cancelled (the other client went away).
  void _sweepActions() {
    final cutoff = DateTime.now().subtract(_actionTtl);
    var dropped = false;
    for (final chat in _actions.keys.toList()) {
      final map = _actions[chat]!;
      final before = map.length;
      map.removeWhere((_, a) => a.at.isBefore(cutoff));
      if (map.isEmpty) _actions.remove(chat);
      if (map.length != before) dropped = true;
    }
    if (_actions.isEmpty) {
      _actionSweep?.cancel();
      _actionSweep = null;
    }
    if (dropped) _changed();
  }

  /// "yozmoqda…" for the chat header and list; in groups with the names.
  String _typingText(int chatId, ChatKind kind) {
    final map = _actions[chatId];
    if (map == null || map.isEmpty) return '';
    final t = S.current.chats;
    final label = switch (map.values.first.type) {
      'chatActionRecordingVoiceNote' || 'chatActionUploadingVoiceNote' => t.actionVoice,
      'chatActionRecordingVideo' || 'chatActionRecordingVideoNote' || 'chatActionUploadingVideoNote' => t.actionVideo,
      'chatActionUploadingPhoto' || 'chatActionUploadingVideo' || 'chatActionUploadingDocument' => t.actionFile,
      'chatActionChoosingSticker' => t.actionSticker,
      _ => t.actionTyping,
    };
    if (kind != ChatKind.group) return label;
    final names = [
      for (final id in map.keys.take(2)) (_users[id]?['first_name'] as String?) ?? (_chats[id]?['title'] as String?) ?? '',
    ].where((n) => n.isNotEmpty).toList();
    return names.isEmpty ? label : '${names.join(', ')} $label';
  }

  /// Messages older than this when they arrive (catch-up after being
  /// offline) get no toast: Telegram already showed them on the phone.
  static const _freshFor = Duration(minutes: 2);

  /// Emits [incoming] for a message from someone else that just arrived.
  void _announce(TdObject m) {
    if (m['is_outgoing'] == true || m['sending_state'] != null) return;
    final chat = _chats[m['chat_id'] as int];
    if (chat == null) return;
    final date = DateTime.fromMillisecondsSinceEpoch((m['date'] as int) * 1000);
    if (DateTime.now().add(_serverOffset).difference(date) > _freshFor) return;
    final kind = _kind(chat);
    final muteFor = ((chat['notification_settings'] as TdObject?)?['mute_for'] as int?) ?? 0;
    _incoming.add(IncomingMessage(
      chatId: '${chat['id']}',
      chatTitle: kind == ChatKind.saved ? S.current.chats.savedMessages : (chat['title'] as String? ?? ''),
      kind: kind,
      muted: muteFor > 0,
      preview: _contentText(m['content'] as TdObject),
      sender: kind == ChatKind.group ? _senderName(m, full: true) : null,
    ));
  }

  void _replace(int chatId, int oldId, TdObject m) {
    final list = _messages[chatId];
    if (list == null) return;
    final index = list.indexWhere((x) => x['id'] == oldId);
    if (index >= 0) {
      list[index] = Map<String, dynamic>.of(m);
      list.sort((a, b) => (a['id'] as int).compareTo(b['id'] as int));
    } else {
      _insert(chatId, m);
    }
  }

  static _FileState _stateOf(TdObject f) {
    final local = f['local'] as Map?;
    final done = local?['is_downloading_completed'] == true;
    final path = local?['path'] as String? ?? '';
    final size = (f['size'] as int?) ?? 0;
    final remote = f['remote'] as Map?;
    return _FileState(
      path: done && path.isNotEmpty ? path : null,
      downloaded: (local?['downloaded_size'] as int?) ?? 0,
      total: size > 0 ? size : ((f['expected_size'] as int?) ?? 0),
      active: local?['is_downloading_active'] == true,
      uploaded: (remote?['uploaded_size'] as int?) ?? 0,
    );
  }

  /// Latest known state of a file. File objects inside messages can be
  /// older than `updateFile`, so the first one seen only seeds the map.
  _FileState _file(TdObject f) => _files.putIfAbsent(f['id'] as int, () => _stateOf(f));

  // ------------------------------------------------------------------ chats

  @override
  bool get loading => _loading;

  @override
  List<Chat> get chats {
    _checkLanguage();
    return _sorted ??= _buildChats();
  }

  /// Drops cached texts (previews, statuses, meeting labels) after the UI
  /// language changed.
  void _checkLanguage() {
    if (identical(_builtIn, S.current)) return;
    _builtIn = S.current;
    _sorted = null;
    _meetings.clear();
  }

  List<Chat> _buildChats() {
    final entries = _chats.values.where((c) => _mainOrder(c) > 0).toList()..sort((a, b) => _mainOrder(b).compareTo(_mainOrder(a)));
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
    final name = kind == ChatKind.saved ? S.current.chats.savedMessages : (c['title'] as String? ?? '');
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
      typing: _typingText(id, kind),
      lastAt: date,
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
        final g = type['@type'] == 'chatTypeBasicGroup' ? _basicGroups[type['basic_group_id']] : _supergroups[type['supergroup_id']];
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
    final t = S.current.chats;
    switch (kind) {
      case ChatKind.saved:
        return t.statusCloud;
      case ChatKind.bot:
        return t.statusBot;
      case ChatKind.private:
        return _userStatus(user);
      case ChatKind.group || ChatKind.channel:
        final g = type['@type'] == 'chatTypeBasicGroup' ? _basicGroups[type['basic_group_id']] : _supergroups[type['supergroup_id']];
        final n = (g?['member_count'] as int?) ?? 0;
        if (n == 0) return kind == ChatKind.channel ? t.statusChannel : t.statusGroup;
        return kind == ChatKind.channel ? t.subscribers(n, Fmt.count(n)) : t.members(n, Fmt.count(n));
    }
  }

  static String _userStatus(TdObject? user) {
    if (user == null) return '';
    final t = S.current.chats;
    if ((user['type'] as TdObject?)?['@type'] == 'userTypeDeleted') return t.deletedAccount;
    final s = user['status'] as TdObject?;
    return switch (s?['@type']) {
      'userStatusOnline' => t.online,
      'userStatusOffline' => Fmt.lastSeen(DateTime.fromMillisecondsSinceEpoch((s!['was_online'] as int) * 1000)),
      'userStatusRecently' => t.lastSeenRecently,
      'userStatusLastWeek' => t.lastSeenWeek,
      'userStatusLastMonth' => t.lastSeenMonth,
      _ => t.lastSeenLongAgo,
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

  FileInfo? _fileInfo(TdObject f, {required bool uploading}) {
    if (f['id'] is! int) return null;
    final st = _files[f['id'] as int] ?? _file(f);
    final size = st.total > 0 ? st.total : ((f['size'] as int?) ?? 0);
    return FileInfo(
      fileId: f['id'] as int,
      size: size,
      path: st.path,
      progress: st.progress,
      downloading: st.active,
      uploadProgress: uploading ? (size > 0 ? (st.uploaded / size).clamp(0, 1).toDouble() : 0) : null,
    );
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
    if (m['is_outgoing'] == true) return '${S.current.chats.youPrefix}$text';
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
    'messageVideoChatScheduled',
    'messageVideoChatStarted',
    'messageVideoChatEnded',
    'messageInviteVideoChatParticipants',
    'messageChatBoost',
    'messageChatSetTheme',
    'messageChatSetBackground',
    'messageForumTopicCreated',
    'messageForumTopicEdited',
    'messageForumTopicIsClosedToggled',
    'messageForumTopicIsHiddenToggled',
    'messagePaymentSuccessful',
    'messageGiftedPremium',
    'messagePremiumGiftCode',
    'messageGift',
    'messageUpgradedGift',
    'messageProximityAlertTriggered',
    'messageWebAppDataSent',
    'messageBotWriteAccessAllowed',
    'messageChatShared',
    'messageUsersShared',
    'messageSuggestProfilePhoto',
  };

  static bool _isService(String type) => _serviceTypes.contains(type);

  static String _formatted(Object? f) {
    if (f is String) return f;
    if (f is Map) return (f['text'] as String?) ?? '';
    return '';
  }

  static String _caption(TdObject content) => _formatted(content['caption']);

  /// Short text in the UI language for any message content (used for
  /// previews too).
  static String _contentText(TdObject content) {
    final t = S.current.chats;
    String withCaption(String label) {
      final c = _caption(content);
      return c.isEmpty ? label : c;
    }

    return switch (content['@type']) {
      'messageText' => _formatted(content['text']),
      'messagePhoto' => withCaption(t.photo),
      'messageVideo' => withCaption(t.video),
      'messageAnimation' => withCaption('GIF'),
      'messageSticker' => '${((content['sticker'] as TdObject?)?['emoji'] as String?) ?? ''} ${t.sticker}'.trim(),
      'messageVoiceNote' => withCaption(t.voiceMessage),
      'messageVideoNote' => t.videoMessage,
      'messageAudio' => withCaption(((content['audio'] as TdObject?)?['title'] as String?)?.isNotEmpty == true
          ? (content['audio'] as TdObject)['title'] as String
          : t.audio),
      'messageDocument' => withCaption(((content['document'] as TdObject?)?['file_name'] as String?) ?? S.current.common.file),
      'messageLocation' => t.location,
      'messageVenue' => t.venue(((content['venue'] as TdObject?)?['title'] as String?) ?? ''),
      'messageContact' => t.contact,
      'messagePoll' => t.poll(_formatted((content['poll'] as TdObject?)?['question'])),
      'messageCall' => t.callMessage,
      'messageDice' => (content['emoji'] as String?) ?? '🎲',
      'messageAnimatedEmoji' => (content['emoji'] as String?) ?? '',
      'messageStory' => t.story,
      'messagePaidMedia' => withCaption(t.paidMedia),
      'messageInvoice' => ((content['product_info'] as TdObject?)?['title'] as String?) ?? t.invoice,
      'messageGiveaway' || 'messageGiveawayWinners' || 'messageGiveawayCompleted' || 'messageGiveawayPrizeStars' => t.giveaway,
      'messageUnsupported' => t.unsupportedMessage,
      'messageChatAddMembers' => t.joinedGroup,
      'messageChatJoinByLink' || 'messageChatJoinByRequest' => t.joinedGroup,
      'messageChatDeleteMember' => t.leftGroup,
      'messageChatChangeTitle' => t.changedGroupTitle('${content['title'] ?? ''}'),
      'messageChatChangePhoto' => t.changedGroupPhoto,
      'messageChatDeletePhoto' => t.deletedGroupPhoto,
      'messagePinMessage' => t.pinnedMessage,
      'messageBasicGroupChatCreate' || 'messageSupergroupChatCreate' => t.createdGroup,
      'messageChatUpgradeTo' || 'messageChatUpgradeFrom' => t.upgradedGroup,
      'messageContactRegistered' => t.joinedTelegram,
      'messageChatSetMessageAutoDeleteTime' => t.setAutoDelete,
      'messageScreenshotTaken' => t.tookScreenshot,
      'messageCustomServiceAction' => (content['text'] as String?) ?? '',
      'messageVideoChatScheduled' || 'messageVideoChatStarted' => t.videoChatStarted,
      'messageVideoChatEnded' => t.videoChatEnded,
      'messageChatBoost' => t.boostedChat,
      'messageForumTopicCreated' || 'messageForumTopicEdited' => t.topicChanged,
      _ => _unknown(content['@type'] as String),
    };
  }

  /// Debug builds log content types Focus does not name yet (type only,
  /// never the message itself).
  static String _unknown(String type) {
    if (kDebugMode && _loggedTypes.add(type)) debugPrint('message content not handled: $type');
    return S.current.chats.message;
  }

  static final _loggedTypes = <String>{};

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
        // Plain text bubbles: the text is the label (emoji, unsupported notice).
        'messageText' || 'messageDocument' || 'messageAudio' || 'messageAnimatedEmoji' || 'messageUnsupported' => null,
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
    TdObject? fileObj;
    if (type == 'messageDocument') {
      final doc = content['document'] as TdObject;
      fileObj = doc['document'] as TdObject?;
      fileName = (doc['file_name'] as String?) ?? S.current.common.file;
      final size = ((doc['document'] as TdObject?)?['size'] as int?) ?? 0;
      final ext = fileName.contains('.') ? fileName.split('.').last.toUpperCase() : S.current.common.file;
      fileMeta = '${Fmt.size(size)} · $ext';
    } else if (type == 'messageAudio') {
      final a = content['audio'] as TdObject;
      fileObj = a['audio'] as TdObject?;
      final title = (a['title'] as String?) ?? '';
      fileName = title.isNotEmpty ? title : ((a['file_name'] as String?) ?? S.current.chats.audio);
      final size = ((a['audio'] as TdObject?)?['size'] as int?) ?? 0;
      fileMeta = '${Fmt.size(size)} · ${S.current.chats.audio}';
    }

    final media = _mediaKind(type);
    final formatted = type == 'messageText' ? content['text'] : content['caption'];
    final text = switch (type) {
      'messageText' => _formatted(content['text']),
      'messageDocument' || 'messageAudio' => _caption(content),
      'messageAnimatedEmoji' || 'messageUnsupported' => _contentText(content),
      _ => media == null ? '' : _caption(content),
    };
    final inGroup = kind == ChatKind.group && !out;
    final sender = inGroup ? _sender(m) : null;
    // Relative days ("ertaga") count from the message date; only meetings
    // that have not passed are offered.
    final meet = text.isEmpty ? null : _meetings.putIfAbsent('${m['chat_id']}:$id', () => MeetingParser.parse(text, date));
    final showMeet = meet != null && meet.at.isAfter(DateTime.now().subtract(const Duration(hours: 2)));

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
      edited: ((m['edit_date'] as int?) ?? 0) > 0,
      entities: text.isEmpty ? const [] : entitiesOf(formatted),
      info: _mediaInfo(content),
      senderId: sender?.id,
      senderInitials: sender?.initials ?? '',
      senderColor: sender?.color ?? 0,
      senderPhoto: sender?.photo,
      meeting: showMeet ? meet.label : null,
      meetingAt: showMeet ? meet.at : null,
      file: fileObj == null ? null : _fileInfo(fileObj, uploading: sending == 'messageSendingStatePending'),
      reply: _replyInfo(m),
      forwardedFrom: _originName((m['forward_info'] as TdObject?)?['origin'] as TdObject?),
    );
  }

  String? _originName(TdObject? origin) {
    if (origin == null) return null;
    switch (origin['@type']) {
      case 'messageOriginUser':
        final u = _users[origin['sender_user_id']];
        final name = [u?['first_name'], u?['last_name']].whereType<String>().where((s) => s.isNotEmpty).join(' ');
        return name.isEmpty ? S.current.chats.deletedAccount : name;
      case 'messageOriginHiddenUser':
        return origin['sender_name'] as String?;
      case 'messageOriginChat':
        return _chats[origin['sender_chat_id']]?['title'] as String? ?? S.current.chats.message;
      case 'messageOriginChannel':
        return _chats[origin['chat_id']]?['title'] as String? ?? S.current.chats.message;
      default:
        return null;
    }
  }

  ReplyInfo? _replyInfo(TdObject message) {
    final reply = message['reply_to'] as TdObject?;
    if (reply?['@type'] != 'messageReplyToMessage') return null;
    final chatId = reply!['chat_id'] as int? ?? message['chat_id'] as int;
    final id = reply['message_id'] as int? ?? 0;
    final cached = _messages[chatId]?.where((m) => m['id'] == id).firstOrNull ?? _found['$chatId:$id'];
    if (cached == null && id != 0) _loadReply(chatId, id);
    final content = cached?['content'] as TdObject? ?? reply['content'] as TdObject?;
    final quote = _formatted((reply['quote'] as TdObject?)?['text']);
    final author = cached == null ? _originName(reply['origin'] as TdObject?) : _senderName(cached, full: true);
    return ReplyInfo(
        chatId: '$chatId',
        messageId: '$id',
        author: author?.isNotEmpty == true ? author! : (_chats[chatId]?['title'] as String? ?? S.current.chats.message),
        text: quote.isNotEmpty
            ? quote
            : content == null
                ? S.current.chats.message
                : _contentText(content));
  }

  final Set<String> _requestedReplies = {};
  void _loadReply(int chatId, int messageId) {
    final key = '$chatId:$messageId';
    if (_disposed || !_requestedReplies.add(key)) return;
    td.query({'@type': 'getMessage', 'chat_id': chatId, 'message_id': messageId}).then((m) {
      if (_disposed || m['@type'] != 'message') return;
      _found[key] = m;
      _changed();
    }).catchError((Object _) {});
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
            file: v['voice'] as TdObject?, duration: (v['duration'] as int?) ?? 0, waveform: decodeWaveform(v['waveform'] as String?));
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
    _checkLanguage();
    final kind = _kind(chat);
    return [for (final m in list) _toMessage(m, chat, kind)];
  }

  @override
  bool loadingHistory(String chatId) => _historyLoading.contains(int.tryParse(chatId));

  @override
  Future<void> open(String chatId) async {
    final id = int.parse(chatId);
    td.query({'@type': 'openChat', 'chat_id': id}).catchError((Object e) => <String, dynamic>{});
    if (_historical.contains(id)) {
      await historyAround(chatId, '0');
    } else if (!_messages.containsKey(id)) {
      await _loadHistory(id);
    }
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
    final generation = _historyNavigation[chatId] ?? 0;
    if (_disposed || _navigating.contains(chatId) || _historyLoading.contains(chatId) || _historyDone.contains(chatId)) return;
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
        if (_disposed || (_historyNavigation[chatId] ?? 0) != generation) return;
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
      // A latest-history jump may receive just one cached message while an
      // older page is in flight. Fill that latest window once the stale page
      // has released the loading slot.
      if (!_disposed &&
          (_historyNavigation[chatId] ?? 0) != generation &&
          !_historical.contains(chatId) &&
          !_navigating.contains(chatId) &&
          (_messages[chatId]?.length ?? 0) < want) {
        unawaited(_loadHistory(chatId));
      }
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
    await _sendText(chatId, text);
  }

  @override
  Future<void> sendReply(String chatId, String text, String messageId) => _sendText(chatId, text, replyTo: messageId);

  static TdObject _replyTo(String messageId) => {'@type': 'inputMessageReplyToMessage', 'message_id': int.parse(messageId)};

  Future<void> _sendText(String chatId, String text, {String? replyTo}) async {
    final t = text.trim();
    if (t.isEmpty) return;
    await td.query({
      '@type': 'sendMessage',
      'chat_id': int.parse(chatId),
      if (replyTo != null) 'reply_to': _replyTo(replyTo),
      'input_message_content': {
        '@type': 'inputMessageText',
        'text': {'@type': 'formattedText', 'text': t},
        'clear_draft': true,
      },
    });
  }

  /// A raw TDLib message as a [FoundFile]; fetches its chat if needed.
  Future<FoundFile?> _foundOf(TdObject m) async {
    final cid = m['chat_id'] as int;
    var chat = _chats[cid];
    if (chat == null) {
      // A chat outside the loaded list: fetch it once (also fills _chats).
      try {
        chat = Map<String, dynamic>.of(await td.query({'@type': 'getChat', 'chat_id': cid}));
        _chats[cid] = chat;
      } catch (_) {
        return null;
      }
    }
    final f = FoundFile(chatId: '$cid', chatTitle: _titleOf(chat), message: _toMessage(m, chat, _kind(chat)));
    _found[f.key] = m;
    return f;
  }

  @override
  Future<FoundFile?> getFound(String chatId, String messageId) async {
    final cached = _found['$chatId:$messageId'];
    if (cached != null) return _foundOf(cached);
    try {
      // getMessage only reads (td_api.tl of the pinned commit).
      final m = await td.query({'@type': 'getMessage', 'chat_id': int.parse(chatId), 'message_id': int.parse(messageId)});
      return _foundOf(m);
    } catch (_) {
      return null;
    }
  }

  String _titleOf(TdObject chat) => _kind(chat) == ChatKind.saved ? S.current.chats.savedMessages : (chat['title'] as String? ?? '');

  @override
  Message refreshFound(FoundFile f) {
    final raw = _found[f.key];
    final chat = _chats[int.parse(f.chatId)];
    if (raw == null || chat == null) return f.message;
    return _toMessage(raw, chat, _kind(chat));
  }

  @override
  Future<MessageRights> rightsOf(String chatId, String messageId) async {
    final p = await td.query({
      '@type': 'getMessageProperties',
      'chat_id': int.parse(chatId),
      'message_id': int.parse(messageId),
    });
    return MessageRights(
      canEdit: p['can_be_edited'] == true,
      canReply: p['can_be_replied'] == true,
      canForward: p['can_be_forwarded'] == true,
      canDeleteForMe: p['can_be_deleted_only_for_self'] == true,
      canDeleteForAll: p['can_be_deleted_for_all_users'] == true,
    );
  }

  @override
  Future<void> editText(String chatId, String messageId, String text) async {
    final id = int.parse(chatId);
    final m = await td.query({
      '@type': 'editMessageText',
      'chat_id': id,
      'message_id': int.parse(messageId),
      'input_message_content': {
        '@type': 'inputMessageText',
        'text': {'@type': 'formattedText', 'text': text.trim()},
      },
    });
    // The edited message comes back at once; updates follow as well.
    if (m['@type'] == 'message') {
      _meetings.remove('$chatId:$messageId');
      _replace(id, int.parse(messageId), m);
      _changed();
    }
  }

  @override
  Future<void> deleteMessages(String chatId, List<String> messageIds, {required bool forAll}) async {
    final id = int.parse(chatId);
    final ids = [for (final m in messageIds) int.parse(m)];
    await td.query({'@type': 'deleteMessages', 'chat_id': id, 'message_ids': ids, 'revoke': forAll});
    _messages[id]?.removeWhere((m) => ids.contains(m['id']));
    _changed();
  }

  @override
  Future<void> setPinned(String chatId, bool pinned) => td.query({
        '@type': 'toggleChatIsPinned',
        'chat_list': {'@type': _mainList},
        'chat_id': int.parse(chatId),
        'is_pinned': pinned,
      });

  @override
  Future<void> sendFiles(String chatId, List<OutgoingFile> files, {String caption = '', bool compressImages = true}) async {
    await _sendFiles(chatId, files, caption: caption, compressImages: compressImages);
  }

  @override
  Future<void> sendFilesReply(String chatId, List<OutgoingFile> files, String messageId,
          {String caption = '', bool compressImages = true}) =>
      _sendFiles(chatId, files, caption: caption, compressImages: compressImages, replyTo: messageId);

  Future<void> _sendFiles(String chatId, List<OutgoingFile> files,
      {String caption = '', bool compressImages = true, String? replyTo}) async {
    if (files.isEmpty) return;
    final id = int.parse(chatId);
    var text = caption.trim();
    if (text.length > kCaptionLimit) {
      await _sendText(chatId, text, replyTo: replyTo);
      text = '';
    }
    final planned = await planFiles(files, compressImages: compressImages);
    var first = true;
    for (final group in groupForSending(planned)) {
      final contents = [
        for (var i = 0; i < group.length; i++) inputContent(group[i], first && i == 0 ? text : ''),
      ];
      first = false;
      if (contents.length == 1) {
        await td.query({
          '@type': 'sendMessage',
          'chat_id': id,
          if (replyTo != null) 'reply_to': _replyTo(replyTo),
          'input_message_content': contents.single
        });
      } else {
        await td.query({
          '@type': 'sendMessageAlbum',
          'chat_id': id,
          if (replyTo != null) 'reply_to': _replyTo(replyTo),
          'input_message_contents': contents
        });
      }
    }
  }

  /// TDLib content for one file (shapes as in td_api.tl of the pinned TDLib).
  @visibleForTesting
  static TdObject inputContent(PlannedFile p, String caption) {
    final file = {'@type': 'inputFileLocal', 'path': p.file.path};
    final text = {'@type': 'formattedText', 'text': caption};
    if (p.asPhoto) {
      return {
        '@type': 'inputMessagePhoto',
        'photo': {'@type': 'inputPhoto', 'photo': file, 'width': p.width, 'height': p.height},
        'caption': text,
      };
    }
    return {
      '@type': 'inputMessageDocument',
      'document': {'@type': 'inputDocument', 'document': file},
      'caption': text,
    };
  }

  @override
  Future<void> forwardMessages(String chatId, String fromChatId, List<String> messageIds) async {
    if (messageIds.isEmpty) return;
    // Preserve attribution and let TDLib enforce protected-content rights.
    await td.query({
      '@type': 'forwardMessages',
      'chat_id': int.parse(chatId),
      'from_chat_id': int.parse(fromChatId),
      'message_ids': messageIds.map(int.parse).toList(),
      'send_copy': false,
      'remove_caption': false
    });
  }

  @override
  Future<MessageSearchPage> searchMessages(String chatId, String query, {String fromMessageId = '', int limit = 50}) async {
    final id = int.parse(chatId);
    final chat = _chats[id];
    if (chat == null || query.trim().isEmpty) return const MessageSearchPage(messages: [], total: 0);
    final result = await td.query({
      '@type': 'searchChatMessages',
      'chat_id': id,
      'query': query.trim(),
      'from_message_id': int.tryParse(fromMessageId) ?? 0,
      'offset': 0,
      'limit': limit.clamp(1, 100),
      'filter': {'@type': 'searchMessagesFilterEmpty'}
    });
    final raw = (result['messages'] as List? ?? const []).cast<TdObject>();
    for (final m in raw) {
      _found['$chatId:${m['id']}'] = m;
    }
    final next = result['next_from_message_id'] as int? ?? 0;
    return MessageSearchPage(
        messages: [for (final m in raw) _toMessage(m, chat, _kind(chat))],
        total: result['total_count'] as int? ?? raw.length,
        nextFromMessageId: next == 0 ? '' : '$next');
  }

  final Map<int, int> _historyNavigation = {};
  final Set<int> _historical = {};
  final Set<int> _navigating = {};

  @override
  Future<void> historyAround(String chatId, String messageId) async {
    final id = int.parse(chatId);
    final target = int.parse(messageId);
    final generation = (_historyNavigation[id] ?? 0) + 1;
    _historyNavigation[id] = generation;
    _navigating.add(id);
    try {
      final result = await td.query({
        '@type': 'getChatHistory',
        'chat_id': id,
        'from_message_id': target,
        'offset': target == 0 ? 0 : -20,
        'limit': 40,
        'only_local': false
      });
      final list = (result['messages'] as List? ?? const []).cast<TdObject>().map(TdObject.of).toList();
      if (target != 0 && !list.any((m) => m['id'] == target)) {
        list.add(await td.query({'@type': 'getMessage', 'chat_id': id, 'message_id': target}));
      }
      if (_disposed || _historyNavigation[id] != generation) return;
      // Replace the window instead of presenting disjoint history as contiguous.
      _messages[id] = list..sort((a, b) => (a['id'] as int).compareTo(b['id'] as int));
      if (target == 0) {
        _historical.remove(id);
      } else {
        _historical.add(id);
      }
      _historyDone.remove(id);
      _changed();
    } finally {
      if (_historyNavigation[id] == generation) _navigating.remove(id);
    }
    if (!_disposed && target == 0 && _historyNavigation[id] == generation && (_messages[id]?.length ?? 0) < 40) {
      await _loadHistory(id);
    }
  }
}

class _FileState {
  const _FileState({this.path, this.downloaded = 0, this.total = 0, this.active = false, this.uploaded = 0});

  /// Bytes already uploaded (outgoing files).
  final int uploaded;

  /// Set once the download is complete.
  final String? path;
  final int downloaded;
  final int total;
  final bool active;

  double get progress => path != null ? 1 : (total > 0 ? downloaded / total : 0);
}

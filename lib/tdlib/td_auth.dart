import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import '../auth/auth.dart';
import '../backup/backup_key_store.dart';
import '../data/chat_source.dart';
import '../data/local_store.dart';
import '../data/account_storage.dart';
import '../config.dart';
import '../l10n/l10n.dart';
import 'db_key.dart';
import 'td_backup.dart';
import 'td_chats.dart';
import 'td_client.dart';

/// Telegram login through TDLib: phone → code → 2FA password.
///
/// Owns the [TdClient]. After `logOut` TDLib closes the client; a new one is
/// started automatically so the user lands on the phone step again.
class TdAuth implements AuthService {
  TdAuth({this.libPath = 'tdjson.dll'});

  final String libPath;
  final _state = ValueNotifier(const AuthState(AuthStep.starting));
  TdClient? _td;
  StreamSubscription<TdObject>? _sub;
  bool _paramsSent = false;
  bool _disposed = false;

  /// The live client once [AuthStep.ready]; used by the chat layer (phase 1).
  TdClient? get client => _td;

  @override
  ValueListenable<AuthState> get state => _state;

  @override
  bool get isMock => false;

  @override
  Future<void> start() async {
    if (!AppConfig.hasTelegramKeys) {
      _fail(S.current.auth.noApiKeys);
      return;
    }
    _state.value = const AuthState(AuthStep.starting);
    _paramsSent = false;
    try {
      _td = await TdClient.start(libPath: libPath);
    } catch (e) {
      _fail(S.current.auth.tdlibLoadFailed);
      debugPrint('TDLib load failed: $e');
      return;
    }
    final td = _td!;
    _sub = td.updates.where((u) => u['@type'] == 'updateAuthorizationState').listen((u) => _onState(u['authorization_state'] as TdObject));
    // The first update may arrive before we subscribed, so ask explicitly.
    try {
      await _onState(await td.query({'@type': 'getAuthorizationState'}));
    } catch (e) {
      debugPrint('getAuthorizationState: $e');
    }
  }

  void _fail(String message) => _state.value = AuthState(AuthStep.failed, message: message);

  Future<void> _onState(TdObject s) async {
    switch (s['@type']) {
      case 'authorizationStateWaitTdlibParameters':
        if (_paramsSent) return;
        _paramsSent = true;
        try {
          await _setParameters();
        } on DbKeyException catch (e) {
          debugPrint('$e');
          _fail(S.current.auth.dbKeyFailed);
        } catch (e) {
          debugPrint('setTdlibParameters: $e');
          _fail(authErrorText(e));
        }
      case 'authorizationStateWaitPhoneNumber':
        _state.value = const AuthState(AuthStep.waitPhone);
      case 'authorizationStateWaitCode':
        _state.value = AuthState(AuthStep.waitCode, code: _codeInfo(s['code_info'] as TdObject));
      case 'authorizationStateWaitPassword':
        _state.value = AuthState(AuthStep.waitPassword, passwordHint: (s['password_hint'] as String?) ?? '');
      case 'authorizationStateWaitRegistration':
        _state.value = AuthState(
          AuthStep.unsupported,
          message: S.current.auth.noAccount,
        );
      case 'authorizationStateWaitEmailAddress' || 'authorizationStateWaitEmailCode':
        _state.value = AuthState(
          AuthStep.unsupported,
          message: S.current.auth.emailRequired,
        );
      case 'authorizationStateReady':
        try {
          await LocalMode.apply(_td!);
        } catch (e) {
          debugPrint('online=false: $e');
        }
        _state.value = const AuthState(AuthStep.ready);
      case 'authorizationStateLoggingOut' || 'authorizationStateClosing':
        _state.value = const AuthState(AuthStep.loggingOut);
      case 'authorizationStateClosed':
        await _sub?.cancel();
        await _td?.dispose();
        _td = null;
        if (!_disposed) await start();
      default:
        _state.value = AuthState(
          AuthStep.unsupported,
          message: S.current.auth.unknownMethod,
        );
    }
  }

  Future<void> _setParameters() async {
    final td = _td!;
    final base = await getApplicationSupportDirectory();
    final sep = Platform.pathSeparator;
    final db = Directory('${base.path}${sep}tdlib');
    final files = Directory('${db.path}${sep}files');
    await files.create(recursive: true);

    // Database encryption key, protected with DPAPI (see db_key.dart).
    var key = await DbKey.load(db);
    DbKey? migrateTo;
    if (key == null) {
      final hadDb = await File('${db.path}${sep}td.binlog').exists();
      if (hadDb) {
        // A database from a build without encryption: open it, then encrypt.
        migrateTo = DbKey.generate();
      } else {
        key = DbKey.generate();
        await key.save(db);
      }
    }

    await td.query({
      '@type': 'setTdlibParameters',
      'use_test_dc': false,
      'database_directory': db.path,
      'files_directory': files.path,
      'database_encryption_key': key == null ? '' : base64Encode(key.bytes),
      'use_file_database': true,
      'use_chat_info_database': true,
      'use_message_database': true,
      'use_secret_chats': false,
      'api_id': AppConfig.apiId,
      'api_hash': AppConfig.apiHash,
      'system_language_code': 'uz',
      'device_model': 'Windows PC',
      'system_version': Platform.operatingSystemVersion,
      'application_version': AppConfig.version,
    });

    if (migrateTo != null) {
      await migrateTo.save(db);
      try {
        await td.query({'@type': 'setDatabaseEncryptionKey', 'new_encryption_key': base64Encode(migrateTo.bytes)});
      } catch (e) {
        await DbKey.delete(db);
        rethrow;
      }
    }

    // Never appear online, even for a moment before authorization completes.
    try {
      await LocalMode.apply(td);
    } catch (e) {
      debugPrint('online=false before login: $e');
    }
  }

  static CodeDelivery _delivery(TdObject? t) => switch (t?['@type']) {
        'authenticationCodeTypeTelegramMessage' => CodeDelivery.telegram,
        'authenticationCodeTypeSms' || 'authenticationCodeTypeSmsWord' || 'authenticationCodeTypeSmsPhrase' => CodeDelivery.sms,
        'authenticationCodeTypeCall' => CodeDelivery.call,
        'authenticationCodeTypeFlashCall' => CodeDelivery.flashCall,
        'authenticationCodeTypeMissedCall' => CodeDelivery.missedCall,
        'authenticationCodeTypeFragment' => CodeDelivery.fragment,
        _ => CodeDelivery.other,
      };

  static CodeInfo _codeInfo(TdObject info) {
    final type = info['type'] as TdObject;
    final next = info['next_type'] as TdObject?;
    final phone = (info['phone_number'] as String?) ?? '';
    return CodeInfo(
      phone: phone.startsWith('+') ? phone : '+$phone',
      delivery: _delivery(type),
      length: (type['length'] as int?) ?? 0,
      next: next == null ? null : _delivery(next),
      timeout: (info['timeout'] as int?) ?? 0,
      textual: type['@type'] == 'authenticationCodeTypeSmsWord' || type['@type'] == 'authenticationCodeTypeSmsPhrase',
    );
  }

  Future<void> _call(TdObject request) async {
    final td = _td;
    if (td == null) throw AuthException(S.current.auth.notConnected);
    try {
      await td.query(request);
    } catch (e) {
      throw AuthException(authErrorText(e));
    }
  }

  @override
  Future<void> sendPhone(String phone) {
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    return _call({'@type': 'setAuthenticationPhoneNumber', 'phone_number': '+$digits'});
  }

  @override
  Future<void> sendCode(String code) => _call({'@type': 'checkAuthenticationCode', 'code': code.trim()});

  @override
  Future<void> sendPassword(String password) => _call({'@type': 'checkAuthenticationPassword', 'password': password});

  @override
  Future<void> resendCode() => _call({
        '@type': 'resendAuthenticationCode',
        'reason': {'@type': 'resendCodeReasonUserRequest'},
      });

  /// TDLib accepts a new phone number in the code, password and
  /// registration states, so going back is a UI-only step.
  @override
  void editPhone() => _state.value = const AuthState(AuthStep.waitPhone);

  @override
  Future<void> logOut() async {
    _state.value = const AuthState(AuthStep.loggingOut);
    try {
      await _td?.query({'@type': 'logOut'});
    } catch (e) {
      debugPrint('logOut: $e');
    }
  }

  @override
  Future<ChatSession> openSession() async {
    final td = _td;
    if (td == null) throw StateError('TDLib client is not running');
    final me = await td.query({'@type': 'getMe'});
    final id = me['id'];
    if (id is! int || id <= 0) throw StateError('Cannot identify the Telegram account');
    final storage = await AccountStorage.forAccount('$id');
    final db = await storage.open();
    final source = TdChatSource(td);
    try {
      final store = await LocalStore.openDb(db);
      unawaited(source.start());
      return ChatSession(
        source: source,
        store: store,
        db: db,
        backupTransport: TdBackupTransport(td),
        backupKeys: DpapiBackupKeyStore(directory: storage.directory),
        accountStorage: storage,
      );
    } catch (_) {
      source.dispose();
      await db.close();
      rethrow;
    }
  }

  Future<void> dispose() async {
    _disposed = true;
    await _sub?.cancel();
    await _td?.close();
    _state.dispose();
  }
}

/// TDLib errors → text in the current language for the login screen.
String authErrorText(Object e) {
  final t = S.current.auth;
  if (e is TimeoutException) return t.errTimeout;
  if (e is! TdError) return t.unexpectedError(e);
  final m = e.message;
  final wait = RegExp(r'(?:FLOOD_WAIT_|retry after )(\d+)').firstMatch(m)?.group(1);
  if (e.code == 429 || wait != null) {
    return t.errFloodWait(int.tryParse(wait ?? '') ?? 0);
  }
  return switch (m) {
    'PHONE_NUMBER_INVALID' => t.errPhoneInvalid,
    'PHONE_NUMBER_BANNED' => t.errPhoneBanned,
    'PHONE_NUMBER_FLOOD' => t.errPhoneFlood,
    'PHONE_CODE_INVALID' || 'PHONE_CODE_EMPTY' => t.errCodeInvalid,
    'PHONE_CODE_EXPIRED' => t.errCodeExpired,
    'PASSWORD_HASH_INVALID' => t.errPasswordInvalid,
    'SEND_CODE_UNAVAILABLE' => t.errNoResendMethod,
    'API_ID_INVALID' || 'API_ID_PUBLISHED_FLOOD' => t.errApiKeysInvalid,
    'AUTH_RESTART' => t.errAuthRestart,
    'Wrong database encryption key' => t.errDbKeyMismatch,
    _ => t.errTelegram(m),
  };
}

/// "Lokal rejim · telefon ta'sirlanmaydi" rules.
///
/// - Never report the user as online.
/// - Never call `viewMessages` (that is what marks messages as read on
///   every device). Opening a chat in Focus only clears the local badge.
/// - No typing actions (`sendChatAction`).
/// [TdClient] refuses to send [forbiddenRequests].
/// Known limit: sending a reply makes Telegram treat the chat as read.
class LocalMode {
  static Future<void> apply(TdClient td) async {
    await td.query({
      '@type': 'setOption',
      'name': 'online',
      'value': {'@type': 'optionValueBoolean', 'value': false},
    });
  }

  static const forbiddenRequests = {'viewMessages', 'sendChatAction', 'readAllChatMentions', 'readAllChatReactions'};
}

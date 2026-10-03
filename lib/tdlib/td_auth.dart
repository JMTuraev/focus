import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import '../auth/auth.dart';
import '../data/chat_source.dart';
import '../data/local_store.dart';
import '../config.dart';
import 'db_key.dart';
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
      _fail('Telegram API kalitlari berilmagan. secrets.json’ni to‘ldiring va ilovani '
          '--dart-define-from-file=secrets.json bilan ishga tushiring.');
      return;
    }
    _state.value = const AuthState(AuthStep.starting);
    _paramsSent = false;
    try {
      _td = await TdClient.start(libPath: libPath);
    } catch (e) {
      _fail('TDLib (tdjson.dll) yuklanmadi. tdlib\\ papkasidagi DLL’lar fokus.exe yonida ekanini tekshiring.');
      debugPrint('TDLib load failed: $e');
      return;
    }
    final td = _td!;
    _sub = td.updates
        .where((u) => u['@type'] == 'updateAuthorizationState')
        .listen((u) => _onState(u['authorization_state'] as TdObject));
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
          _fail('TDLib bazasining kaliti ochilmadi. Ehtimol, papka boshqa Windows foydalanuvchisidan ko‘chirilgan. '
              'Ilova ma’lumotlari ichidagi tdlib papkasini o‘chirib, qayta kiring.');
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
        _state.value = const AuthState(
          AuthStep.unsupported,
          message: 'Bu raqamda Telegram akkaunti yo‘q. Avval rasmiy Telegram ilovasida ro‘yxatdan o‘ting, '
              'keyin Fokus orqali kiring.',
        );
      case 'authorizationStateWaitEmailAddress' || 'authorizationStateWaitEmailCode':
        _state.value = const AuthState(
          AuthStep.unsupported,
          message: 'Telegram bu kirish uchun email tasdiqlashni so‘rayapti. Bu imkoniyat Fokus’da hali yo‘q. '
              'Avval rasmiy Telegram ilovasida emailni tasdiqlang, keyin qayta urinib ko‘ring.',
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
        _state.value = const AuthState(
          AuthStep.unsupported,
          message: 'Telegram kutilmagan tasdiqlash usulini so‘rayapti. Rasmiy Telegram ilovasi orqali kirib ko‘ring.',
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
        'authenticationCodeTypeSms' ||
        'authenticationCodeTypeSmsWord' ||
        'authenticationCodeTypeSmsPhrase' =>
          CodeDelivery.sms,
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
    if (td == null) throw AuthException('Telegram’ga ulanish hali tayyor emas. Bir oz kuting.');
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
    final source = TdChatSource(td);
    unawaited(source.start());
    return ChatSession(source: source, store: await LocalStore.open());
  }

  Future<void> dispose() async {
    _disposed = true;
    await _sub?.cancel();
    await _td?.close();
    _state.dispose();
  }
}

/// TDLib errors → Uzbek text for the login screen.
String authErrorText(Object e) {
  if (e is TimeoutException) {
    return 'Telegram javob bermadi. Internet aloqasini tekshirib, qayta urinib ko‘ring.';
  }
  if (e is! TdError) return 'Kutilmagan xatolik: $e';
  final m = e.message;
  final wait = RegExp(r'(?:FLOOD_WAIT_|retry after )(\d+)').firstMatch(m)?.group(1);
  if (e.code == 429 || wait != null) {
    final s = int.tryParse(wait ?? '') ?? 0;
    final when = s >= 120 ? '${(s / 60).ceil()} daqiqadan' : (s > 0 ? '$s soniyadan' : 'birozdan');
    return 'Juda ko‘p urinish bo‘ldi. $when keyin qayta urinib ko‘ring.';
  }
  return switch (m) {
    'PHONE_NUMBER_INVALID' => 'Telefon raqami noto‘g‘ri. Mamlakat kodi bilan to‘liq kiriting.',
    'PHONE_NUMBER_BANNED' => 'Bu raqam Telegram tomonidan bloklangan.',
    'PHONE_NUMBER_FLOOD' => 'Bu raqam uchun juda ko‘p kod so‘raldi. Keyinroq urinib ko‘ring.',
    'PHONE_CODE_INVALID' || 'PHONE_CODE_EMPTY' => 'Kod noto‘g‘ri. Qaytadan tekshirib kiriting.',
    'PHONE_CODE_EXPIRED' => 'Kodning muddati o‘tgan. Yangi kod so‘rang.',
    'PASSWORD_HASH_INVALID' => 'Parol noto‘g‘ri.',
    'SEND_CODE_UNAVAILABLE' => 'Kodni qayta yuborishning boshqa usuli qolmadi.',
    'API_ID_INVALID' || 'API_ID_PUBLISHED_FLOOD' =>
      'Telegram API kalitlari (api_id / api_hash) noto‘g‘ri. secrets.json’ni tekshiring.',
    'AUTH_RESTART' => 'Kirish jarayoni qayta boshlandi. Raqamni yana kiriting.',
    'Wrong database encryption key' =>
      'TDLib bazasini ochib bo‘lmadi (kalit mos emas). Ilova ma’lumotlari ichidagi tdlib papkasini o‘chirib, qayta kiring.',
    _ => 'Telegram xatosi: $m',
  };
}

/// "Lokal rejim · telefon ta'sirlanmaydi" rules.
///
/// - Never report the user as online.
/// - Never call `viewMessages` (that is what marks messages as read on
///   every device). Opening a chat in Fokus only clears the local badge.
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

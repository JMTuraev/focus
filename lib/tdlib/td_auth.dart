import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import '../config.dart';
import 'td_client.dart';

enum AuthStep { starting, waitPhone, waitCode, waitPassword, ready, loggingOut, closed, unknown }

/// Drives TDLib's authorization state machine.
/// UI listens to [step] and calls [sendPhone] / [sendCode] / [sendPassword].
class TdAuth {
  TdAuth(this.td);

  final TdClient td;
  final step = ValueNotifier<AuthStep>(AuthStep.starting);
  String? passwordHint;
  StreamSubscription<TdObject>? _sub;

  void attach() {
    _sub = td.updates.where((u) => u['@type'] == 'updateAuthorizationState').listen((u) {
      _onState(u['authorization_state'] as TdObject);
    });
  }

  Future<void> _onState(TdObject s) async {
    switch (s['@type']) {
      case 'authorizationStateWaitTdlibParameters':
        await _setParameters();
      case 'authorizationStateWaitPhoneNumber':
        step.value = AuthStep.waitPhone;
      case 'authorizationStateWaitCode':
        step.value = AuthStep.waitCode;
      case 'authorizationStateWaitPassword':
        passwordHint = s['password_hint'] as String?;
        step.value = AuthStep.waitPassword;
      case 'authorizationStateReady':
        await LocalMode.apply(td);
        step.value = AuthStep.ready;
      case 'authorizationStateLoggingOut':
        step.value = AuthStep.loggingOut;
      case 'authorizationStateClosed':
        step.value = AuthStep.closed;
      default:
        step.value = AuthStep.unknown;
    }
  }

  Future<void> _setParameters() async {
    if (!AppConfig.hasTelegramKeys) {
      throw StateError('TD_API_ID / TD_API_HASH berilmagan. secrets.json ni tekshiring.');
    }
    final base = await getApplicationSupportDirectory();
    final db = Directory('${base.path}${Platform.pathSeparator}tdlib');
    final files = Directory('${db.path}${Platform.pathSeparator}files');
    await files.create(recursive: true);

    await td.query({
      '@type': 'setTdlibParameters',
      'use_test_dc': false,
      'database_directory': db.path,
      'files_directory': files.path,
      // TODO(phase-1): random 32-byte key stored with Windows DPAPI
      // (flutter_secure_storage), passed here as base64.
      'database_encryption_key': '',
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
  }

  Future<void> sendPhone(String phone) =>
      td.query({'@type': 'setAuthenticationPhoneNumber', 'phone_number': phone});

  Future<void> sendCode(String code) => td.query({'@type': 'checkAuthenticationCode', 'code': code});

  Future<void> sendPassword(String password) =>
      td.query({'@type': 'checkAuthenticationPassword', 'password': password});

  Future<void> logOut() => td.query({'@type': 'logOut'});

  Future<void> dispose() async {
    await _sub?.cancel();
    step.dispose();
  }
}

/// "Lokal rejim · telefon ta'sirlanmaydi" rules.
///
/// - Never report the user as online.
/// - Never call `viewMessages` (that is what marks messages as read on
///   every device). Opening a chat in Fokus only clears the local badge.
/// - No typing actions (`sendChatAction`).
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

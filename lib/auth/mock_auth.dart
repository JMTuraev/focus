import 'package:flutter/foundation.dart';

import '../data/chat_source.dart';
import '../data/local_store.dart';
import '../data/mock_source.dart';
import '../l10n/l10n.dart';
import 'auth.dart';

/// Login without Telegram, for UI work (`USE_MOCK=true`).
///
/// Any phone with 9+ digits works. Any 5-digit code works except `00000`.
/// Any password works except `xato`.
class MockAuth implements AuthService {
  MockAuth({bool loggedIn = false, this.delay = const Duration(milliseconds: 600)})
      : _state = ValueNotifier(AuthState(loggedIn ? AuthStep.ready : AuthStep.starting));

  final Duration delay;
  final ValueNotifier<AuthState> _state;
  String _phone = '';

  @override
  ValueListenable<AuthState> get state => _state;

  @override
  bool get isMock => true;

  Future<void> _wait() => delay == Duration.zero ? Future.value() : Future.delayed(delay);

  @override
  Future<void> start() async {
    if (_state.value.step == AuthStep.ready) return;
    await _wait();
    _state.value = const AuthState(AuthStep.waitPhone);
  }

  @override
  Future<void> sendPhone(String phone) async {
    await _wait();
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 9) throw AuthException(S.current.auth.errPhoneInvalid);
    _phone = '+$digits';
    _state.value = AuthState(
      AuthStep.waitCode,
      code: CodeInfo(phone: _phone, delivery: CodeDelivery.telegram, length: 5, next: CodeDelivery.sms, timeout: 30),
    );
  }

  @override
  Future<void> sendCode(String code) async {
    await _wait();
    if (code.length != 5 || code == '00000') throw AuthException(S.current.auth.errCodeInvalid);
    _state.value = const AuthState(AuthStep.waitPassword, passwordHint: 'sevimli shahar');
  }

  @override
  Future<void> sendPassword(String password) async {
    await _wait();
    if (password.isEmpty || password == 'xato') throw AuthException(S.current.auth.errPasswordInvalid);
    _state.value = const AuthState(AuthStep.ready);
  }

  @override
  Future<void> resendCode() async {
    await _wait();
    _state.value = AuthState(
      AuthStep.waitCode,
      code: CodeInfo(phone: _phone, delivery: CodeDelivery.sms, length: 5),
    );
  }

  @override
  void editPhone() => _state.value = const AuthState(AuthStep.waitPhone);

  @override
  Future<ChatSession> openSession() async =>
      ChatSession(source: MockChatSource(), store: LocalStore.memory(), initialChatId: 'dilshod');

  @override
  Future<void> logOut() async {
    _state.value = const AuthState(AuthStep.loggingOut);
    await _wait();
    _state.value = const AuthState(AuthStep.waitPhone);
  }
}

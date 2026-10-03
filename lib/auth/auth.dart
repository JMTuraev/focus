import 'package:flutter/foundation.dart';

/// Login steps shown by the login screen.
enum AuthStep {
  /// Connecting to Telegram / opening the local database.
  starting,
  waitPhone,
  waitCode,
  waitPassword,
  ready,
  loggingOut,

  /// Telegram asks for something Fokus does not support yet
  /// (sign-up, e-mail confirmation). [AuthState.message] explains it.
  unsupported,

  /// TDLib could not start (missing DLL, missing API keys, broken database).
  failed,
}

/// How the login code was delivered.
enum CodeDelivery { telegram, sms, call, flashCall, missedCall, fragment, email, other }

@immutable
class CodeInfo {
  const CodeInfo({
    required this.phone,
    required this.delivery,
    required this.length,
    this.next,
    this.timeout = 0,
    this.textual = false,
  });

  /// Phone number in international format, digits only with a leading `+`.
  final String phone;
  final CodeDelivery delivery;

  /// Expected code length (0 when unknown).
  final int length;

  /// How a resent code would be delivered; null when it cannot be resent.
  final CodeDelivery? next;

  /// Seconds before the code can be resent.
  final int timeout;

  /// The "code" is a word or phrase from an SMS, not digits.
  final bool textual;
}

@immutable
class AuthState {
  const AuthState(this.step, {this.code, this.passwordHint = '', this.message = ''});

  final AuthStep step;
  final CodeInfo? code;
  final String passwordHint;
  final String message;
}

/// User-facing error (Uzbek text) from a login action.
class AuthException implements Exception {
  AuthException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Telegram login, backed by TDLib or by a mock for UI work.
abstract class AuthService {
  ValueListenable<AuthState> get state;

  /// True for the mock: the login screen shows test hints.
  bool get isMock;

  Future<void> start();

  /// Throws [AuthException].
  Future<void> sendPhone(String phone);

  /// Throws [AuthException].
  Future<void> sendCode(String code);

  /// Throws [AuthException].
  Future<void> sendPassword(String password);

  /// Throws [AuthException].
  Future<void> resendCode();

  /// Back to phone entry from the code, password or unsupported step.
  void editPhone();

  Future<void> logOut();
}

/// `+998901234567` → `+998 90 123 45 67`; other countries in groups of 3.
String formatPhone(String input) {
  final d = input.replaceAll(RegExp(r'\D'), '');
  if (d.isEmpty) return '+';
  if (d.startsWith('998')) {
    final parts = <String>['998'];
    var rest = d.substring(3);
    for (final n in [2, 3, 2, 2]) {
      if (rest.isEmpty) break;
      final take = rest.length < n ? rest.length : n;
      parts.add(rest.substring(0, take));
      rest = rest.substring(take);
    }
    if (rest.isNotEmpty) parts.add(rest);
    return '+${parts.join(' ')}';
  }
  final groups = <String>[];
  for (var i = 0; i < d.length; i += 3) {
    groups.add(d.substring(i, i + 3 > d.length ? d.length : i + 3));
  }
  return '+${groups.join(' ')}';
}

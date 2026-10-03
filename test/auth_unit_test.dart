import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:fokus/auth/auth.dart';
import 'package:fokus/tdlib/db_key.dart';
import 'package:fokus/tdlib/td_auth.dart';
import 'package:fokus/tdlib/td_client.dart';

void main() {
  group('formatPhone', () {
    test('Uzbek numbers', () {
      expect(formatPhone('+998901234567'), '+998 90 123 45 67');
      expect(formatPhone('99890'), '+998 90');
      expect(formatPhone('998'), '+998');
      expect(formatPhone(''), '+');
    });
    test('other countries in groups of three', () {
      expect(formatPhone('+79161234567'), '+791 612 345 67');
    });
  });

  group('authErrorText', () {
    test('known TDLib errors', () {
      expect(authErrorText(TdError(400, 'PHONE_CODE_INVALID')), 'Kod noto‘g‘ri. Qaytadan tekshirib kiriting.');
      expect(authErrorText(TdError(400, 'PASSWORD_HASH_INVALID')), 'Parol noto‘g‘ri.');
      expect(authErrorText(TdError(400, 'PHONE_NUMBER_INVALID')), contains('Telefon raqami noto‘g‘ri'));
    });
    test('flood wait with seconds and minutes', () {
      expect(authErrorText(TdError(429, 'Too Many Requests: retry after 45')), contains('45 soniyadan'));
      expect(authErrorText(TdError(420, 'FLOOD_WAIT_600')), contains('10 daqiqadan'));
    });
    test('timeout and unknown errors', () {
      expect(authErrorText(TimeoutException('x')), contains('Internet'));
      expect(authErrorText(TdError(400, 'SOMETHING_NEW')), 'Telegram xatosi: SOMETHING_NEW');
    });
  });

  test('local mode requests are refused before reaching TDLib', () {
    for (final type in LocalMode.forbiddenRequests) {
      expect(() => TdClient.checkAllowed({'@type': type}), throwsStateError);
    }
    TdClient.checkAllowed({'@type': 'getChats'});
  });

  group('DPAPI database key', () {
    late Directory dir;
    setUp(() => dir = Directory.systemTemp.createTempSync('fokus_key_test'));
    tearDown(() => dir.deleteSync(recursive: true));

    test('round trip through db.key', () async {
      expect(await DbKey.load(dir), isNull);
      final key = DbKey.generate();
      expect(key.bytes.length, 32);
      await key.save(dir);

      final raw = File('${dir.path}${Platform.pathSeparator}db.key').readAsBytesSync();
      expect(raw.length, greaterThan(32), reason: 'stored encrypted, not raw');
      expect(_contains(raw, key.bytes), isFalse, reason: 'plain key must not appear in the file');

      final loaded = await DbKey.load(dir);
      expect(loaded!.bytes, key.bytes);
    }, skip: !Platform.isWindows);

    test('a tampered file is rejected', () async {
      await DbKey.generate().save(dir);
      final f = File('${dir.path}${Platform.pathSeparator}db.key');
      final bytes = f.readAsBytesSync();
      bytes[bytes.length - 5] ^= 0xFF;
      f.writeAsBytesSync(bytes);
      expect(() => DbKey.load(dir), throwsA(isA<DbKeyException>()));
    }, skip: !Platform.isWindows);
  });
}

bool _contains(Uint8List hay, Uint8List needle) {
  for (var i = 0; i + needle.length <= hay.length; i++) {
    var ok = true;
    for (var j = 0; j < needle.length; j++) {
      if (hay[i + j] != needle[j]) {
        ok = false;
        break;
      }
    }
    if (ok) return true;
  }
  return false;
}

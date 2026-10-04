import 'dart:convert';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';

/// Backup errors with Uzbek messages for the UI.
class BackupException implements Exception {
  BackupException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Key-derivation settings stored in every backup header, so a backup can be
/// opened with the password on any PC, even if the defaults change later.
class KdfParams {
  const KdfParams({this.memoryKiB = 65536, this.iterations = 3, this.parallelism = 1});

  final int memoryKiB;
  final int iterations;
  final int parallelism;

  Map<String, int> toJson() => {'m': memoryKiB, 't': iterations, 'p': parallelism};

  static KdfParams fromJson(Map<String, dynamic> j) =>
      KdfParams(memoryKiB: j['m'] as int, iterations: j['t'] as int, parallelism: j['p'] as int);

  @override
  bool operator ==(Object other) =>
      other is KdfParams && other.memoryKiB == memoryKiB && other.iterations == iterations && other.parallelism == parallelism;

  @override
  int get hashCode => Object.hash(memoryKiB, iterations, parallelism);
}

/// A key derived from the backup password, with the salt and settings used.
class BackupKey {
  const BackupKey(this.key, this.salt, this.params);

  final Uint8List key;
  final Uint8List salt;
  final KdfParams params;
}

/// Encrypted backup file:
///
/// ```
/// "FOKUSBAK" | version(1) | kdf=1 (Argon2id) | memoryKiB u32 | iterations u32
/// | parallelism u8 | salt[16] | nonce[12] | AES-256-GCM(ciphertext) | tag[16]
/// ```
/// Everything before the ciphertext is authenticated as associated data, so
/// the header cannot be changed without the tag failing.
class BackupCrypto {
  static final magic = ascii.encode('FOKUSBAK');
  static const version = 1;
  static const _kdfArgon2id = 1;
  static const _saltLength = 16;
  static const _nonceLength = 12;
  static const _headerLength = 8 + 1 + 1 + 4 + 4 + 1 + _saltLength + _nonceLength;

  static final _aes = AesGcm.with256bits();

  /// Derives a key from [password]; a new random salt unless one is given.
  static Future<BackupKey> deriveKey(String password, {Uint8List? salt, KdfParams params = const KdfParams()}) async {
    final s = salt ?? Uint8List.fromList(SecretKeyData.random(length: _saltLength).bytes);
    final argon = Argon2id(
      memory: params.memoryKiB,
      iterations: params.iterations,
      parallelism: params.parallelism,
      hashLength: 32,
    );
    final key = await argon.deriveKeyFromPassword(password: password, nonce: s);
    return BackupKey(Uint8List.fromList(await key.extractBytes()), s, params);
  }

  static Future<Uint8List> encrypt(Uint8List plain, BackupKey key) async {
    final nonce = _aes.newNonce();
    final header = BytesBuilder()
      ..add(magic)
      ..addByte(version)
      ..addByte(_kdfArgon2id)
      ..add(_u32(key.params.memoryKiB))
      ..add(_u32(key.params.iterations))
      ..addByte(key.params.parallelism)
      ..add(key.salt)
      ..add(nonce);
    final aad = header.toBytes();
    final box = await _aes.encrypt(plain, secretKey: SecretKey(key.key), nonce: nonce, aad: aad);
    return (BytesBuilder()
          ..add(aad)
          ..add(box.cipherText)
          ..add(box.mac.bytes))
        .toBytes();
  }

  /// The salt and settings in a backup header (to derive the key).
  static (Uint8List salt, KdfParams params) readHeader(Uint8List data) {
    if (data.length < _headerLength + 16 || !_startsWithMagic(data)) {
      throw BackupException('Bu Fokus zaxira nusxasi emas yoki fayl buzilgan.');
    }
    if (data[8] != version || data[9] != _kdfArgon2id) {
      throw BackupException('Bu zaxira nusxasi Fokus’ning yangiroq versiyasida yaratilgan. Ilovani yangilang.');
    }
    final b = ByteData.sublistView(data);
    final params = KdfParams(memoryKiB: b.getUint32(10), iterations: b.getUint32(14), parallelism: data[18]);
    final salt = Uint8List.sublistView(data, 19, 19 + _saltLength);
    return (Uint8List.fromList(salt), params);
  }

  /// Decrypts with [key]; throws [BackupException] if the key is wrong or
  /// the file was changed.
  static Future<Uint8List> decrypt(Uint8List data, BackupKey key) async {
    readHeader(data);
    final aad = Uint8List.sublistView(data, 0, _headerLength);
    final nonce = Uint8List.sublistView(data, _headerLength - _nonceLength, _headerLength);
    final cipher = Uint8List.sublistView(data, _headerLength, data.length - 16);
    final mac = Mac(Uint8List.sublistView(data, data.length - 16));
    try {
      final plain = await _aes.decrypt(SecretBox(cipher, nonce: nonce, mac: mac), secretKey: SecretKey(key.key), aad: aad);
      return Uint8List.fromList(plain);
    } on SecretBoxAuthenticationError {
      throw BackupException('Parol noto‘g‘ri yoki zaxira fayli buzilgan.');
    }
  }

  /// Derives the key from [password] with the backup's own salt, then decrypts.
  static Future<Uint8List> decryptWithPassword(Uint8List data, String password) async {
    final (salt, params) = readHeader(data);
    return decrypt(data, await deriveKey(password, salt: salt, params: params));
  }

  static bool _startsWithMagic(Uint8List d) {
    for (var i = 0; i < magic.length; i++) {
      if (d[i] != magic[i]) return false;
    }
    return true;
  }

  static Uint8List _u32(int v) => Uint8List(4)..buffer.asByteData().setUint32(0, v);
}

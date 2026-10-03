import 'dart:ffi';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:ffi/ffi.dart';

/// Encryption key for the TDLib database, protected with Windows DPAPI.
///
/// A random 32-byte key is generated once and stored in `db.key`, encrypted
/// with `CryptProtectData` for the current Windows user. Other users, or a
/// copy of the folder on another PC, cannot decrypt it.
class DbKey {
  DbKey._(this.bytes);

  final Uint8List bytes;

  static const _entropy = 'fokus-tdlib-db-key-v1';

  static File _file(Directory dir) => File('${dir.path}${Platform.pathSeparator}db.key');

  /// Reads `db.key` from [dir]; null when there is none.
  /// Throws [DbKeyException] if it exists but cannot be decrypted
  /// (another Windows user, or copied from another PC).
  static Future<DbKey?> load(Directory dir) async {
    final file = _file(dir);
    if (!await file.exists()) return null;
    try {
      return DbKey._(Dpapi.unprotect(await file.readAsBytes(), entropy: _entropy));
    } catch (e) {
      throw DbKeyException('db.key ochilmadi: $e');
    }
  }

  /// A new random 32-byte key (not saved yet).
  static DbKey generate() {
    final rnd = Random.secure();
    return DbKey._(Uint8List.fromList(List.generate(32, (_) => rnd.nextInt(256))));
  }

  /// Writes the key to `db.key` in [dir], encrypted with DPAPI.
  Future<void> save(Directory dir) async {
    await dir.create(recursive: true);
    await _file(dir).writeAsBytes(Dpapi.protect(bytes, entropy: _entropy), flush: true);
  }

  static Future<void> delete(Directory dir) async {
    final f = _file(dir);
    if (await f.exists()) await f.delete();
  }
}

class DbKeyException implements Exception {
  DbKeyException(this.message);

  final String message;

  @override
  String toString() => message;
}

final class _DataBlob extends Struct {
  @Uint32()
  external int cbData;

  external Pointer<Uint8> pbData;
}

typedef _CryptC = Int32 Function(
    Pointer<_DataBlob>, Pointer<Utf16>, Pointer<_DataBlob>, Pointer<Void>, Pointer<Void>, Uint32, Pointer<_DataBlob>);
typedef _CryptD = int Function(
    Pointer<_DataBlob>, Pointer<Utf16>, Pointer<_DataBlob>, Pointer<Void>, Pointer<Void>, int, Pointer<_DataBlob>);
typedef _UnprotectC = Int32 Function(
    Pointer<_DataBlob>, Pointer<Pointer<Utf16>>, Pointer<_DataBlob>, Pointer<Void>, Pointer<Void>, Uint32, Pointer<_DataBlob>);
typedef _UnprotectD = int Function(
    Pointer<_DataBlob>, Pointer<Pointer<Utf16>>, Pointer<_DataBlob>, Pointer<Void>, Pointer<Void>, int, Pointer<_DataBlob>);
typedef _LocalFreeC = Pointer<Void> Function(Pointer<Void>);
typedef _LocalFreeD = Pointer<Void> Function(Pointer<Void>);

/// Minimal Windows DPAPI binding (current-user scope, no UI).
class Dpapi {
  static const _uiForbidden = 0x1; // CRYPTPROTECT_UI_FORBIDDEN

  static final _crypt32 = DynamicLibrary.open('crypt32.dll');
  static final _kernel32 = DynamicLibrary.open('kernel32.dll');
  static final _protect = _crypt32.lookupFunction<_CryptC, _CryptD>('CryptProtectData');
  static final _unprotect = _crypt32.lookupFunction<_UnprotectC, _UnprotectD>('CryptUnprotectData');
  static final _localFree = _kernel32.lookupFunction<_LocalFreeC, _LocalFreeD>('LocalFree');

  static Uint8List protect(Uint8List data, {required String entropy}) =>
      _run(data, entropy, (inp, ent, out) => _protect(inp, nullptr, ent, nullptr, nullptr, _uiForbidden, out), 'CryptProtectData');

  static Uint8List unprotect(Uint8List data, {required String entropy}) =>
      _run(data, entropy, (inp, ent, out) => _unprotect(inp, nullptr, ent, nullptr, nullptr, _uiForbidden, out), 'CryptUnprotectData');

  static Uint8List _run(
    Uint8List data,
    String entropy,
    int Function(Pointer<_DataBlob>, Pointer<_DataBlob>, Pointer<_DataBlob>) call,
    String name,
  ) {
    final entropyBytes = Uint8List.fromList(entropy.codeUnits);
    final inp = calloc<_DataBlob>();
    final ent = calloc<_DataBlob>();
    final out = calloc<_DataBlob>();
    final inBuf = calloc<Uint8>(data.length);
    final entBuf = calloc<Uint8>(entropyBytes.length);
    try {
      inBuf.asTypedList(data.length).setAll(0, data);
      entBuf.asTypedList(entropyBytes.length).setAll(0, entropyBytes);
      inp.ref
        ..cbData = data.length
        ..pbData = inBuf;
      ent.ref
        ..cbData = entropyBytes.length
        ..pbData = entBuf;
      if (call(inp, ent, out) == 0) {
        throw StateError('$name failed');
      }
      final outBytes = out.ref.pbData.asTypedList(out.ref.cbData);
      final result = Uint8List.fromList(outBytes);
      outBytes.fillRange(0, outBytes.length, 0);
      _localFree(out.ref.pbData.cast());
      return result;
    } finally {
      // Wipe the plaintext copy before freeing.
      inBuf.asTypedList(data.length).fillRange(0, data.length, 0);
      calloc.free(inBuf);
      calloc.free(entBuf);
      calloc.free(inp);
      calloc.free(ent);
      calloc.free(out);
    }
  }
}

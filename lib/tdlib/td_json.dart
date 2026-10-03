import 'dart:ffi';

import 'package:ffi/ffi.dart';

typedef _CreateC = Int32 Function();
typedef _CreateD = int Function();
typedef _SendC = Void Function(Int32, Pointer<Utf8>);
typedef _SendD = void Function(int, Pointer<Utf8>);
typedef _ReceiveC = Pointer<Utf8> Function(Double);
typedef _ReceiveD = Pointer<Utf8> Function(double);
typedef _ExecuteC = Pointer<Utf8> Function(Pointer<Utf8>);
typedef _ExecuteD = Pointer<Utf8> Function(Pointer<Utf8>);

/// Thin FFI binding over TDLib's JSON interface (tdjson.dll).
/// https://core.telegram.org/tdlib/docs/td__json__client_8h.html
class TdJson {
  TdJson._(DynamicLibrary lib)
      : _create = lib.lookupFunction<_CreateC, _CreateD>('td_create_client_id'),
        _send = lib.lookupFunction<_SendC, _SendD>('td_send'),
        _receive = lib.lookupFunction<_ReceiveC, _ReceiveD>('td_receive'),
        _execute = lib.lookupFunction<_ExecuteC, _ExecuteD>('td_execute');

  /// Looks for tdjson.dll next to fokus.exe by default.
  factory TdJson.open([String path = 'tdjson.dll']) => TdJson._(DynamicLibrary.open(path));

  final _CreateD _create;
  final _SendD _send;
  final _ReceiveD _receive;
  final _ExecuteD _execute;

  int createClientId() => _create();

  void send(int clientId, String request) {
    final p = request.toNativeUtf8();
    try {
      _send(clientId, p);
    } finally {
      malloc.free(p);
    }
  }

  /// Blocks up to [timeout] seconds. Must be called from one thread only.
  String? receive(double timeout) {
    final r = _receive(timeout);
    return r == nullptr ? null : r.toDartString();
  }

  /// Synchronous requests (only a few methods support it, e.g. log settings).
  String? execute(String request) {
    final p = request.toNativeUtf8();
    try {
      final r = _execute(p);
      return r == nullptr ? null : r.toDartString();
    } finally {
      malloc.free(p);
    }
  }
}

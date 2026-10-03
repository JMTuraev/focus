import 'dart:async';
import 'dart:convert';
import 'dart:isolate';

import 'td_json.dart';

typedef TdObject = Map<String, dynamic>;

class TdError implements Exception {
  TdError(this.code, this.message);

  final int code;
  final String message;

  @override
  String toString() => 'TdError($code): $message';
}

/// One TDLib client. `td_receive` runs in a background isolate so the UI
/// thread never blocks; requests are sent from the main isolate.
class TdClient {
  TdClient._(this._td, this._libPath);

  final TdJson _td;
  final String _libPath;
  late final int _clientId;
  Isolate? _isolate;
  ReceivePort? _port;
  int _seq = 0;

  final _pending = <String, Completer<TdObject>>{};
  final _updates = StreamController<TdObject>.broadcast();

  /// All updates (`update*` objects) from TDLib.
  Stream<TdObject> get updates => _updates.stream;

  static Future<TdClient> start({String libPath = 'tdjson.dll', int logLevel = 1}) async {
    final td = TdJson.open(libPath);
    td.execute(jsonEncode({'@type': 'setLogVerbosityLevel', 'new_verbosity_level': logLevel}));
    final client = TdClient._(td, libPath);
    client._clientId = td.createClientId();

    final port = ReceivePort();
    client._port = port;
    port.listen((msg) => client._dispatch(msg as String));
    client._isolate = await Isolate.spawn(_receiveLoop, (port.sendPort, libPath), debugName: 'td_receive');

    // A new client becomes active after its first request.
    client.send({'@type': 'getOption', 'name': 'version'});
    return client;
  }

  /// Fire-and-forget request.
  void send(TdObject request) => _td.send(_clientId, jsonEncode(request));

  /// Request with a response. Throws [TdError] when TDLib returns `error`.
  Future<TdObject> query(TdObject request, {Duration timeout = const Duration(seconds: 30)}) {
    final extra = 'q${++_seq}';
    final c = Completer<TdObject>();
    _pending[extra] = c;
    _td.send(_clientId, jsonEncode({...request, '@extra': extra}));
    return c.future.timeout(timeout, onTimeout: () {
      _pending.remove(extra);
      throw TimeoutException('TDLib: ${request['@type']}');
    });
  }

  void _dispatch(String raw) {
    final obj = jsonDecode(raw) as TdObject;
    final cid = obj['@client_id'];
    if (cid != null && cid != _clientId) return;
    final extra = obj['@extra'];
    if (extra is String) {
      final c = _pending.remove(extra);
      if (c == null) return;
      if (obj['@type'] == 'error') {
        c.completeError(TdError(obj['code'] as int, obj['message'] as String));
      } else {
        c.complete(obj);
      }
      return;
    }
    _updates.add(obj);
  }

  Future<void> close() async {
    try {
      await query({'@type': 'close'}, timeout: const Duration(seconds: 5));
    } catch (_) {}
    _isolate?.kill(priority: Isolate.immediate);
    _port?.close();
    await _updates.close();
  }

  String get libPath => _libPath;
}

void _receiveLoop((SendPort, String) args) {
  final (out, libPath) = args;
  final td = TdJson.open(libPath);
  while (true) {
    final r = td.receive(1.0);
    if (r != null) out.send(r);
  }
}

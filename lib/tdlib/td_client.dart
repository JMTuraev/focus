import 'dart:async';
import 'dart:convert';
import 'dart:isolate';

import 'td_auth.dart' show LocalMode;
import 'td_json.dart';

typedef TdObject = Map<String, dynamic>;

class TdError implements Exception {
  TdError(this.code, this.message);

  final int code;
  final String message;

  @override
  String toString() => 'TdError($code): $message';
}

/// What the chat layer needs from TDLib; [TdClient] implements it and tests
/// use a fake.
abstract class TdApi {
  Stream<TdObject> get updates;

  Future<TdObject> query(TdObject request, {Duration timeout});
}

/// One TDLib client. Requests are sent from the main isolate; responses and
/// updates come from a single shared background isolate that runs
/// `td_receive` (TDLib allows only one receiving thread).
class TdClient implements TdApi {
  TdClient._(this._td, this._clientId);

  final TdJson _td;
  final int _clientId;
  int _seq = 0;
  bool _closed = false;

  final _pending = <String, Completer<TdObject>>{};
  final _updates = StreamController<TdObject>.broadcast();

  /// All updates (`update*` objects) from TDLib.
  @override
  Stream<TdObject> get updates => _updates.stream;

  static Future<TdClient> start({String libPath = 'tdjson.dll', int logLevel = 1}) async {
    final td = TdJson.open(libPath);
    td.execute(jsonEncode({'@type': 'setLogVerbosityLevel', 'new_verbosity_level': logLevel}));
    final client = TdClient._(td, td.createClientId());
    _Receiver.clients[client._clientId] = client;
    await _Receiver.ensure(libPath);

    // A new client becomes active after its first request.
    client.send({'@type': 'getOption', 'name': 'version'});
    return client;
  }

  /// Throws if [request] would break local mode (see [LocalMode]).
  static void checkAllowed(TdObject request) {
    final type = request['@type'];
    if (LocalMode.forbiddenRequests.contains(type)) {
      throw StateError('Local mode: $type must never be sent (see LocalMode in td_auth.dart).');
    }
  }

  /// Fire-and-forget request.
  void send(TdObject request) {
    checkAllowed(request);
    _td.send(_clientId, jsonEncode(request));
  }

  /// Request with a response. Throws [TdError] when TDLib returns `error`.
  @override
  Future<TdObject> query(TdObject request, {Duration timeout = const Duration(seconds: 30)}) {
    checkAllowed(request);
    if (_closed) return Future.error(TdError(500, 'Client is closed'));
    final extra = 'q${++_seq}';
    final c = Completer<TdObject>();
    _pending[extra] = c;
    _td.send(_clientId, jsonEncode({...request, '@extra': extra}));
    return c.future.timeout(timeout, onTimeout: () {
      _pending.remove(extra);
      throw TimeoutException('TDLib: ${request['@type']}');
    });
  }

  void _dispatch(TdObject obj) {
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
    if (!_updates.isClosed) _updates.add(obj);
  }

  /// Asks TDLib to close the client, then releases it.
  Future<void> close() async {
    try {
      await query({'@type': 'close'}, timeout: const Duration(seconds: 5));
    } catch (_) {}
    await dispose();
  }

  /// Releases a client that TDLib already closed (`authorizationStateClosed`).
  Future<void> dispose() async {
    _closed = true;
    _Receiver.clients.remove(_clientId);
    for (final c in _pending.values) {
      c.completeError(TdError(500, 'Client is closed'));
    }
    _pending.clear();
    await _updates.close();
  }
}

/// The single `td_receive` loop shared by all clients.
class _Receiver {
  static final clients = <int, TdClient>{};
  static Future<void>? _started;

  static Future<void> ensure(String libPath) => _started ??= _spawn(libPath);

  static Future<void> _spawn(String libPath) async {
    final port = ReceivePort();
    port.listen((msg) {
      final obj = jsonDecode(msg as String) as TdObject;
      final client = clients[obj['@client_id']];
      client?._dispatch(obj);
    });
    await Isolate.spawn(_receiveLoop, (port.sendPort, libPath), debugName: 'td_receive');
  }
}

void _receiveLoop((SendPort, String) args) {
  final (out, libPath) = args;
  final td = TdJson.open(libPath);
  while (true) {
    final r = td.receive(1.0);
    if (r != null) out.send(r);
  }
}

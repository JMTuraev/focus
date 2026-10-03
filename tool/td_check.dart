// Quick check that tdjson.dll loads and answers.
//   dart run tool/td_check.dart [path\to\tdjson.dll]
import 'dart:convert';

import 'package:fokus/tdlib/td_json.dart';

void main(List<String> args) {
  final path = args.isNotEmpty ? args.first : 'tdlib/tdjson.dll';
  final td = TdJson.open(path);
  td.execute(jsonEncode({'@type': 'setLogVerbosityLevel', 'new_verbosity_level': 1}));
  final id = td.createClientId();
  td.send(id, jsonEncode({'@type': 'getOption', 'name': 'version', '@extra': 'v'}));

  final deadline = DateTime.now().add(const Duration(seconds: 10));
  while (DateTime.now().isBefore(deadline)) {
    final raw = td.receive(1.0);
    if (raw == null) continue;
    final obj = jsonDecode(raw) as Map<String, dynamic>;
    if (obj['@extra'] == 'v') {
      print('TDLib ishlayapti. Versiya: ${obj['value']}');
      td.send(id, jsonEncode({'@type': 'close'}));
      return;
    }
  }
  print('TDLib javob bermadi (10 s).');
}

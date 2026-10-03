import 'dart:io';

import 'package:flutter/services.dart';

/// Loads Windows' Segoe UI so text in widget tests has real metrics
/// (the default test font is much wider and would fake overflows).
Future<void> loadSegoeUi() async {
  final loader = FontLoader('Segoe UI');
  for (final f in [r'C:\Windows\Fonts\segoeui.ttf', r'C:\Windows\Fonts\segoeuib.ttf']) {
    final file = File(f);
    if (file.existsSync()) {
      loader.addFont(file.readAsBytes().then((b) => ByteData.view(b.buffer)));
    }
  }
  await loader.load();
}

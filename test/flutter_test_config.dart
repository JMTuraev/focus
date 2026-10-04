import 'dart:async';

import 'package:drift/drift.dart';

/// Runs before every test file: tests open many independent in-memory
/// databases on purpose, so drift's "created multiple times" warning is noise.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  await testMain();
}

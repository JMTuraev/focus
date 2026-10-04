/// Build-time configuration.
///
/// Telegram keys are passed at build time and never committed:
///   flutter run -d windows --dart-define-from-file=secrets.json
/// See secrets.example.json.
class AppConfig {
  static const int apiId = int.fromEnvironment('TD_API_ID');
  static const String apiHash = String.fromEnvironment('TD_API_HASH');

  /// When true (default), the app runs on mock data and never loads TDLib.
  /// Pass --dart-define=USE_MOCK=false once tdjson.dll is in place.
  static const bool useMock = bool.fromEnvironment('USE_MOCK', defaultValue: true);

  static const String version = '0.1.0';

  /// Public source code; also where people report bugs.
  static const String repoUrl = 'https://github.com/JMTuraev/focus';

  static bool get hasTelegramKeys => apiId != 0 && apiHash.isNotEmpty;
}

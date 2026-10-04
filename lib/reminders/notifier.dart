import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

/// Shows and schedules system notifications. Payloads are "event:ID" or
/// "task:ID" so a click can open the right place.
abstract class Notifier {
  /// Clicks on notifications while the app runs.
  Stream<String> get taps;

  /// The payload of the notification that started the app, if any.
  Future<String?> launchPayload();

  Future<void> schedule({required int id, required DateTime at, required String title, required String body, required String payload});

  Future<void> show({required int id, required String title, required String body, String payload = ''});

  Future<void> cancel(int id);

  /// Ids of notifications scheduled and not shown yet.
  Future<Set<int>> pendingIds();
}

/// Windows toasts via flutter_local_notifications. Scheduled toasts are kept
/// by Windows, so they appear even when Fokus is closed.
class WindowsNotifier implements Notifier {
  final _plugin = FlutterLocalNotificationsPlugin();
  final _taps = StreamController<String>.broadcast();
  bool _ready = false;

  /// Identity of the app for Windows' notification system. Never change these:
  /// Windows ties scheduled toasts and click activation to them.
  static const _settings = WindowsInitializationSettings(
    appName: 'Fokus',
    appUserModelId: 'Fokus.Desktop.App',
    guid: '6c3f2a8e-4b1d-4f7a-9e2c-5d8b1a0f3e71',
  );

  bool get ready => _ready;

  Future<bool> init() async {
    try {
      _ready = await _plugin.initialize(
            settings: const InitializationSettings(windows: _settings),
            onDidReceiveNotificationResponse: (r) {
              final p = r.payload;
              if (p != null && p.isNotEmpty) _taps.add(p);
            },
          ) ??
          false;
    } catch (e) {
      debugPrint('notifications init: $e');
      _ready = false;
    }
    return _ready;
  }

  @override
  Stream<String> get taps => _taps.stream;

  @override
  Future<String?> launchPayload() async {
    if (!_ready) return null;
    try {
      final d = await _plugin.getNotificationAppLaunchDetails();
      final p = d?.notificationResponse?.payload;
      return d?.didNotificationLaunchApp == true && p != null && p.isNotEmpty ? p : null;
    } catch (_) {
      return null;
    }
  }

  static const _details = NotificationDetails(windows: WindowsNotificationDetails());

  @override
  Future<void> schedule({required int id, required DateTime at, required String title, required String body, required String payload}) async {
    if (!_ready) return;
    await _plugin.zonedSchedule(
      id: id,
      scheduledDate: tz.TZDateTime.from(at.toUtc(), tz.UTC),
      notificationDetails: _details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      title: title,
      body: body,
      payload: payload,
    );
  }

  @override
  Future<void> show({required int id, required String title, required String body, String payload = ''}) async {
    if (!_ready) return;
    await _plugin.show(id: id, title: title, body: body, notificationDetails: _details, payload: payload);
  }

  @override
  Future<void> cancel(int id) async {
    if (_ready) await _plugin.cancel(id: id);
  }

  @override
  Future<Set<int>> pendingIds() async {
    if (!_ready) return {};
    final list = await _plugin.pendingNotificationRequests();
    return {for (final r in list) r.id};
  }
}

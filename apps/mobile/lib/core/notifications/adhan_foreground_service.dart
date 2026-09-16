import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';

/// Initializes and manages the adhan foreground task service.
/// This service runs when a prayer time arrives and the app is in background,
/// showing the adhan overlay screen as a full-screen notification.
class AdhanForegroundService {
  static const _channelId = 'adhan_channel';
  static const _channelName = 'أذان الصلاة';

  /// Initialize foreground task settings. Call once at app startup.
  static void initForegroundTask() {
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: _channelId,
        channelName: _channelName,
        channelDescription: 'إشعار أذان الصلاة',
        channelImportance: NotificationChannelImportance.MAX,
        priority: NotificationPriority.MAX,
        enableVibration: true,
        playSound: false, // audio handled inside the overlay screen
        visibility: NotificationVisibility.VISIBILITY_PUBLIC,
      ),
      iosNotificationOptions: const IOSNotificationOptions(
        showNotification: true,
        playSound: true,
      ),
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.nothing(),
        autoRunOnBoot: false,
        allowWifiLock: false,
      ),
    );
  }

  /// Start the foreground service for adhan with a persistent notification.
  /// Tapping the notification will show the AdhanOverlayScreen.
  static Future<void> startAdhanService({
    required String prayerName,
    required BuildContext context,
  }) async {
    // Check / request notification permission
    final perm = await FlutterForegroundTask.checkNotificationPermission();
    if (perm != NotificationPermission.granted) {
      await FlutterForegroundTask.requestNotificationPermission();
    }

    // Stop any existing service first
    if (await FlutterForegroundTask.isRunningService) {
      await FlutterForegroundTask.stopService();
    }

    await FlutterForegroundTask.startService(
      notificationTitle: 'حان وقت $prayerName 🕌',
      notificationText: 'اضغط لعرض شاشة الأذان',
      callback: _adhanCallback,
    );
  }

  /// Stop the foreground service (call when adhan overlay is dismissed).
  static Future<void> stopAdhanService() async {
    if (await FlutterForegroundTask.isRunningService) {
      await FlutterForegroundTask.stopService();
    }
  }
}

/// Top-level callback for the foreground task (must be top-level).
@pragma('vm:entry-point')
void _adhanCallback() {
  FlutterForegroundTask.setTaskHandler(_AdhanTaskHandler());
}

class _AdhanTaskHandler extends TaskHandler {
  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {}

  @override
  void onRepeatEvent(DateTime timestamp) {}

  @override
  Future<void> onDestroy(DateTime timestamp, bool isTimeout) async {}

  @override
  void onReceiveData(Object data) {}

  @override
  void onNotificationButtonPressed(String id) {}

  @override
  void onNotificationPressed() {
    // Signal the main isolate to show the AdhanOverlayScreen
    FlutterForegroundTask.sendDataToMain({'action': 'show_adhan'});
  }
}

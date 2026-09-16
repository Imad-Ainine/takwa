import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/widgets.dart' show Locale;
import 'package:takwa/core/notifications/notifications_service.dart';
import 'package:takwa/core/utils/app_logger.dart';
import 'package:takwa/l10n/app_localizations.dart';

/// The topic every device subscribes to — a single broadcast reaches every
/// installed copy of the app at once, with no per-device token registry to
/// maintain. See docs/specs/release-push-notifications.md for the full
/// design and the one-time Firebase project setup this needs.
const String kNewReleaseTopic = 'new_release';

/// Real push notifications (Firebase Cloud Messaging), scaffolded to be a
/// complete no-op until a Firebase project's `google-services.json` /
/// `GoogleService-Info.plist` is actually added to the app — every method
/// here is wrapped so a missing/invalid config never crashes app startup,
/// only silently skips push. Until then,
/// `core/updates/update_check_service.dart` is what actually notifies users
/// of a new release (checked in-app on launch).
class PushNotificationService {
  static bool _initialized = false;

  static Future<void> initialize() async {
    if (_initialized) return;
    try {
      await Firebase.initializeApp();
      // Registered here (not top-level in main()) so it stays inside the
      // same try/catch as initializeApp() itself — this app has no
      // google-services.json yet, and neither call should be reachable
      // without the other succeeding first.
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    } catch (e, st) {
      // No google-services.json/GoogleService-Info.plist yet — expected
      // until the Firebase project from the setup doc is wired up.
      AppLogger.warning('Firebase not configured, push notifications disabled', e, st);
      return;
    }
    _initialized = true;

    try {
      await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
    } catch (e, st) {
      AppLogger.warning('Push notification permission request failed', e, st);
    }

    try {
      await FirebaseMessaging.instance.subscribeToTopic(kNewReleaseTopic);
    } catch (e, st) {
      AppLogger.warning('Failed to subscribe to $kNewReleaseTopic topic', e, st);
    }

    // Foreground: FCM never auto-displays a notification while the app is
    // open, so show our own local one through the existing plugin/channel.
    FirebaseMessaging.onMessage.listen(_showForCurrentMessage);

    // App was backgrounded (not killed) and the user tapped the system
    // notification — same routing NotificationRouter already uses for
    // local notifications.
    FirebaseMessaging.onMessageOpenedApp.listen(_route);

    // App was fully killed and got launched by tapping the notification.
    try {
      final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
      if (initialMessage != null) {
        _route(initialMessage);
      }
    } catch (e, st) {
      AppLogger.warning('Failed to read initial push message', e, st);
    }
  }

  static Future<void> _showForCurrentMessage(RemoteMessage message) async {
    final data = message.data;
    if (data['type'] != 'release_update') return;
    final version = data['version'] as String? ?? '';
    final url = data['url'] as String? ?? '';
    if (url.isEmpty) return;

    // Grant-time text is Arabic-only for now, same rationale as the
    // existing achievement-grant text (see StatsDao.checkAndGrantAchievements'
    // own comment) — no locale switcher reaches this background code path.
    final l10n = lookupAppLocalizations(const Locale('ar'));
    await NotificationsService.showNotification(
      id: NotifIds.appUpdate,
      title: message.notification?.title ?? l10n.updateAvailableNotifTitle,
      body: message.notification?.body ?? l10n.updateAvailableNotifBody(version),
      payload: 'release_update:$url',
      channel: NotifChannels.appUpdates,
    );
  }

  static void _route(RemoteMessage message) {
    final url = message.data['url'] as String?;
    if (url == null || url.isEmpty) return;
    NotificationRouter.route('release_update:$url');
  }
}

/// Required by firebase_messaging even though this app has nothing to
/// process in the background beyond what Android already displays
/// automatically for a "notification" message — must be a top-level
/// function (not a static method) per the plugin's isolate requirements.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {}

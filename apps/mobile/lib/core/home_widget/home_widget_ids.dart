/// Shared identifiers every home-screen widget service needs.
///
/// Pulled out of `PrayerHomeWidgetService` once a second and third widget
/// (dua-of-the-day, dhikr-of-the-day — see `daily_quote_widget_service.dart`)
/// needed the same App Group: single source of truth instead of three
/// copies of the same string that could drift.
class HomeWidgetIds {
  HomeWidgetIds._();

  /// Shared storage container every iOS widget extension target reads and
  /// the app writes. Must match the App Group added to *both* the Runner
  /// app target's and every widget extension target's entitlements in
  /// Xcode — see ios/PrayerWidget/SETUP.md.
  static const iOSAppGroupId = 'group.com.takwa.PrayerWidget';
}

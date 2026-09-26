/// Single source of truth for the fixed schedule parameters that decide
/// *when* prayer-related things happen, shared by the notification
/// scheduler and the Prayer/Home UIs.
///
/// Before this, the iqama offsets existed twice — `_kIqamaOffsets` in
/// prayer_screen.dart and a private literal map in
/// NotificationsService.schedulePrayerNotifications — so changing one
/// (e.g. Maghrib 5 → 7) silently desynced the on-screen iqama countdown
/// from the scheduled notification.
class PrayerScheduleParams {
  const PrayerScheduleParams._();

  /// Minutes after adhan until iqama, keyed by prayer name. Sunrise is
  /// deliberately absent (no alerts for it).
  static const Map<String, int> iqamaOffsets = {
    'fajr': 20,
    'dhuhr': 15,
    'asr': 15,
    'maghrib': 5,
    'isha': 15,
  };

  /// Fallback for an unknown prayer key — matches the local convention at
  /// every previous call site.
  static int iqamaOffsetMinutes(String prayerName) =>
      iqamaOffsets[prayerName] ?? 15;

  static Duration iqamaOffset(String prayerName) =>
      Duration(minutes: iqamaOffsetMinutes(prayerName));

  /// How far before adhan the "prayer is coming" reminder fires.
  static const Duration preAdhanLead = Duration(minutes: 15);
}

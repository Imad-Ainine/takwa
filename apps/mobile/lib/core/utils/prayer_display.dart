import 'package:takwa/l10n/app_localizations.dart';

/// Single source of truth for a prayer key's emoji and localized display
/// name. Was previously duplicated verbatim in multiple widgets (each with
/// its own hardcoded-Arabic `_getEmoji`/`_getArabicName` pair), which meant
/// every copy had to be found and fixed separately for i18n.
String prayerEmoji(String key) => switch (key) {
  'fajr' => '🌙',
  'sunrise' => '🌅',
  'dhuhr' => '🌤',
  'asr' => '🌇',
  'maghrib' => '🌆',
  'isha' => '🌃',
  _ => '🕌',
};

String prayerLocalizedName(AppLocalizations l10n, String key) => switch (key) {
  'fajr' => l10n.prayerFajr,
  'sunrise' => l10n.prayerSunrise,
  'dhuhr' => l10n.prayerDhuhr,
  'jumuah' => l10n.prayerJumuah,
  'asr' => l10n.prayerAsr,
  'maghrib' => l10n.prayerMaghrib,
  'isha' => l10n.prayerIsha,
  _ => key,
};

import 'package:takwa/l10n/app_localizations.dart';

/// Localized Hijri month name for a 1-based month number (1 = Muharram,
/// 12 = Dhu al-Hijjah), as returned by `HijriCalendar.hMonth`.
///
/// Single source of truth — was previously a private, duplicated-on-demand
/// `_hMonth` helper on `HomeScreen`; the prayer home-screen widget needs
/// the same mapping without a `BuildContext`, hence pulling it out (see
/// `prayer_display.dart`'s `prayerLocalizedName` for the same pattern).
String hijriMonthName(AppLocalizations l10n, int month) => [
  l10n.hijriMuharram,
  l10n.hijriSafar,
  l10n.hijriRabiAlAwwal,
  l10n.hijriRabiAlThani,
  l10n.hijriJumadaAlAwwal,
  l10n.hijriJumadaAlThani,
  l10n.hijriRajab,
  l10n.hijriShaban,
  l10n.hijriRamadan,
  l10n.hijriShawwal,
  l10n.hijriDhulQadah,
  l10n.hijriDhulHijjah,
][month - 1];

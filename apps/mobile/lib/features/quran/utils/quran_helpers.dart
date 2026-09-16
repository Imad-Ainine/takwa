import 'package:flutter/material.dart';
import 'package:hijri/hijri_calendar.dart';
import 'package:takwa/l10n/app_localizations.dart';
import '../data/quran_data.dart';

// ─── Color Palette ────────────────────────────────────────────
const kGold = Color(0xFFC8A96E);
const kGoldL = Color(0xFFE4C98A);
const kGoldD = Color(0xFF9A7040);
const kTeal = Color(0xFF3AAFA9);
const kNight = Color(0xFF0D1117);
const kCard = Color(0xFF1A2332);
const kBorder = Color(0xFF2A3A50);
const kText = Color(0xFFE8EDF3);
const kTextS = Color(0xFF8FA3BB);

// Khatma Green Palette
const kGreen = Color(0xFF1A5C3A); // main green
const kGreenDark = Color(0xFF0D3D24); // darker bg
const kGreenMid = Color(0xFF2A7A4E); // lighter card
const kGreenCard = Color(0xFF1E6B43); // action card
const kGoldChip = Color(0xFFD4A843); // chip badge
const kOlive = Color(0xFF7A6833); // history icon bg

// ─── Surah Colors ─────────────────────────────────────────────
Color surahColor(int n) {
  const colors = [
    Color(0xFFC8A96E),
    Color(0xFF3AAFA9),
    Color(0xFF4CAF7D),
    Color(0xFF9B59B6),
    Color(0xFFE67E22),
    Color(0xFF2980B9),
    Color(0xFFE74C3C),
    Color(0xFF16A085),
    Color(0xFFD35400),
  ];
  return colors[n % colors.length];
}

// ─── Quran Page → Juz Lookup ──────────────────────────────────
// Approximate Juz boundaries (page numbers, 1-indexed, Medina mushaf)
const _juzPageStarts = [
  1,
  22,
  42,
  62,
  82,
  102,
  121,
  142,
  162,
  182,
  201,
  222,
  242,
  262,
  282,
  302,
  322,
  342,
  362,
  382,
  402,
  422,
  442,
  462,
  482,
  502,
  522,
  542,
  562,
  582,
];

int pageToJuz(int page) {
  for (int i = _juzPageStarts.length - 1; i >= 0; i--) {
    if (page >= _juzPageStarts[i]) return i + 1;
  }
  return 1;
}

int juzToPage(int juz) {
  final idx = (juz - 1).clamp(0, _juzPageStarts.length - 1);
  return _juzPageStarts[idx];
}

// ─── Juz Start (Surah, Ayah) ──────────────────────────────────
const juzStarts = [
  (1, 1),
  (2, 142),
  (2, 253),
  (3, 93),
  (4, 24),
  (4, 148),
  (5, 83),
  (6, 111),
  (7, 88),
  (8, 41),
  (9, 93),
  (11, 6),
  (12, 53),
  (15, 1),
  (17, 1),
  (18, 75),
  (21, 1),
  (23, 1),
  (25, 21),
  (27, 56),
  (29, 45),
  (33, 31),
  (36, 28),
  (39, 32),
  (41, 47),
  (46, 1),
  (51, 31),
  (58, 1),
  (67, 1),
  (78, 1),
];

// ─── Arabic Numerals ──────────────────────────────────────────
String ar(int n) {
  const d = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
  return n.toString().split('').map((c) => d[int.parse(c)]).join();
}

// ─── Hijri Date Helper ────────────────────────────────────────
/// Today's Hijri date as "<weekday> <day> <month> <year>", using the same
/// `HijriCalendar` conversion (and active `HijriCalendar.language`) as the
/// rest of the app, rather than a hand-rolled ±1-day approximation.
String hijriDateString() {
  final h = HijriCalendar.now();
  final isArabic = HijriCalendar.language == 'ar';
  final dayNum = isArabic ? ar(h.hDay) : h.hDay.toString();
  final year = isArabic ? ar(h.hYear) : h.hYear.toString();
  return '${h.getDayName()} $dayNum ${h.getLongMonthName()} $year';
}

/// Localized display name for a surah, using the `nameEn`/`nameAr` already
/// carried by [kSurahData] — no translation needed, just picking the field
/// that matches the active locale. Falls back to a generic "Quran"
/// placeholder if [surahNum] is out of range.
String localizedSurahName(BuildContext context, int surahNum) {
  if (surahNum < 1 || surahNum > kSurahData.length) {
    return AppLocalizations.of(context)!.quranReaderFallbackName;
  }
  final meta = kSurahData[surahNum - 1];
  final isArabic = Localizations.localeOf(context).languageCode == 'ar';
  return isArabic ? meta.nameAr : meta.nameEn;
}

/// Renders [n] using Arabic-Indic digits when the active locale is Arabic,
/// or plain Latin digits otherwise — for interpolating numbers into ARB
/// messages that were previously built with a hardcoded [ar] call.
String localizedNumeral(BuildContext context, int n) =>
    Localizations.localeOf(context).languageCode == 'ar' ? ar(n) : n.toString();

/// "<month> <year>" in the active Hijri calendar language, e.g. for
/// prefilling a default label like "Khatma <month> <year>". Callers should
/// not derive this by splitting [hijriDateString] on spaces — several
/// Hijri month names (e.g. "ربيع الأول") contain a space themselves.
String hijriMonthYearLabel() {
  final h = HijriCalendar.now();
  final year = HijriCalendar.language == 'ar'
      ? ar(h.hYear)
      : h.hYear.toString();
  return '${h.getLongMonthName()} $year';
}

// ─── Page Routes ──────────────────────────────────────────────
Route slideRoute(Widget w) => PageRouteBuilder(
  pageBuilder: (_, a, _) => w,
  transitionsBuilder: (_, a, _, child) => SlideTransition(
    position: Tween<Offset>(
      begin: const Offset(0, 0.04),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: a, curve: Curves.easeOutCubic)),
    child: FadeTransition(opacity: a, child: child),
  ),
  transitionDuration: const Duration(milliseconds: 380),
);

Route fadeRoute(Widget w) => PageRouteBuilder(
  pageBuilder: (_, a, _) => w,
  transitionsBuilder: (_, a, _, child) =>
      FadeTransition(opacity: a, child: child),
  transitionDuration: const Duration(milliseconds: 300),
);

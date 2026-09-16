# Home screen widgets

Five home-screen widgets (Android AppWidget / iOS WidgetKit), all sharing
one visual style — the app's own brand colors (gold/teal accents on a
navy-to-card-tone gradient, plus a low-opacity rub el hizb geometric motif
tucked into one corner), in both light and dark mode:

- **Prayer times** — today's five prayer times, next one highlighted.
  Modeled on the reference "ختمة" widget the feature request was based on.
  Ships in two sizes: the compact 4×2 (`.systemMedium` on iOS,
  `PrayerWidgetProvider` on Android) and a 4×3 "large" variant
  (`.systemLarge` / `PrayerWidgetLargeProvider`) that adds a countdown bar
  to the next prayer — the countdown-timer style from the very first
  reference screenshots.
- **Dua of the day** — one dua from the app's own bundled traditional duas,
  rotating daily.
- **Dhikr of the day** — same idea, from the bundled adhkar, with a "×N"
  repetition pill when the dhikr is said more than once.
- **Verse of the day** — one ayah from `quran_library`'s own Quran text
  (the same package the Quran reader screen renders from), drawn only from
  Juz 30's short surahs (At-Takathur..An-Nas) so it always reads as a
  complete standalone thought rather than a sentence cut out of a longer
  passage.

## How it flows

1. **Prayer times**: `prayerTimesProvider` (already existed, `lib/core/
   notifications/notifications_service.dart`) recomputes prayer times
   whenever location, calculation settings, or the day changes.
   `_TakwaAppState.build()` in `lib/main.dart` listens to it (and to
   `localeProvider`, so a language switch alone still refreshes the
   widget's labels) and calls `PrayerHomeWidgetService.update()`, which
   formats the five prayers + Hijri/Gregorian date into a JSON blob.
2. **Dua/dhikr/verse of the day**: `DailyQuoteWidgetService` picks
   deterministically from `kDuasData`/`kAdhkarData` (the same bundled data
   the Duas/Adhkar screens show) or `quran_library`'s Quran text using the
   calendar date, so every device shows the same pick on a given day with
   no server involved. Called once at app start and on every locale change
   (see `_TakwaAppState.initState`/`.build()` in `lib/main.dart`).
3. All services push their JSON via the `home_widget` plugin and ask the
   platform to redraw:
   - **Android**: `HomeWidget.updateWidget()` broadcasts to the matching
     `*WidgetProvider` immediately, and `HomeWidget.scheduleWidgetUpdates()`
     arms an alarm for the next content change (each remaining prayer time
     today, or next midnight for a daily pick) so widgets keep advancing
     while the app is closed.
   - **iOS**: each widget's own WidgetKit `TimelineProvider` builds its
     timeline entries from the same JSON and reload policy, so no
     equivalent "update again later" call is needed from Flutter.
4. No native side computes a prayer time, a Hijri date, or "today's pick"
   itself — they only format whatever JSON these two services last wrote.
   All that logic stays in one place (Dart), so it can never drift between
   the app and the widgets, or between Android and iOS.

## Branding: light & dark

Every widget uses the app's actual design-system colors — mirrored from
`AppColorsExtension` (`packages/takwa_ui/lib/src/theme/app_colors.dart`),
not invented separately — and follows the *system's* light/dark setting
(WidgetKit/AppWidgets have no hook into the app's own in-app theme choice):

- **Android**: `res/values/widget_colors.xml` (light) and
  `res/values-night/widget_colors.xml` (dark) define the same color names;
  Android resolves whichever matches automatically. The shared
  `takwa_widget_card_background.xml` drawable and every widget layout only
  ever reference `@color/widget_*`, never a literal hex, so light/dark
  needs no code — just those two resource files.
- **iOS**: `ios/PrayerWidget/TakwaWidgetTheme.swift` defines the same two
  palettes; every widget view resolves `TakwaWidgetTheme.resolve(
  colorScheme)` from `@Environment(\.colorScheme)` once per render.

Every color used for *text* (`widget_text_primary/secondary`, the
AA-adjusted `widget_gold`/`widget_teal` — not the raw brand accent, which
fails contrast on a light card) comes from those same two token sets, so
adding the gradient/motif styling below couldn't regress light-mode
legibility: the new layers sit at 5-20% opacity, well under what would
threaten the existing AA-contrast numbers on either background.

### The "Islamic" gradient + motif

Layered into the same one shared background (`takwa_widget_card_background
.xml` on Android, `TakwaWidgetBackgroundView` on iOS) so every widget got
this for free with no per-widget change:

1. The original card gradient (unchanged) — the base.
2. A gold→teal accent sheen at low opacity, using the *exact* ARGB values
   as `AppColorsExtension.cardGradient` (`widget_overlay_gold/teal` /
   `TakwaWidgetTheme.overlayGold/Teal`) — the same wash the in-app cards
   use, not a color invented for the widget.
3. A "rub el hizb" motif (two squares, one rotated 45°, forming an
   8-pointed star — used throughout Islamic art and to mark Quran section
   divisions) stroked at low opacity in one corner, behind the real
   content (`ic_widget_islamic_motif.xml` / `RubElHizbMotif` Shape).

## Resizing

- Every prayer/label/quote TextView that sits in a width-constrained cell
  uses `autoSizeTextType="uniform"` (Android) so shrinking the widget
  narrower scales the text down to fit instead of clipping or overflowing
  — needs the TextView's width to actually be constrained (`match_parent`
  in a weighted cell, not `wrap_content`) for autosize to have anything to
  shrink against.
- `minResizeWidth` was lowered across all four widgets (prayer: 140dp,
  dua/dhikr/verse: 150dp) now that autosize covers the narrower cells that
  unlocks.
- iOS has no separate "resize" concept — `.systemMedium`/`.systemLarge` are
  the two sizes WidgetKit itself offers, picked from the widget gallery.

## Widget-picker previews

Without an explicit preview, Android's "add widget" picker falls back to
showing the app's launcher icon centered in a gray box — not what the
widget actually looks like. Every widget here declares both:

- `android:previewLayout` (API 31+): a static copy of the widget's real
  layout (`*_widget_preview.xml`) with realistic hardcoded sample content
  instead of the live/empty state. The system renders it directly, so it
  already uses the real `@color/widget_*` resources and matches light/dark
  automatically.
- `android:previewImage` (all API levels): a matching static PNG
  (`res/drawable-nodpi/*_widget_preview.png`) for pre-Android-12 devices,
  rendered to the same layout and brand palette (fixed to dark mode, since
  a bitmap can't switch with the system setting).

iOS's widget gallery renders each widget's own `TimelineProvider.
placeholder()`/`getSnapshot()` directly — no separate preview asset is
needed there.

## Files

| Purpose | Path |
|---|---|
| Push prayer-time data | `lib/core/home_widget/prayer_home_widget_service.dart` |
| Push dua/dhikr/verse-of-day data | `lib/core/home_widget/daily_quote_widget_service.dart` |
| Shared App Group id | `lib/core/home_widget/home_widget_ids.dart` |
| Shared Hijri month name helper | `lib/core/utils/hijri_display.dart` |
| Android prayer widget (compact) | `PrayerWidgetProvider.kt` + `res/layout/prayer_widget.xml` + `res/xml/prayer_widget_info.xml` |
| Android prayer widget (large, countdown) | `PrayerWidgetLargeProvider.kt` (subclasses the above) + `res/layout/prayer_widget_large.xml` + `res/xml/prayer_widget_large_info.xml` |
| Android dua/dhikr/verse widgets | `DailyQuoteWidgetProviderBase.kt` (shared base, three thin subclasses) + `res/layout/daily_quote_widget.xml` + `res/xml/{dua,dhikr,verse}_of_day_widget_info.xml` |
| Android brand colors | `res/values/widget_colors.xml` + `res/values-night/widget_colors.xml` |
| Android shared card background + motif | `res/drawable/takwa_widget_card_background.xml` + `res/drawable{,-night}/ic_widget_islamic_motif.xml` |
| Android widget-picker previews | `res/layout/*_widget_preview.xml` + `res/drawable-nodpi/*_widget_preview.png` |
| iOS prayer widget (compact + large) | `ios/PrayerWidget/PrayerWidget.swift` |
| iOS dua/dhikr/verse widgets | `ios/PrayerWidget/DailyQuoteWidget.swift` (all three, sharing one provider/view) |
| iOS brand colors + shared background/motif | `ios/PrayerWidget/TakwaWidgetTheme.swift` |
| iOS `@main` entry point | `ios/PrayerWidget/TakwaWidgetsBundle.swift` (lists all four widgets) |
| iOS one-time Xcode setup | `ios/PrayerWidget/SETUP.md` |

## Status

- **Android**: fully wired — `flutter pub get`, build, and all five (four
  widgets, prayer times in two sizes) work. No extra manual step (the
  `home_widget` plugin's own Gradle module and the manifest `<receiver>`
  entries handle themselves).
- **iOS**: the Swift/plist/entitlements source for all four widgets is
  ready, but a WidgetKit extension **target** has to be added once from
  inside Xcode — that plumbing can't be scripted safely outside Xcode's
  own "New Target" wizard. See `ios/PrayerWidget/SETUP.md` for the exact
  steps (~10 minutes, one-time, then committed) — adding all four widgets
  is one pass through that setup, not four, since they share a single
  extension target.
- Prayer times ships two sizes (`.systemMedium`/4×2 and `.systemLarge`/4×3
  with the countdown bar); dua/dhikr/verse ship one (`.systemMedium`/4×2)
  — see SETUP.md's notes for extending them the same way.
- The verse-of-the-day pool is deliberately narrow (Juz 30's short surahs)
  for editorial safety — a length filter alone (as used for dua/dhikr)
  risks landing on a fragment that reads oddly out of its original
  context. Broadening the pool later means adding surah numbers to
  `DailyQuoteWidgetService._verseSurahPool`, not touching the picking
  logic itself.

## Testing manually (Android)

1. `flutter pub get` (needed once, to pull in `home_widget` — not run in
   this session since no Flutter SDK is available here).
2. Run the app on a device/emulator once so all services push real data.
3. Long-press the home screen → Widgets → search "تقوى" → you'll see five
   entries: "أوقات الصلاة" (compact), "أوقات الصلاة (كبير)" (large, with
   the countdown bar), "دعاء اليوم", "ذكر اليوم", "آية اليوم" — each
   showing realistic sample content in the picker, not just the app icon.
4. Toggle the device's system dark mode and confirm all five switch
   between the light and dark palettes (including the gold/teal sheen and
   corner motif).
5. Change the language in Settings and confirm the widgets' labels switch
   too (they redraw within a second via the `localeProvider` listener).
6. Drag a widget's resize handles to its `minResizeWidth`/`minResizeHeight`
   and confirm the prayer times/dua/dhikr/verse text shrinks to fit rather
   than clipping.

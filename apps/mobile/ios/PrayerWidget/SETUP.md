# Wiring up the iOS widgets

This folder has the Swift/plist/entitlements source for four widgets —
prayer times, dua of the day, dhikr of the day, verse of the day — but a WidgetKit
**extension target** can only be added to the Xcode project from inside
Xcode — its plumbing (product reference, build phases, embed step, scheme)
isn't something safe to hand-edit into `project.pbxproj` from outside
Xcode, and this repo is developed from a Linux machine with no Xcode to
build/verify a hand edit against. You'll need a Mac with Xcode for this
regardless, since that's also required to build/run the iOS app at all —
so doing these steps once in Xcode's UI isn't extra work, just the normal
place to do it.

All four widgets live in **one** extension target/scheme, added once —
adding each new one after the first is just dragging in more files, no
second target needed (a WidgetKit extension can host any number of
`Widget`s via one `WidgetBundle`, see `TakwaWidgetsBundle.swift`).

Budget about 10 minutes. All of it is done once and then committed.

## 1. Add the Widget Extension target

1. Open `ios/Runner.xcworkspace` in Xcode (not `.xcodeproj`).
2. **File ▸ New ▸ Target…** ▸ iOS ▸ **Widget Extension**.
3. Product Name: `PrayerWidget` (this is the target/extension's name —
   it hosts all four widgets, the name doesn't need to change). Uncheck
   "Include Configuration Intent" (none of these widgets are
   user-configurable). Team/bundle ID: same team as Runner; bundle id
   `com.takwa.PrayerWidget` (Runner's id + `.PrayerWidget`).
4. When Xcode asks to "Activate" the new scheme, choose **Activate**.
5. Xcode generates a `PrayerWidget/` group with its own
   `PrayerWidget.swift`, `Info.plist`, and (if you left configuration
   intents off) possibly an `Assets.xcassets`. **Delete the generated
   `PrayerWidget.swift` and `Info.plist`** (Move to Trash) and instead
   **drag in every file already in this folder**: `PrayerWidget.swift`,
   `DailyQuoteWidget.swift`, `TakwaWidgetTheme.swift`,
   `TakwaWidgetsBundle.swift`, `Info.plist`, `PrayerWidget.entitlements` —
   check "Copy items if needed" and add them to the `PrayerWidget` target
   only (not Runner). Don't drag in `SETUP.md`.
6. In the new target's **Build Settings**, set **Info.plist File** to
   `PrayerWidget/Info.plist` and **Code Signing Entitlements** to
   `PrayerWidget/PrayerWidget.entitlements` if Xcode didn't already point
   them there.
7. In the new target's **Build Settings**, set **iOS Deployment Target**
   to **17.0** (the widgets use `containerBackground(for:.widget)`,
   iOS 17+ only — Runner's own deployment target stays 13.0, so the app
   still installs on older iOS, it just won't offer these widgets there).

## 2. Add the shared App Group

Both targets need the *same* App Group so the app can write prayer times/
dua/dhikr data where the widgets can read it.

1. Select the **Runner** target ▸ **Signing & Capabilities** ▸
   **+ Capability** ▸ **App Groups**. Click **+** under the App Groups
   list and add `group.com.takwa.PrayerWidget`. Xcode creates
   `Runner/Runner.entitlements` for you and wires it into the build
   settings automatically.
2. Select the **PrayerWidget** target ▸ **Signing & Capabilities** ▸
   **+ Capability** ▸ **App Groups** ▸ check the same
   `group.com.takwa.PrayerWidget` group (Xcode will offer it once step 1
   is done since it already exists in your Apple Developer account/team).
   This should point at the `PrayerWidget.entitlements` already in this
   folder — if Xcode instead generated a second entitlements file, delete
   the generated one and re-point **Code Signing Entitlements** at
   `PrayerWidget/PrayerWidget.entitlements`.
3. If you ever rename the group, update it in **five** places: both
   entitlements files above, `PrayerProvider.appGroupId` and
   `DailyQuoteProvider.appGroupId` in the two Swift files, and
   `HomeWidgetIds.iOSAppGroupId` in
   `lib/core/home_widget/home_widget_ids.dart` (both
   `PrayerHomeWidgetService` and `DailyQuoteWidgetService` read that one
   constant, so it's the only Dart-side place).

## 3. Build

1. Select the **Runner** scheme (not PrayerWidget) ▸ your device/simulator
   ▸ **Run**.
2. Open the app once so `PrayerHomeWidgetService` and
   `DailyQuoteWidgetService` write real data into the shared App Group
   (both run on every app start — see `lib/main.dart`'s
   `_TakwaAppState.initState`).
3. Long-press the Home Screen ▸ **+** ▸ search "تقوى" ▸ you'll see four
   widgets to add: **أوقات الصلاة**, **دعاء اليوم**, **ذكر اليوم**,
   **آية اليوم**.

If a widget shows its "افتح تطبيق تقوى..." placeholder instead of real
content, the App Group is misconfigured (a mismatched group id somewhere
in the "five places" list above) or the app hasn't been opened yet on this
device/simulator.

## Notes

- Each widget's `kind` string (`"PrayerWidget"` / `"DuaOfDayWidget"` /
  `"DhikrOfDayWidget"` / `"VerseOfDayWidget"`) must keep matching the
  corresponding `iOS*WidgetName` constant on the Dart side — that's the
  name `HomeWidget.updateWidget(iOSName: ...)` looks up.
- `TakwaWidgetTheme.swift` holds the brand light/dark colors shared by all
  four widgets (mirrors `AppColorsExtension` in
  `packages/takwa_ui/lib/src/theme/app_colors.dart`) — change the palette
  there once, not per widget file. It also defines
  `TakwaWidgetBackgroundView` (the brand gradient + gold/teal accent sheen +
  rub el hizb corner motif every widget's `containerBackground` uses) — same
  reasoning, change the background once, not per widget.
- Dua/dhikr/verse ship one size (`.systemMedium`, ~4×2 cells). Prayer times
  additionally supports `.systemLarge` (~4×3): the same 5-prayer row plus a
  countdown bar to the next prayer (`PrayerContentView`'s `showCountdown`,
  gated on `\.widgetFamily`) — the countdown-timer variant from the
  original reference screenshots. Giving the other three the same
  `.systemLarge` treatment later just means branching their content view
  the same way; no new provider/kind needed since WidgetKit — unlike
  Android's AppWidgetProviderInfo — lets one widget declare several sizes.
- No Podfile changes are needed — the extension only uses WidgetKit/SwiftUI
  and `UserDefaults`, no Flutter engine or CocoaPods dependency.

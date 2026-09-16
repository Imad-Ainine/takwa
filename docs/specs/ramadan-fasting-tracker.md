# Spec: Ramadan Fasting Tracker

## Status
Not implemented. Proposed.

## Context

The data layer for this feature already exists and is unused by any screen:

- `RamadanProgress` table (`apps/mobile/lib/core/database/app_database.dart:188`) has
  `year`, `dayNumber`, `recordId` (FK to `DailyRecords`), `duaOfDay`, `iHyaLayl`
  (قيام ليلة من ليالي رمضان), and `totalPoints`, with a unique key on
  `(year, dayNumber)`.
- `RamadanProgressDao` (`apps/mobile/lib/core/database/daos.dart:1720`) already exposes
  `getProgress(year, day)` and `updateProgress(...)`, and is wired into
  `SyncManager` for push/pull to the Supabase `daily_records`-adjacent flow.
- `DailyRecords.fastingType` (`FastingType` enum: `none`/`fard`/`nafl`/`makruh`) already
  records whether a given day was fasted, and is set today only from the generic daily
  checklist (`apps/mobile/lib/features/checklist`).
- `StatsPeriod.ramadan` in `apps/mobile/lib/features/statistics/statistics_screen.dart:22`
  computes the Hijri-to-Gregorian Ramadan date range and renders a bare
  "day X of 30" progress bar (`_RamadanProgress` at line 362) — it never reads
  `RamadanProgress.duaOfDay` / `iHyaLayl`, and there's no way to log those fields.
- `apps/mobile/lib/core/theme/ramadan_theme.dart` already re-themes the app during Ramadan.

So today: the app *detects* Ramadan and *reskins* itself, and the schema is ready to hold
per-day Ramadan data, but there is no dedicated screen for a user to log a fasting day,
see days remaining, see Suhoor/Iftar countdowns, or read the daily dua/reflection. This
spec covers building that screen and the small amount of glue it needs.

## Goals

1. A dedicated "Ramadan" home surface, auto-surfaced (e.g. from `home_screen.dart` and/or
   the drawer in `apps/mobile/lib/app/animated_drawer.dart`) only while
   `HijriCalendar.now().hMonth == 9`, matching the existing `isRamadan` check pattern
   already used in `statistics_screen.dart:296`.
2. Suhoor end / Iftar countdown, reusing the existing prayer-times pipeline
   (`features/prayer/data`, `PrayerTimesCache`) — Suhoor end = Fajr time, Iftar = Maghrib
   time for the user's cached location. No new prayer-time source.
3. Per-day fasting log: fasted (fard/nafl/qada — reuse `FastingType`), missed with reason
   (`makruh`/excuse), Qiyam al-layl done (`iHyaLayl`), and the day's dua/reflection text
   (`duaOfDay` — for v1 this can be a static curated list of 30 duas bundled with the app,
   indexed by `dayNumber`, rather than user-authored).
4. A 30-day Ramadan progress strip (day 1..30, filled/empty/missed) on the tracker screen,
   replacing/extending today's single progress bar.
5. End-of-Ramadan summary reusing `AchievementCategory.special` (there is already a
   `ramadan_knight` achievement in
   `apps/mobile/lib/features/achievements/domain/models/achievement_definition.dart:146`)
   — no new achievement infra needed, just a grant condition (e.g. fasted all 30 days).

## Non-goals

- Fiqh/madhab-specific fasting rulings or a fatwa engine.
- Automatic Ramadan-start detection via moon sighting — keep using the existing
  Hijri-calendar-package computation already used for `StatsPeriod.ramadan`.
- Multi-user/family fasting visibility — see
  [family-community-features.md](family-community-features.md) if that's wanted later;
  this spec is single-user, local-first, same as the rest of the app.
- Zakat al-Fitr calculation — see [zakat-calculator.md](zakat-calculator.md).

## Functional requirements (EARS)

- R1: WHEN the current Hijri month is Ramadan (month 9), THE SYSTEM SHALL show a Ramadan
  tracker entry point on the home screen and drawer.
- R2: WHEN the user opens the Ramadan tracker on a given Gregorian day that falls within
  Ramadan, THE SYSTEM SHALL display that day's Hijri day number (1-30), the Suhoor-end
  (Fajr) and Iftar (Maghrib) countdowns sourced from `PrayerTimesCache`, and that day's
  curated dua/reflection.
- R3: WHEN the user marks a day as fasted (fard/nafl) or not fasted (with an excuse type),
  THE SYSTEM SHALL persist it via `RamadanProgressDao.updateProgress` and mirror
  `fastingType` onto that date's `DailyRecords` row so existing points/statistics logic
  keeps working unchanged.
- R4: WHEN the user toggles "Qiyam al-layl performed" for a day, THE SYSTEM SHALL persist
  `iHyaLayl` for that `(year, dayNumber)`.
- R5: WHILE viewing the tracker, THE SYSTEM SHALL render a 30-cell strip reflecting each
  day's logged status (fasted / missed / not yet reached / today).
- R6: WHEN all 30 days of the current Ramadan are logged as fasted, THE SYSTEM SHALL grant
  the existing `ramadan_knight` achievement if not already granted.
- R7: IF the user has not granted location/prayer-time permissions, THEN THE SYSTEM SHALL
  fall back to the same "no location" empty state already used on the Prayer screen,
  rather than a distinct error UI.

## Data model changes

None required for the core loop — `RamadanProgress` already has the needed columns. Only
addition: a static bundled asset (e.g. `assets/ramadan_duas.json`, 30 entries) for the
curated daily dua/reflection, loaded the same way `books_data.dart` or `duas` data is
loaded today.

## Open questions

- Should "missed with excuse" (travel, illness) count differently in the 30-day strip and
  in achievement eligibility than an unexcused missed day? Needs a product decision before
  implementation; `FastingType.makruh` exists but its exact semantics for this UI aren't
  defined yet.
- Should the tracker be reachable year-round (read-only, past Ramadans) via
  `RamadanProgressDao.getProgress(year, day)` for previous years, or only during the
  active Ramadan? Affects whether `khatma_history_screen.dart`-style history list is
  needed.

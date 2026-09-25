# Spec: Islamic Occasions & Voluntary Fasting Reminders

## Status
Implemented. `lib/features/occasions/` — an `IslamicOccasionKind` enum of nine fixed
Hijri-date occasions (Ashura, Isra' & Mi'raj, Ramadan start, Laylat al-Qadr, Eid al-Fitr,
Mawlid, Eid al-Adha, Islamic New Year, 'Arafah) resolved to their next Gregorian occurrence
with a days-until countdown, plus this month's three White Days (Ayyam al-Beed) as a
separate monthly list. `islamic_occasions_screen.dart` is reachable from the home feature
grid; tapping a tile opens the existing reminder sheet pre-filled for that occasion (R3 —
`Semantics(button: true)` + `GestureDetector`, with the bell `IconButton` kept for
keyboard/focus access). No new table: reminders go through the existing `Reminders` feature.

## Context

The app already computes the Hijri date reliably (`hijri` package, used throughout
`statistics_screen.dart`, `home_screen.dart`, the new Ramadan tracker) and already has a
`Reminders` feature for user-defined daily alerts
(`apps/mobile/lib/features/reminders`). There is no screen or data showing recurring
Islamic occasions (White Days / Ayyam al-Beed fasting on the 13th-15th of every Hijri
month, Ashura, Mawlid, Isra' wal Mi'raj) or how many days away the next one is — a common
feature in comparable apps, and a natural fit given the Hijri-date infrastructure already
in place.

## Goals

1. A read-only "Islamic Occasions" screen: a short list of the year's notable Hijri dates
   (Ashura, Ramadan start, Eid al-Fitr, Eid al-Adha, Mawlid, Isra' wal Mi'raj) with each
   one's countdown in days, plus this month's three White Days dates and countdown to the
   next one.
2. A one-tap shortcut from an occasion to create a matching entry in the existing
   `Reminders` feature, rather than building a second, parallel notification-scheduling
   system.

## Non-goals

- A full notification-scheduling engine for these occasions (recurring yearly/monthly
  push notifications tied to Hijri dates) — v1 is informational plus a manual "add
  reminder" shortcut into the existing daily-reminder system, which schedules a plain
  recurring time-of-day alert, not a date-aware one. A real date-aware scheduler is a
  larger change to `NotificationsService`/`NotificationsManager` and is a reasonable
  fast-follow, not v1.
- Fiqh differences on which occasions are "recommended" to mark (e.g. some scholars
  discourage marking Mawlid) — the list here is informational/cultural, not a religious
  ruling; no in-app disclaimer beyond noting it's for awareness, not obligation.
- Moon-sighting-accurate occasion dates — same tabular Hijri calendar the rest of the app
  already relies on (`HijriCalendar`), with the same margin of error other Hijri-date UI
  in this app already accepts.

## Functional requirements (EARS)

- R1: WHEN the user opens the Islamic Occasions screen, THE SYSTEM SHALL list each
  configured occasion with its Gregorian date for the current Hijri year and the number
  of days until it (or "today" if it is today).
- R2: WHEN the user opens the Islamic Occasions screen, THE SYSTEM SHALL show the current
  Hijri month's three White Days dates and highlight whichever is soonest.
- R3: WHEN the user taps an occasion, THE SYSTEM SHALL offer to create a matching entry
  in the existing Reminders list pre-filled with that occasion's name.

## Data model

None — occasions are a small bundled static list (Hijri month/day pairs), computed
against the current Hijri year the same way the Ramadan tracker computes Ramadan's range.
No new table.

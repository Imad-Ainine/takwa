# Spec: Qada' (Missed Prayers) Tracker

## Status
Not implemented. Proposed.

## Context

`PrayerStatus.qadaa` (`packages/takwa_core/lib/src/enums.dart:6`) already exists and is
selectable per-prayer in the daily checklist
(`apps/mobile/lib/features/checklist/screens/checklist_screen.dart:834`) — but it only
means "I made this specific prayer up later on the same day." There is no concept
anywhere in the app of a standing backlog: prayers missed before a user started
practicing regularly (or missed years ago) that they intend to make up over time, which
is what "Qada'" commonly refers to in everyday usage and what other Islamic apps
typically call a "missed prayers counter." This is a distinct, unimplemented feature.

## Goals

1. A per-prayer (Fajr/Dhuhr/Asr/Maghrib/Isha) counter of how many Qada prayers are owed.
2. The user can set/adjust the owed count directly (they know their own history; the app
   has no way to infer it).
3. A "mark one as made up" action per prayer that decrements the owed count and
   increments a lifetime "completed" counter — for encouragement, not correctness (no
   attempt to reconcile this against `daily_records`, which tracks a different concept).

## Non-goals

- Automatically inferring a Qada backlog from prayer history (the app didn't exist for
  most of a user's life; there's nothing to infer from).
- Linking this to the daily checklist's own `PrayerStatus.qadaa` value — that stays a
  same-day "performed late" marker, unrelated to this lifetime counter.
- Streak/points integration — this is a personal utility, not a scored Ibadah.

## Functional requirements (EARS)

- R1: WHEN the user opens the Qada tracker, THE SYSTEM SHALL show the current owed count
  for each of the five daily prayers.
- R2: WHEN the user sets an owed count for a prayer, THE SYSTEM SHALL persist it
  immediately, replacing the previous value.
- R3: WHEN the user marks one prayer as made up, THE SYSTEM SHALL decrement that prayer's
  owed count by 1 (never below 0) and increment its lifetime completed count by 1.
- R4: WHILE a prayer's owed count is 0, THE SYSTEM SHALL disable further decrements for
  that prayer (nothing to mark as made up).

## Data model

New local-only Drift table `QadaCounters`: `prayerName` (primary key, one of the five
prayer names), `owedCount`, `completedCount`, `updatedAt`. No Supabase sync in v1 — kept
local like most personal-utility state in this app; add a sync path later only if users
ask for cross-device continuity here specifically.

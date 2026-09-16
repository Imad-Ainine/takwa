# Spec: Sadaqah (Charity) Tracker

## Status
Not implemented. Proposed.

## Context

`DailyRecords.sadaqah` (bool) and `DailyRecords.sadaqahAmount` (real) already exist in
the schema (`apps/mobile/lib/core/database/app_database.dart:65`), and sync to Supabase
(`daily_records.sadaqah_amount` in `apps/mobile/docs/schema.sql:185`). In practice, only
`sadaqah` (a plain yes/no toggle) is ever set from the UI — via
`DailyRecordDao.toggleSadaqah` in `checklist_screen.dart:1030`.
`sadaqahAmount` is written only when *pulling* a remote row
(`daos.dart:517`); nothing in the app ever lets a user enter an amount, and nothing
displays a running total or history. The column has existed since the schema's design but
was never wired to any input or view.

## Goals

1. Let the user optionally log an amount (in whatever currency/unit they choose, same
   free-text-currency approach as the Zakat calculator) alongside the existing daily
   Sadaqah toggle.
2. A dedicated screen showing total given this week/month/all-time and a simple
   chronological history list — reusing the existing `DailyRecords` rows rather than a
   new table, since the data already lives there.

## Non-goals

- Multi-currency conversion or totals across mixed currencies — same simplification the
  Zakat calculator makes (a single free-text currency label, no conversion).
- Recipient tracking (who/where the charity went) — out of scope for v1.
- Recurring/pledged giving reminders — could reuse the existing `Reminders` feature later
  if requested; not built here.

## Functional requirements (EARS)

- R1: WHEN the user toggles Sadaqah on for today in the checklist, THE SYSTEM SHALL
  reveal an optional amount field (already-existing `sadaqahAmount` column) instead of
  only recording the boolean.
- R2: WHEN the user opens the Sadaqah tracker screen, THE SYSTEM SHALL show total amount
  given this week, this month, and all-time, computed from existing `DailyRecords` rows
  where `sadaqah` is true.
- R3: WHEN the user opens the Sadaqah tracker screen, THE SYSTEM SHALL list past
  Sadaqah-logged days in reverse chronological order with their amount (if any).
- R4: IF a Sadaqah-logged day has no amount entered, THEN THE SYSTEM SHALL show it in the
  history as logged-without-amount rather than as 0 (a real 0 and "didn't say" are not the
  same fact).

## Data model

None — reuses `DailyRecords.sadaqah` / `sadaqahAmount`, already present and already
syncing. This is a UI-only gap being closed, not a schema gap.

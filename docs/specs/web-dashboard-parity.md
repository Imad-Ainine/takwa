# Spec: Web Dashboard Parity

## Status
Not implemented. Proposed.

## Context

`apps/web/src/app/[locale]/dashboard/page.tsx` today is explicitly a placeholder: it
renders a welcome card with a `t('placeholderNote')` string and an APK early-access
download card (`getLatestRelease()` from `apps/web/src/lib/releases.ts`). It shows zero
of the user's actual worship data. Meanwhile the mobile app already syncs a rich dataset
to the same Supabase project the web app authenticates against
(`apps/web/src/lib/supabase/{client,server}.ts`, same project as
`apps/mobile/lib/core/supabase/supabase_service.dart`):

- `profiles`: `total_points`, `current_streak`, `highest_streak`, `quran_pages`
  (`apps/mobile/docs/schema.sql:218`).
- `daily_records`: per-day prayer/Quran/adhkar/fasting/sadaqah log
  (`apps/mobile/docs/schema.sql:160`).
- `achievements`: earned badges (`apps/mobile/docs/schema.sql:1`).
- `book_reading_progress`, `custom_ibadah`/`custom_ibadah_log`.

Auth is already shared (Supabase `auth.getUser()` in `page.tsx:22`); the gap is purely
that the dashboard never reads any of these tables. This spec is a read-only web view
onto data the mobile app already writes — no new mobile-side sync work.

Web app supports `ar`/`en`/`fr` locales (`apps/web/messages/*.json`) — one more (`fr`)
than the mobile app's `ar`/`en` (`apps/mobile/lib/core/providers/locale_provider.dart:9`).
Any user-facing strings this spec adds need all three web locale files updated.

## Goals

1. Replace `placeholderNote` with a real summary: current streak, total points, and
   today's checklist completion (prayers done / Quran read / adhkar done), read directly
   from `profiles` and today's `daily_records` row.
2. A simple history view: a calendar or list of recent days from `daily_records`,
   read-only (editing stays a mobile-only capability for v1 — see Non-goals).
3. An achievements list mirroring the mobile `achievements_screen.dart` — same data
   (`achievements` table), simpler layout (list/grid, no animation).
4. Keep the existing APK download card as-is; it's unrelated to this spec and already
   works.

## Non-goals

- Write access from the web (logging a prayer, marking adhkar done, etc.) — v1 is
  read-only. Introducing web-side writes means reconciling with `SyncManager`'s
  conflict-handling logic (`apps/mobile/lib/core/supabase/sync_manager.dart`), which is
  a materially bigger change than a dashboard view and should be its own spec if wanted
  later.
- Real-time updates (e.g. live-refreshing while the phone logs something) — a simple
  server-rendered page re-fetched on load is enough for v1, matching the current
  dashboard's `async` server component pattern.
- Any feature from the other three specs in this batch (Ramadan tracker, Zakat
  calculator, family circles) — those are mobile-first; whether they ever need a web
  surface is out of scope here.
- Account management beyond the existing sign-out (password change, deletion) — separate
  concern from data parity.

## Functional requirements (EARS)

- R1: WHEN an authenticated user loads the dashboard, THE SYSTEM SHALL fetch that user's
  `profiles` row and display `current_streak`, `total_points`, and `highest_streak`.
- R2: WHEN an authenticated user loads the dashboard, THE SYSTEM SHALL fetch today's
  `daily_records` row (if any) for that user and summarize prayer/Quran/adhkar/fasting
  completion for today.
- R3: IF no `daily_records` row exists yet for today, THEN THE SYSTEM SHALL show an empty
  state ("no data logged today yet") rather than an error or zeroed-out fields that look
  like real data.
- R4: WHEN an authenticated user requests recent history, THE SYSTEM SHALL fetch and list
  the last N (e.g. 14) `daily_records` rows ordered by date descending.
- R5: WHEN an authenticated user views achievements, THE SYSTEM SHALL fetch and display
  all rows from `achievements` for that user, ordered by `earned_at` descending.
- R6: WHERE a data-fetch fails (network/Supabase error), THE SYSTEM SHALL render the
  existing `error.tsx` boundary already present for this route rather than a raw error.
- R7: WHEN a new string is added for this feature, THE SYSTEM SHALL add it to all three
  message files (`ar.json`, `en.json`, `fr.json`) — no locale left with a missing key.

## Data model changes

None. This is read-only against existing tables. RLS policies on `profiles`,
`daily_records`, and `achievements` must already restrict rows to `auth.uid()` (verify
this is true today, since the mobile app relying on client-side Supabase calls implies
RLS is already the enforcement boundary — this spec doesn't need to add policies, only
confirm existing ones cover a web-originated `auth.getUser()` session the same way).

## Open questions

- Should recent-history rows be paginated/infinite-scroll, or is a fixed last-14-days
  view sufficient for v1? Recommend fixed window for v1 given the placeholder-to-real
  jump is already the main value.
- Does the `fr` web locale matter for this feature, or is French support itself
  incomplete/aspirational elsewhere in the web app? Worth confirming before spending
  translation effort on `fr.json` for new dashboard strings.

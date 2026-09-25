# Spec: Family / Community Accountability Circles

## Status
Implemented (R1-R8) on mobile + Supabase: `apps/mobile/lib/features/circles/`
(list/detail screens, `circle_models.dart`, `circles_providers.dart`) over the
`circles` / `circle_members` / `circle_reactions` tables and their SECURITY DEFINER RPCs in
`apps/mobile/supabase/migrations/20260916120000_add_family_circles.sql` — invite codes,
per-signal opt-in toggles defaulting to off, streak/points leaderboard, the fixed five-phrase
reaction set with an unread badge, and guest-mode gating. `get_circle_leaderboard()` NULLs any
signal a member hasn't opted into, which is what makes R4/R8 enforceable server-side rather
than in the widget tree. Both catalog achievements exist now: `circle_joined` (granted on
create/join) and `circle_streak_match` (granted when your local streak equals a peer's shared
streak — `matchesSharedStreak()` in `circle_models.dart`, covered by
`apps/mobile/test/features/circles/circle_models_test.dart`).

Known deviation: there is **no Drift local mirror** for circles, contrary to the data-model
sketch below. Circle data is read straight from Supabase, so the feature is
network-only/offline-empty. That was a deliberate scope call — a cached mirror adds a sync
surface for data whose whole point is cross-user freshness — and it is the one thing to
revisit if circles ever need to render offline.

## Context — what "community" already means in this app today

Don't confuse this feature with what already exists:

- `community_adhkar` / `community_duas` (`apps/mobile/docs/schema.sql:98,113`) are a
  **content-sharing** feed: a user can share a custom dhikr/dua (`shared_by`), others can
  `like` it, and a moderator `approve`s it before it's visible
  (`apps/mobile/lib/features/adhkar/presentation/screens/_user_community_adhkar_views.dart`,
  `CommunityAdhkarTabView` at line 503). There is no follower graph, no notion of "my
  circle," and nothing about a user's own worship data is shared — only content they
  chose to author and submit.
- This spec is a different thing: letting a user opt certain *progress signals*
  (streaks, points, checklist completion) be visible to a small circle of people they
  explicitly invite (family/friends), for mutual encouragement — closer to a
  Duolingo-style friends/leaderboard feature than the existing content feed.

Relevant existing building blocks to reuse rather than duplicate:

- `profiles` table already has `total_points`, `current_streak`, `highest_streak`,
  `quran_pages` (`apps/mobile/docs/schema.sql:218`) — exactly the aggregate fields a
  circle/leaderboard view would read. No new aggregate computation needed server-side if
  these are already kept correct by the existing sync path.
- `GuestModeGuard` (`apps/mobile/lib/core/widgets/guest_mode_guard.dart`) is the existing
  pattern for "this screen requires an authenticated account" — reuse it verbatim to gate
  the whole feature, since it inherently requires a Supabase account (guest/local-only
  users have no `user_id` to be discoverable by).
- `AchievementCategory` / `achievement_definition.dart` is the existing gamification
  system — new circle-related achievements (e.g. "invited 3 friends," "matched a friend's
  streak") should be added there, not a parallel system.
- `SyncManager` (`apps/mobile/lib/core/supabase/sync_manager.dart`) is the existing
  push/pull sync engine; circle membership and shared-signal visibility should be
  additional Supabase tables/RLS policies read through the same client, not a new sync
  mechanism.

## Privacy is the central design constraint

This is a personal religious-accountability app: `daily_records` includes prayer status
per-prayer, fasting, and (via `prohibitions_log`) sins/prohibitions committed. **None of
that granular data should ever become visible to a circle by default, or at all in v1.**
Only opt-in, coarse, positive signals should be shareable:

- Current streak length (not which specific days/prayers).
- Total points / level (not the point breakdown).
- Checklist "completed today: yes/no" (not which items).
- Quran pages read (aggregate, not which surah/khatma).

## Goals

1. Circles: a user can create a circle (e.g. "family") and invite others via an
   invite-code or link; invitees who accept become members of that circle.
2. Per-circle, per-user opt-in toggle for each shareable signal (streak, points,
   checklist-done-today, Quran pages) — off by default.
3. A circle view listing members with only their opted-in signals, sorted by streak or
   points (leaderboard), reusing `profiles.current_streak`/`total_points`.
4. Lightweight encouragement: a member can send a fixed set of pre-written
   encouragement reactions (e.g. "🤲 دعوة لك", "💪 استمر") to another member — no free-text
   chat, to keep moderation surface minimal (same spirit as the existing
   `approved` moderation flag on community content).
5. New achievements for circle participation, added to the existing
   `AchievementDefinition.all` catalog.

## Non-goals

- Free-text chat/messaging between members.
- Sharing granular `daily_records`/`prohibitions_log` rows, ever.
- Public/global leaderboards — circles are private, invite-only.
- Cross-posting circle activity to the existing `community_adhkar`/`community_duas` feed.
- Push notifications for every circle event in v1 (e.g. "so-and-so hit a 7-day streak") —
  start with in-app only; notification fan-out is a fast-follow once the data model
  exists.

## Functional requirements (EARS)

- R1: WHEN an authenticated user creates a circle, THE SYSTEM SHALL generate a unique,
  shareable invite code for that circle.
- R2: WHEN an authenticated user redeems a valid invite code, THE SYSTEM SHALL add them as
  a member of that circle with all sharing toggles defaulted to off.
- R3: WHILE a user has not authenticated (guest mode), THE SYSTEM SHALL gate the entire
  circles feature behind the existing `GuestModeGuard` pattern.
- R4: WHEN a member enables sharing for a specific signal (streak/points/checklist-done/
  Quran pages), THE SYSTEM SHALL make only that signal visible to other members of that
  specific circle — never other circles, never non-opted-in signals.
- R5: WHEN viewing a circle, THE SYSTEM SHALL list members sorted by a selectable
  metric (streak or points) using only opted-in, aggregate values already present in
  `profiles`.
- R6: WHEN a member sends a pre-written encouragement reaction to another member, THE
  SYSTEM SHALL deliver it as an in-app notification/badge to the recipient, drawn only
  from a fixed, pre-approved list of phrases (no free text).
- R7: WHEN a user leaves or is removed from a circle, THE SYSTEM SHALL immediately stop
  exposing any of their signals to that circle's remaining members.
- R8: IF a user has never enabled any sharing toggle in a circle, THEN THE SYSTEM SHALL
  show them in that circle's member list with signals hidden/blank rather than zeros
  (to avoid implying "0 streak").

## Data model changes (new Supabase tables + local mirrors, following the existing
`daily_records`/`custom_ibadah` per-user-row + Drift-local-cache pattern)

- `circles`: `id`, `owner_id`, `name`, `invite_code`, `created_at`.
- `circle_members`: `circle_id`, `user_id`, `joined_at`, `share_streak` (bool),
  `share_points` (bool), `share_checklist_done` (bool), `share_quran_pages` (bool).
  RLS: a user can only read rows for circles they belong to.
- `circle_reactions`: `id`, `circle_id`, `from_user_id`, `to_user_id`, `phrase_key`,
  `created_at`. RLS: readable by sender/recipient and circle members only.
- New `AchievementDefinition` entries (no schema change — reuses existing `achievements`
  table): e.g. `circle_joined`, `circle_streak_match`.

## Open questions

- Should circle size be capped (e.g. immediate family = small, vs. large groups)? Affects
  whether a simple invite-code model is sufficient or an admin/roles model is needed.
- Should a member be able to belong to multiple circles simultaneously (e.g. "family" and
  "study group")? Assumed yes above (`circle_members` is many-to-many), but UI for
  switching between circles needs design.
- Encouragement reactions: fixed phrase list needs actual copy decided (Arabic-first, per
  the app's current Arabic-only runtime strings) before `phrase_key` values can be
  finalized.
- Does this feature ship inside the free/honor-system app as-is, or does it become the
  first reason to actually enforce `subscription_screen.dart`'s payment gate? Today that
  screen is honor-system/no enforcement — needs a product decision, not assumed here.

-- ─────────────────────────────────────────────────────────────
-- Fix: sharing a dua/dhikr to the community silently never showed
-- up anywhere.
--
-- `community_duas.approved` / `community_adhkar.approved` have no
-- column default, so a plain insert leaves them null. Both
-- getCommunityDuas()/getCommunityAdhkar() filter client-side with
-- `.eq('approved', true)`, and (per the 2026-09-06 RLS audit,
-- supabase/audit/table_checklist.md) that filter is backed by a
-- matching server-side SELECT policy — so a null/false row isn't
-- just hidden by the app, it's unreadable by anyone via the anon
-- key. There has never been any moderation UI in this app (mobile
-- or web) to flip `approved` afterwards, so every share made
-- before this fix is invisible forever.
--
-- supabase_service.dart's shareDuaToCommunity()/
-- shareAdhkarToCommunity() now send `approved: true` explicitly
-- (allowed — the INSERT policy only checks `shared_by =
-- auth.uid()`), so new shares work going forward. This migration
-- covers the other two cases: it sets a matching DEFAULT for any
-- insert path that doesn't set the column explicitly, and it
-- backfills the shares that already went in stuck invisible.
-- ─────────────────────────────────────────────────────────────
alter table public.community_duas
alter column approved
set default true;

alter table public.community_adhkar
alter column approved
set default true;

update public.community_duas
set approved = true
where approved is distinct from true;

update public.community_adhkar
set approved = true
where approved is distinct from true;

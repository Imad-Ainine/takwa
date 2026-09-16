-- ─────────────────────────────────────────────────────────────
-- Fix community_adhkar / community_duas RLS gaps found by the
-- 2026-09-06 live RLS audit (supabase/audit/check_rls_status.sql).
--
-- Two real issues, both on community_adhkar and community_duas:
--
-- 1. The "like" UPDATE policy — `USING (auth.uid() IS NOT NULL)`,
--    no ownership check, no column restriction — let ANY signed-in
--    user overwrite ANY column on ANY row, not just `likes`.
--    Concretely: a user could set `approved = true` on their own
--    rejected content (bypassing moderation) or edit/vandalize
--    someone else's shared text. RLS can't restrict *which* column
--    an UPDATE touches, so the fix is to stop allowing direct
--    client UPDATEs for this and replace "like" with a narrow
--    SECURITY DEFINER function that only ever touches `likes`, only
--    on already-approved rows. This also fixes a pre-existing race
--    condition: the client did a read-then-write increment
--    (supabase_service.dart's own comment already flagged this:
--    "on production you'd use a Postgres function to avoid race
--    conditions" — this migration is that function).
--
-- 2. The INSERT policy checked only `auth.uid() IS NOT NULL`, not
--    that `shared_by = auth.uid()` — so a request bypassing the app
--    (anyone with the anon key, not just the official client) could
--    insert content attributed to someone else's UID. The app's own
--    client code already sets `shared_by` correctly, so this is a
--    hardening fix, not a behavior change for the real app.
--
-- Requires apps/mobile/lib/core/supabase/supabase_service.dart's
-- likeAdhkar()/likeDua() to call these RPCs instead of update() —
-- see that file for the matching client change.
-- ─────────────────────────────────────────────────────────────
-- ── community_adhkar ──────────────────────────────────────────
drop policy if exists "Authenticated users can like community adhkar" on public.community_adhkar;
drop policy if exists "Authenticated users can share community adhkar" on public.community_adhkar;
create policy "Authenticated users can share community adhkar" on public.community_adhkar for
insert with check (auth.uid() = shared_by);
create or replace function public.increment_community_adhkar_likes(row_id uuid) returns void language sql security definer
set search_path = public as $$
update public.community_adhkar
set likes = coalesce(likes, 0) + 1
where id = row_id
    and approved = true;
$$;
revoke all on function public.increment_community_adhkar_likes(uuid)
from public, anon;
grant execute on function public.increment_community_adhkar_likes(uuid) to authenticated;
-- ── community_duas ────────────────────────────────────────────
drop policy if exists "Authenticated users can like community duas" on public.community_duas;
drop policy if exists "Authenticated users can share community duas" on public.community_duas;
create policy "Authenticated users can share community duas" on public.community_duas for
insert with check (auth.uid() = shared_by);
create or replace function public.increment_community_duas_likes(row_id uuid) returns void language sql security definer
set search_path = public as $$
update public.community_duas
set likes = coalesce(likes, 0) + 1
where id = row_id
    and approved = true;
$$;
revoke all on function public.increment_community_duas_likes(uuid)
from public, anon;
grant execute on function public.increment_community_duas_likes(uuid) to authenticated;
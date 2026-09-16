-- ─────────────────────────────────────────────────────────────
-- Close the nullable-owner gap flagged by the Security & Privacy
-- audit (2026-09-06). Verified against the live database before
-- writing this: all five tables currently have zero NULL-user_id
-- rows, so this is a pure constraint tightening — no data cleanup
-- needed, nothing to migrate or delete.
--
-- This was never an active leak (every "manage own X" RLS policy
-- uses `auth.uid() = user_id`, which evaluates to NULL — deny — for
-- a NULL-owner row, so such a row was already unreadable by
-- everyone, not exposed to everyone). This closes the underlying
-- data-hygiene gap that made a NULL owner possible at all, and adds
-- `DEFAULT auth.uid()` as a safety net for any insert path that
-- forgets to set `user_id` explicitly.
-- ─────────────────────────────────────────────────────────────

alter table public.achievements
  alter column user_id set default auth.uid(),
  alter column user_id set not null;

alter table public.custom_ibadah_log
  alter column user_id set default auth.uid(),
  alter column user_id set not null;

alter table public.prohibitions_log
  alter column user_id set default auth.uid(),
  alter column user_id set not null;

alter table public.user_adhkar
  alter column user_id set default auth.uid(),
  alter column user_id set not null;

alter table public.user_duas
  alter column user_id set default auth.uid(),
  alter column user_id set not null;

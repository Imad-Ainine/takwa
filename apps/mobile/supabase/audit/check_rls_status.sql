-- ─────────────────────────────────────────────────────────────
-- RLS status audit — read-only, safe to run in the Supabase SQL
-- editor at any time. Changes nothing.
--
-- Run this first, before touching anything: it tells you which of
-- Takwa's tables currently have Row Level Security enabled at all,
-- and lists every policy that exists on each one. Compare the
-- output against supabase/audit/table_checklist.md.
-- ─────────────────────────────────────────────────────────────

-- 1) Which public-schema tables have RLS ON vs OFF.
--    Any Takwa table showing `rls_enabled = false` here is a table
--    every authenticated user's anon-key request can read/write in
--    full, regardless of `user_id` — that's the critical case.
select
  c.relname as table_name,
  c.relrowsecurity as rls_enabled,
  c.relforcerowsecurity as rls_forced
from pg_class c
join pg_namespace n on n.oid = c.relnamespace
where n.nspname = 'public'
  and c.relkind = 'r'
order by c.relrowsecurity asc, c.relname;

-- 2) Every existing policy, per table — what it allows, for whom,
--    and under what condition. An empty result for a table that
--    showed `rls_enabled = true` above means RLS is on but nothing
--    is allowed through (the table is effectively locked, including
--    to its own owner) — also worth knowing, just the opposite risk.
select
  schemaname,
  tablename,
  policyname,
  permissive,
  roles,
  cmd as applies_to,          -- SELECT / INSERT / UPDATE / DELETE / ALL
  qual as using_expression,   -- condition for SELECT/UPDATE/DELETE
  with_check as check_expression -- condition for INSERT/UPDATE
from pg_policies
where schemaname = 'public'
order by tablename, policyname;

-- 3) Columns named `user_id` that allow NULL — a common RLS
--    foot-gun: a policy of `user_id = auth.uid()` behaves
--    differently for NULL rows depending on exactly how it's
--    written, and NULL owner rows can end up readable/writable by
--    nobody, or by everybody, depending on the policy's exact form.
--    Cross-check this against table_checklist.md's "owner column"
--    notes.
select
  table_name,
  column_name,
  is_nullable,
  column_default
from information_schema.columns
where table_schema = 'public'
  and column_name = 'user_id'
order by table_name;

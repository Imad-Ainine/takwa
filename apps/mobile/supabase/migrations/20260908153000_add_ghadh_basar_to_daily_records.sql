-- ─────────────────────────────────────────────────────────────
-- Adds ghadh_basar (lowering the gaze) column to daily_records table.
-- ─────────────────────────────────────────────────────────────

alter table public.daily_records
  add column if not exists ghadh_basar boolean default false;

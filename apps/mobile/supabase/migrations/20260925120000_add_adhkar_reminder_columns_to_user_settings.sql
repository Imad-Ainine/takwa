-- ─────────────────────────────────────────────────────────────
-- The adhkar/dua reminder redesign adds three fields to
-- UserPreferences (apps/mobile/lib/features/settings/data/
-- user_preferences.dart): a sleep-adhkar toggle that finally makes the
-- bedtime reminder switch-off-able, how many minutes after Fajr/Asr the
-- prayer-anchored reminders fire, and a user-set time for the daily dua.
--
-- SyncManager.syncSettings() upserts the *entire* toMap() in one PostgREST
-- call, so a key without a column fails the whole push for every setting —
-- the bug already fixed once in
-- 20260912130000_add_missing_prayer_offset_columns_to_user_settings.sql.
-- Types match what toMap() actually sends (see that note on pre_adhan_notif),
-- and every default equals the Dart default so a pull on a fresh device
-- reproduces the in-app defaults.
--
-- Verified applied on the live project (fmmgiykwebwruhxeztvs) on 2026-09-25:
-- all three columns exist and every key UserPreferences.toMap() pushes has a
-- column. Re-running this is a no-op, which is why it is written with
-- `if not exists`.
-- ─────────────────────────────────────────────────────────────

alter table public.user_settings
  add column if not exists sleep_adhkar_reminder bool default true,
  add column if not exists adhkar_after_prayer_minutes int4 default 15,
  add column if not exists dua_reminder_time text default '12:00';

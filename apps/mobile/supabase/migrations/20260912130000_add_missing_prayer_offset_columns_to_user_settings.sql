-- ─────────────────────────────────────────────────────────────
-- UserPreferences.toMap() (apps/mobile/lib/features/settings/data/
-- user_preferences.dart) sends these 7 keys as part of every settings
-- sync push, but they were never added to `user_settings` — so
-- SyncManager.syncSettings()'s single upsert() with the *entire* map
-- always failed ("Could not find the '<column>' column of 'user_settings'
-- in the schema cache"), for every settings change, not just these
-- fields. Since the push is fire-and-forget (`unawaited(...)` in
-- UserPreferencesNotifier.updatePref), that failure was silent — and the
-- next full sync's pull (SyncManager._syncSettings) would then overwrite
-- the local database with the stale remote row, making any change look
-- like it "didn't save" (e.g. وقت المحاسبة reverting to its default).
-- ─────────────────────────────────────────────────────────────

alter table public.user_settings
  add column if not exists high_latitude_rule text default 'middle_of_the_night',
  add column if not exists fajr_offset int4 default 0,
  add column if not exists sunrise_offset int4 default 0,
  add column if not exists dhuhr_offset int4 default 0,
  add column if not exists asr_offset int4 default 0,
  add column if not exists maghrib_offset int4 default 0,
  add column if not exists isha_offset int4 default 0;

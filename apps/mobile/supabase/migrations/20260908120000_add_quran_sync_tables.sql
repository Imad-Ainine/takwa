-- ─────────────────────────────────────────────────────────────
-- Adds Supabase sync for the Quran feature. Until now,
-- QuranPrefsRepository (bookmarks, last-read position, and Khatma
-- sessions) was 100% local SharedPreferences — none of it reached
-- Supabase, so a signed-in user lost their reading progress, Khatma
-- sessions, and bookmarks whenever they switched devices or
-- reinstalled the app. This migration adds the three tables the
-- matching client change (supabase_service.dart) reads from and
-- writes to, following the same "owns own rows" RLS shape already
-- used by custom_ibadah / custom_ibadah_log / reminders.
-- ─────────────────────────────────────────────────────────────

-- ── quran_bookmarks ───────────────────────────────────────────
-- One row per saved ayah bookmark. Natural key is (user_id, surah_num,
-- ayah_num) — mirrors _BookmarksNotifier's local de-dup key.
create table public.quran_bookmarks (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
  surah_num int4 not null,
  ayah_num int4 not null,
  page int4 not null,
  surah_name text not null,
  saved_at timestamptz not null default now(),
  created_at timestamptz not null default now(),
  unique (user_id, surah_num, ayah_num)
);

alter table public.quran_bookmarks enable row level security;

create policy "Users can view their own quran bookmarks" on public.quran_bookmarks
  for select using (auth.uid() = user_id);
create policy "Users can insert their own quran bookmarks" on public.quran_bookmarks
  for insert with check (auth.uid() = user_id);
create policy "Users can update their own quran bookmarks" on public.quran_bookmarks
  for update using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "Users can delete their own quran bookmarks" on public.quran_bookmarks
  for delete using (auth.uid() = user_id);

-- ── quran_last_read ───────────────────────────────────────────
-- One row per user — the single "continue reading" position, mirroring
-- _LastReadNotifier's local single-bookmark state.
create table public.quran_last_read (
  user_id uuid primary key default auth.uid() references auth.users(id) on delete cascade,
  surah_num int4 not null,
  ayah_num int4 not null,
  page int4 not null,
  surah_name text not null,
  saved_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.quran_last_read enable row level security;

create policy "Users can view their own quran last-read" on public.quran_last_read
  for select using (auth.uid() = user_id);
create policy "Users can insert their own quran last-read" on public.quran_last_read
  for insert with check (auth.uid() = user_id);
create policy "Users can update their own quran last-read" on public.quran_last_read
  for update using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "Users can delete their own quran last-read" on public.quran_last_read
  for delete using (auth.uid() = user_id);

-- ── khatma_sessions ───────────────────────────────────────────
-- Both the active session and archived history share this table (mirroring
-- KhatmaExNotifier's local active/history split — isActive/isCompleted/
-- isCancelled are derived from completed_date/cancelled_date, same as the
-- local KhatmaSessionEx model). `id` is the client-generated local id, kept
-- stable across devices instead of remapping to a server-generated uuid.
create table public.khatma_sessions (
  id text not null,
  user_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
  label text not null,
  type text not null,
  start_date timestamptz not null,
  end_date timestamptz,
  completed_date timestamptz,
  cancelled_date timestamptz,
  start_page int4 not null default 1,
  current_page int4 not null default 1,
  pages_read int4 not null default 0,
  notifications_enabled bool not null default false,
  daily_pages int4,
  total_reading_seconds int4 not null default 0,
  reading_sessions_count int4 not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  primary key (user_id, id)
);

alter table public.khatma_sessions enable row level security;

create policy "Users can view their own khatma sessions" on public.khatma_sessions
  for select using (auth.uid() = user_id);
create policy "Users can insert their own khatma sessions" on public.khatma_sessions
  for insert with check (auth.uid() = user_id);
create policy "Users can update their own khatma sessions" on public.khatma_sessions
  for update using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "Users can delete their own khatma sessions" on public.khatma_sessions
  for delete using (auth.uid() = user_id);

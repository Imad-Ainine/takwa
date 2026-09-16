# RLS table checklist

**Verified live against the `Takwa` Supabase project (`fmmgiykwebwruhxeztvs`).**
Initial audit and the community-content fix landed 2026-09-06; the
nullable-owner columns were closed the same day in a follow-up pass. All
four migrations below are applied and `supabase db push --dry-run --linked`
reports the remote fully in sync with this repo's `migrations/`. Findings
below reflect that live state — re-run `check_rls_status.sql` after any
future schema/policy change instead of trusting this file to stay current.

## Per-user tables (should be scoped to `auth.uid()`)

| Table | Owner column | Column shape | RLS verified? |
|---|---|---|---|
| `daily_records` | `user_id` | `NOT NULL` | ✅ RLS on; `ALL` scoped to `auth.uid() = user_id` |
| `custom_ibadah` | `user_id` | `NOT NULL` | ✅ RLS on; `ALL` scoped to `auth.uid() = user_id` |
| `user_settings` | `user_id` | `NOT NULL` | ✅ RLS on; scoped (two overlapping policies — see note below) |
| `achievements` | `user_id` | `NOT NULL DEFAULT auth.uid()` | ✅ RLS on; scoped (two overlapping policies — see note below) |
| `custom_ibadah_log` | `user_id` | `NOT NULL DEFAULT auth.uid()` | ✅ RLS on; `ALL` scoped to `auth.uid() = user_id` |
| `prohibitions_log` | `user_id` | `NOT NULL DEFAULT auth.uid()` | ✅ RLS on; `ALL` scoped to `auth.uid() = user_id` |
| `user_adhkar` | `user_id` | `NOT NULL DEFAULT auth.uid()` | ✅ RLS on; `ALL` scoped to `auth.uid() = user_id` |
| `user_duas` | `user_id` | `NOT NULL DEFAULT auth.uid()` | ✅ RLS on; `ALL` scoped to `auth.uid() = user_id` |
| `book_reading_progress` | `user_id` | `NOT NULL` | ✅ RLS on; scoped to `{authenticated}` + `auth.uid() = user_id` |
| `reminders` | `user_id` | `NOT NULL` | ✅ RLS on; scoped to `{authenticated}` + `auth.uid() = user_id` |
| `profiles` | `id` | primary key | ✅ RLS on; `ALL` scoped to `auth.uid() = id` |

**Nullable-owner gap: closed** ([`../migrations/20260906201631_close_nullable_owner_gap.sql`](../migrations/20260906201631_close_nullable_owner_gap.sql), applied). Before writing that migration, this was confirmed *not* an active leak either way — every policy above uses `auth.uid() = user_id`, which Postgres evaluates to `NULL` (deny) rather than `true` for a `NULL`-owner row, so such a row was already unreadable and unwritable by everyone, not exposed to everyone. It was a data-hygiene gap, not a security one. Before applying the `NOT NULL` constraint, all five tables were queried directly and confirmed to have **zero** existing `NULL`-owner rows, so this was a pure schema tightening — no data to clean up or delete. The app's own insert/upsert calls (`supabase_service.dart`) already set `user_id` explicitly on every write and guard against a missing session before writing, so nothing in the client depended on the old nullable behavior; `DEFAULT auth.uid()` is a safety net for any insert path that isn't the app itself (an edge function, a future admin script), not something the app relies on today.

**Duplicate policies (cosmetic, not a security issue):** `achievements` and
`user_settings` each carry two overlapping policies with the same
`auth.uid() = user_id` condition (one on `{public}`, one on
`{authenticated}`, or two identically-scoped policies with different
names) — harmless since Postgres OR's permissive policies together and
both enforce the same condition, but worth consolidating to one policy per
table the next time either is touched, so the intent is unambiguous to the
next person reading it. Not fixed — cosmetic, no urgency.

## Public / reference tables (should be public-read, no write from the app)

| Table | Notes | Verified? |
|---|---|---|
| `adhkar` | Static content | ✅ RLS on, `SELECT`-only policy (two duplicate-named ones), no write policy exists → writes denied by default |
| `adhkar_categories` | Same | ✅ Same shape |
| `asma_allah` | Same | ✅ Same shape |
| `books` | Static content — `pdf_url` now points at the app's own `book-pdfs` Storage bucket for all 9 rows instead of islamhouse.com ([`../migrations/20260906195445_point_books_at_storage.sql`](../migrations/20260906195445_point_books_at_storage.sql)) | ✅ RLS on, single `SELECT`-only policy, no write policy |
| `douaa_categories` | Same | ✅ Same shape as adhkar |
| `douaa_content` | Same | ✅ Same shape as adhkar |

## Community / moderated tables (mixed: public read, scoped write)

| Table | Notes | Verified? |
|---|---|---|
| `community_adhkar` | `SELECT` correctly scoped to `approved = true` — the app's client-side `.eq('approved', true)` filter genuinely is backed by a server-side policy, not just a UX convenience. | ✅ **Fixed and live** ([`../migrations/20260906190603_fix_community_content_policies.sql`](../migrations/20260906190603_fix_community_content_policies.sql)). The old `UPDATE` "like" policy (`USING (auth.uid() IS NOT NULL)`, no ownership check, no column restriction — any signed-in user could overwrite *any* column on *any* row, including self-approving unapproved content) is dropped; liking now goes through a `SECURITY DEFINER` function that only touches `likes` on approved rows, granted to `authenticated` only (a follow-up check caught it also being callable by `anon` via Supabase's default grants — revoked). `INSERT` now requires `shared_by = auth.uid()`. |
| `community_duas` | Same shape as `community_adhkar` | ✅ Same fix, same migration, same verification. |

## Storage

| Bucket | Notes | Verified? |
|---|---|---|
| `book-pdfs` | Public, read-only (`SELECT` policy only, no client write policy), 50MB/file limit, `application/pdf` only ([`../migrations/20260906194628_create_book_pdfs_bucket.sql`](../migrations/20260906194628_create_book_pdfs_bucket.sql)) | ✅ All 9 books' PDFs uploaded, verified byte-identical to the islamhouse.com originals and reachable at their public URLs before `books.pdf_url` was repointed at them. |

## What's left

Nothing security-relevant. The only open item from the original audit is
consolidating the duplicate policies on `achievements`/`user_settings`
noted above — cosmetic, do it the next time either table is touched, no
need for a dedicated pass.

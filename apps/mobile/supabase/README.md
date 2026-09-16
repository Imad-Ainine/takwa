# Supabase schema & RLS — versioning this going forward

**Why this folder exists.** [`docs/schema.sql`](../docs/schema.sql) lists
column names and types, but it isn't runnable DDL and it says nothing about
Row Level Security. For an app storing per-user prayer logs, achievements,
and personal notes, whether RLS is actually enabled — and enabled
correctly — currently isn't answerable from the repo at all; it can only be
checked (or changed) in the Supabase dashboard, with no history and no
review. This folder is where that stops being true.

## Step 1 — audit what's live today (no tooling needed)

You don't need the Supabase CLI for this part.

1. Open the Supabase dashboard → SQL Editor for the Takwa project.
2. Run [`audit/check_rls_status.sql`](./audit/check_rls_status.sql). It's
   read-only — it changes nothing, just reports RLS status, existing
   policies, and which tables have a nullable `user_id`.
3. Go through [`audit/table_checklist.md`](./audit/table_checklist.md) and
   check off each table against what the query showed. The five tables
   flagged there with a nullable `user_id` column are the priority — those
   are the ones where a wrong or missing policy would leak or corrupt
   another user's data.
4. Fix whatever's missing directly in the dashboard for now (Step 2 is what
   makes future fixes go through git instead).

## Step 2 — bring the schema under version control

This needs the [Supabase CLI](https://supabase.com/docs/guides/cli/getting-started).

```bash
# once
supabase login
supabase link --project-ref <your-project-ref>

# from apps/mobile/ — pulls the live schema (tables, RLS policies,
# functions, everything) into a timestamped migration file under
# supabase/migrations/
supabase db pull
```

Commit the resulting migration file. That's the baseline — from this point
on, `apps/mobile/supabase/migrations/` is the source of truth for what the
schema and its policies *should* be, and the dashboard is just where it gets
applied.

## Step 3 — going forward

- A schema or policy change starts as `supabase migration new <name>`,
  which creates a new empty SQL file in `migrations/` — write the change
  there, not in the dashboard.
- `supabase db push` applies pending local migrations to the linked
  project.
- Changes go through a normal PR like any other code change, so an RLS
  policy edit gets reviewed before it's live, not after.
- If the dashboard ever *is* edited directly (hotfix, emergency), run
  `supabase db pull` again afterward to bring the migration history back in
  sync — don't let it drift silently.

## Why this matters specifically here

`SupabaseConfig`'s anon key ([supabase_config.dart](../lib/core/supabase/supabase_config.dart))
is meant to be public — that's normal for Supabase, RLS is the actual
security boundary, not key secrecy. Client-side filters like
`.eq('approved', true)` in [supabase_service.dart](../lib/core/supabase/supabase_service.dart)
are UX conveniences, not security: anyone with the anon key can query the
table directly and skip that filter entirely unless a policy enforces it
server-side too. See `audit/table_checklist.md`'s community-tables section
for the specific case that applies to.

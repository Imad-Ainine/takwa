-- ─────────────────────────────────────────────────────────────
-- Freemius SaaS billing for non-Algerian supporters — see
-- docs/freemius-integration.md.
--
-- Two tables:
--   freemius_events        raw webhook log; one row per delivered
--                          event, `event_uid` unique = idempotency key
--                          (Freemius redelivers on any non-2xx).
--   premium_entitlements   one row per Supabase user, written ONLY by
--                          the webhook/proxy (service role). Clients
--                          read their own row to show premium status.
--
-- Chargily (DZ) payments stay exactly as they were: an honor-system
-- local record with no server entitlement. This schema is the first
-- server-side payment truth in the project; historical Wise records
-- lived only on-device (premium_payments drift key) and are untouched.
-- ─────────────────────────────────────────────────────────────

create table public.freemius_events (
  id bigint generated always as identity primary key,
  -- Freemius sends a unique event id per delivery of a logical event;
  -- a second INSERT with the same uid is a retry, not a new event.
  event_uid text not null unique,
  event_type text not null,
  freemius_user_id text,
  license_id text,
  subscription_id text,
  payload jsonb not null,
  received_at timestamptz not null default now(),
  apply_status text not null default 'received'
    check (apply_status in ('received', 'applied', 'ignored', 'failed')),
  apply_error text,
  processed_at timestamptz
);

create index idx_freemius_events_pending
  on public.freemius_events (apply_status, received_at)
  where apply_status in ('received', 'failed');
create index idx_freemius_events_license
  on public.freemius_events (license_id, received_at desc);

alter table public.freemius_events enable row level security;
-- No policies at all: inserts/reads happen exclusively through the
-- service-role key (webhook handler + reconcile endpoint). An
-- event payload contains buyer PII; the app must never read it.

create table public.premium_entitlements (
  user_id uuid primary key references auth.users(id) on delete cascade,
  source text not null default 'freemius'
    check (source in ('freemius', 'chargily', 'manual')),
  -- Lifecycle mirrors Freemius licence/payment states:
  --   trial, active, past_due     → access (past_due until period end)
  --   canceled                    → access until current_period_end
  --   expired, refunded           → no access (kept for history/messaging)
  status text not null
    check (status in ('trial', 'active', 'past_due', 'canceled', 'expired', 'refunded')),
  plan_id text,
  plan_title text,
  is_trial boolean not null default false,
  cancel_at_period_end boolean not null default false,
  current_period_end timestamptz,
  email text,
  freemius_user_id text,
  license_id text,
  subscription_id text,
  -- Last event already folded into this row: out-of-order or replayed
  -- events older than this uid are ignored.
  last_event_id bigint,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index idx_premium_entitlements_license
  on public.premium_entitlements (license_id);
create index idx_premium_entitlements_freemius_user
  on public.premium_entitlements (freemius_user_id);

alter table public.premium_entitlements enable row level security;

create policy "Owner can view their premium entitlement"
  on public.premium_entitlements
  for select
  using (user_id = auth.uid());
-- INSERT/UPDATE/DELETE intentionally have no client policy: only the
-- service-role webhook writes this table. A user must never be able to
-- grant themselves premium — that is the whole point of moving off the
-- honor system for card payments.

-- Keep updated_at honest even for hand-written SQL (grants, fixes).
create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create trigger premium_entitlements_set_updated_at
  before update on public.premium_entitlements
  for each row execute function public.set_updated_at();

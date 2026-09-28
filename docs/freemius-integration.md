# Freemius payment integration (international card support)

Replaces the old manual "Wise transfer" screen for **non-Algerian** supporters with a
real card pipeline: **Freemius** (merchant of record, SaaS mode) for Visa/Mastercard
worldwide, while **Chargily** (CIB / Edahabia, DZD) stays exactly as before for
Algerian customers.

- App: `apps/mobile` (Flutter)
- Server: `apps/web` (Next.js on Vercel, auto-deploys from `main`)
- Database: Supabase (`apps/mobile/supabase/migrations/20260928120000_add_freemius_payments.sql`)

---

## 1. Architecture & payment flow

```
FreemiusPaymentScreen (mobile)
  │ 1. POST /api/payments/freemius/checkout   (Bearer = Supabase access token)
  ▼
apps/web proxy  ── verifies the Supabase session, owns the plan id,
  │                embeds custom={"takwa_user_id": <auth.uid()>}
  │ 2. returns checkout_url (https://checkout.freemius.com/app/{id}/plan/{id}/…)
  ▼
Freemius hosted checkout (browser Custom Tab; email locked with readonly_user)
  │ 3. card charged; success/cancel redirect →
  │    {webBase}/{locale}/payment-redirect?to=takwa://payment-{success|failure}
  │ 4. server-to-server webhooks →
  ▼
POST /api/payments/freemius/webhook
  │    verify HMAC x-signature → log to freemius_events (idempotent)
  │    → derive entitlement → upsert premium_entitlements
  ▼
Mobile polls its OWN premium_entitlements row (RLS: owner-read only)
       → "Payment received" screen + subscription status card
```

The app **never** holds a Freemius key. The proxy is the only Freemius API client.
Purchase truth lives in `premium_entitlements`; the redirect hop and the local
`SubscriptionStore` JSON are UX/history only.

Lifecycle handled (all via webhooks — money state changes never go through the client):
new purchase, trial start/convert, renewal, failed renewal (`past_due`), plan
change/upgrade/downgrade (`license.plan.changed`), cancellation with access until
period end, expiry, refund, chargeback, reactivation.

## 2. Country-based routing rules

Implemented in `lib/core/payments/payment_router.dart` (pure + unit-tested):

| Signal (in order)                              | Rail chosen |
| ---------------------------------------------- | ----------- |
| Manual override `payment_country_override = 'dz'`   | Chargily |
| Manual override `= 'intl'`                          | Freemius |
| Device region country code `DZ`                     | Chargily |
| No region (bare locale) and language `ar`           | Chargily (safe default for the core audience) |
| Any other detected region                           | Freemius |

The override is a user-facing row on the payment-methods screen ("Where do you want
to pay from?" → Auto / Algeria / International), persisted in the local settings DAO;
it only affects the *suggested/default* rail — both cards remain visible and tappable.
Chargily behaviour for Algerian customers is otherwise byte-for-byte unchanged.

## 3. Configuration

### apps/web (Vercel env — server-side only)

| Variable                       | Required | Purpose |
| ------------------------------ | -------- | ------- |
| `FREEMIUS_PRODUCT_ID`          | Yes      | Freemius app/product id (numeric) |
| `FREEMIUS_PUBLISHABLE_KEY`     | Yes      | `pk_test_…` / `pk_live_…` — only ever placed into checkout URLs server-side |
| `FREEMIUS_SECRET_KEY`          | Yes      | `sk_…` — REST auth **and** the HMAC secret for `x-signature` webhook verification |
| `FREEMIUS_MONTHLY_PLAN_ID`     | Yes      | Plan id charged for the default monthly tier |
| `FREEMIUS_PLAN_IDS`            | No       | Comma list of plan ids the app may select (default: only the monthly plan) |
| `FREEMIUS_PORTAL_URL`          | No       | Billing-portal URL template; `{PRODUCT_ID}`, `{PUBLIC_KEY}`, `{USER_EMAIL}` are substituted. Default `https://billing.freemius.com/app/{PRODUCT_ID}/account/?public_key={PUBLIC_KEY}` — **verify once against the dashboard's portal link and adjust here via env only** |
| `TAKWA_ADMIN_SECRET`           | Yes      | Protects `POST /api/payments/freemius/reconcile` |
| `SUPABASE_URL`, `SUPABASE_SERVICE_ROLE_KEY`, `SUPABASE_ANON_KEY` | already present | webhook writes + JWT validation |

### apps/mobile (public `.env`)

| Variable               | Purpose |
| ---------------------- | ------- |
| `FREEMIUS_MONTHLY_USD` | Display mirror of the plan price in USD (default `10`). Never authoritative. |
| `TAKWA_WEB_BASE_URL`   | Shared with Chargily; points at the proxy. |

The international plan bills in **USD**, so `FreemiusConfig.monthlyDisplay`
renders `$…` and local payment history records `currency: 'usd'`. If the plan
currency ever changes in the Freemius dashboard, change both in
`lib/core/payments/payment_config.dart` — the screen and the history entry are
the only two consumers.

## 4. Freemius dashboard setup checklist (one-time, needs your account)

1. Create the Takwa **Application** product; enable **SaaS billing mode**.
2. Define plans (at least the monthly tier priced in **USD**, currently
   $10.00; Freemius handles currency conversion, coupons and VAT itself).
3. Product → **Settings → API & Keys**: copy the **product id**, **publishable
   key** (`pk_…`) and **secret key** (`sk_…`) into the Vercel env
   (Settings → Environment Variables for `takwa-web`), never into the repo or
   `apps/mobile/.env`. If that tab shows an "API Bearer Authorization Token"
   that differs from the secret key, say so — `change-plan` currently sends the
   secret key as the bearer.
4. **Developer Dashboard → Plans**: the **Plan ID** column is
   `FREEMIUS_MONTHLY_PLAN_ID` (`69574` for the current monthly plan); extra
   plans go in `FREEMIUS_PLAN_IDS`. Plans differ by features, not billing
   cycle — an annual pricing lives inside the same plan id.
5. Real-time updates: **Webhooks → Listeners → Add Webhook**, URL
   `https://takwa-web.vercel.app/api/payments/freemius/webhook`, all event
   types, active. Freemius signs with the product secret key (no separate
   signing secret), so `FREEMIUS_SECRET_KEY` must match the product exactly.
6. Sanity-check the checkout link shape: generate a test checkout link in the
   dashboard and compare its query parameters against `buildCheckoutUrl` in
   `apps/web/src/lib/freemius.ts`. If Freemius changed a parameter name, that
   single function is the only place to adjust.
7. Use the sandbox (`pk_test_`/`sk_test_`) first; the code treats key prefix
   modes like Chargily does (no separate mode switch).

## 5. Database changes & migration strategy

`20260928120000_add_freemius_payments.sql`:

- **`freemius_events`** — raw webhook log. `event_uid UNIQUE` is the idempotency key
  (Freemius redelivers any non-2xx); `apply_status ∈ received/applied/ignored/failed`
  plus `apply_error` is the monitoring surface. RLS on, **no policies**: only the
  service role touches it (payloads contain buyer PII — the app must never read it).
- **`premium_entitlements`** — one row per Supabase user; written only by the
  webhook/proxy. Clients get `SELECT` on their own row via RLS
  (`user_id = auth.uid()`). Status vocabulary: `trial, active, past_due, canceled,
  expired, refunded`; access rule (shared with the Dart model):
  `active/trial` until `current_period_end`; `past_due`/`canceled` keep access until
  the already-paid period lapses; `expired`/`refunded` never grant access.
- `last_event_id` monotonic guard: an older delivery can never overwrite a newer state.

**Applying it**: per this project's convention, paste the migration into the
Supabase dashboard SQL editor (no working CLI here). Idempotency-safe re-runs are
guarded by `create table` (fails loudly if already applied — never silently drifts).

**Historical data**: nothing migrates. Old Wise records were device-local
user-declared entries (`premium_payments` drift key) and keep parsing — the
`SupportChannel.wise` enum value is retained exactly for that. Chargily purchases
stay honor-system records with no entitlement row. There were **no server-side
payment records before Freemius**, so no backfill is required; if a known past
subscriber must be honored, insert their `premium_entitlements` row by hand with
`source='manual'`.

## 6. Testing

Automated:

```bash
# apps/web — webhook logic + signature/checkout-URL building (node:test)
npm --prefix apps/web test

# apps/mobile — routing matrix, proxy client, entitlement rules, legacy history
cd apps/mobile && flutter test test/core/payments
```

Manual end-to-end (sandbox):

1. Apply the migration; set test-mode env; deploy (`git push` — Vercel builds).
2. On a device/emulator with region ≠ DZ (or set the override to
   International), open Subscription → Pay monthly → card 1 → Freemius screen:
   expect "Sign in to subscribe" when logged out, otherwise the hosted page
   opens with your account email locked.
3. Pay with a Freemius sandbox card. The app polls its own entitlement row;
   within a few seconds of the webhook it must flip to "Payment received",
   and the subscription screen must show the status card.
4. In the dashboard: cancel at period end → status card "premium stays active
   until …"; issue a refund → card "refunded, premium paused".
5. Verify rejection paths: `POST webhook` with a bad `x-signature` → 401 and
   no DB rows; replay the same valid body → `outcome: "duplicate"`.

## 7. Deployment & rollback

Deploy order (the app fails safe on every intermediate state):

1. Paste the Supabase migration.
2. Add the `FREEMIUS_*` + `TAKWA_ADMIN_SECRET` env vars in Vercel.
3. Commit + push `main` → takwa-web auto-deploys (~1 min).
4. Configure the webhook URL in the Freemius dashboard.
5. Ship the mobile build (routing + Freemius screen + status card).

Old installed builds are unaffected: they still talk to `/api/payments/checkout`
(untouched) and the removed Wise screen simply never existed server-side.

Rollback:
- **Fast kill-switch**: remove/blank `FREEMIUS_SECRET_KEY` in Vercel → every
  Freemius route answers 503 `payments_not_configured`, the app shows the
  error state; Chargily keeps working; remove the webhook URL in the dashboard.
- **Code rollback**: revert the mobile/web commits; tables can stay (they are
  inert without the webhook). No destructive migration is needed, so down is
  up-safe.

## 8. Operations: monitoring & troubleshooting

Health queries (dashboard SQL):

```sql
-- anything not applied cleanly in the last day
select event_type, apply_status, apply_error, count(*)
from freemius_events where received_at > now() - interval '1 day'
group by 1,2,3 order by 4 desc;

-- entitlements that think they are active but should have lapsed
select * from premium_entitlements
where status in ('trial','active','past_due','canceled')
  and current_period_end < now();  -- a renewal webhook should have moved these
```

Retry/reconciliation: `curl -X POST -H "x-takwa-admin-secret: …"
https://takwa-web.vercel.app/api/payments/freemius/reconcile` re-applies every
`received`/`failed` event (e.g. someone subscribed with an email before creating
their Supabase account). Optionally schedule it via Vercel Cron — see
`vercel.json` `crons` key.

Symptom table:

| Symptom | Meaning / fix |
| ------- | ------------- |
| Webhook 401 `invalid_signature` | Wrong `FREEMIUS_SECRET_KEY`, or a CDN/proxy re-serialized the body (the HMAC is over raw bytes; the route reads `.text()` before parsing — keep it that way). |
| 503 `payments_not_configured` | Missing `FREEMIUS_*` env in Vercel. |
| App shows `Freemius … failed (404): http_404` | The route is not deployed yet — `apps/web/.env` only feeds `next dev`; the app calls the production URL, so the code must be merged to `main` and the env vars added in Vercel. Check with `curl -X POST https://takwa-web.vercel.app/api/payments/freemius/checkout` (expect 503 JSON once deployed, 404 HTML while absent). |
| App stuck on "not confirmed yet" | Webhook not configured, or event row shows `failed: no_matching_supabase_user` → run reconcile after the account exists. |
| `duplicate` outcome on every event | Freemius event body lacks a unique id and normalization picked a per-delivery field — check `freemius_events.event_uid` values; it should not re-send identical ids for distinct events. |
| 404 `no_active_license` on change-plan | User has no Freemius license (Chargily supporter / never paid) → client must fall back to a normal new checkout. |
| Checkout params rejected by Freemius | Dashboard-generated link differs from `buildCheckoutUrl` → adjust that one function (and its unit test). |
| Refund/chargeback not revoking | The event arrived with an unknown shape: find it in `freemius_events` (still fully logged), extend `deriveEntitlement` + test, then `POST /reconcile`. |

Logs: `[freemius] …` lines in Vercel's function logs for API failures (error
bodies are truncated and never forwarded to the client).

## 9. Security notes

- Freemius secret key: Vercel env only; never in the APK, never in the repo
  (the pre-2026-09-26 leaks are tracked separately — see the payments runbook notes).
- Webhook: constant-time HMAC comparison on raw bytes; length-mismatch
  short-circuit before `timingSafeEqual`; unrecognized bodies are 200-acked after
  logging to stop retry storms, never executed.
- Proxy auth: the Supabase access token is validated against GoTrue
  (`/auth/v1/user`) server-side; the plan id is whitelisted by env, so a crafted
  client request cannot charge an arbitrary plan; redirect URLs are built
  exclusively from the whitelisted `{en,ar}` locale + fixed `takwa://` hops.
- Entitlement writes are service-role-only; RLS guarantees a user can only ever
  read their own premium row (no client can grant itself premium).

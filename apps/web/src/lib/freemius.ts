/**
 * Server-side Freemius SaaS helpers — config, webhook signature
 * verification, hosted-checkout URL building and the Freemius REST API.
 *
 * The FREEMIUS_SECRET_KEY lives ONLY here (Vercel env), same rule as
 * CHARGILY_SECRET_KEY: the mobile app never holds Freemius credentials, it
 * only talks to these /api/payments/freemius/* routes.
 *
 * Environment variables (server-side only):
 *   FREEMIUS_PRODUCT_ID          – numeric app id from the Freemius dashboard
 *   FREEMIUS_PUBLISHABLE_KEY     – pk_test_… (sandbox) or pk_live_… (live)
 *   FREEMIUS_SECRET_KEY          – sk_… ; also the HMAC secret for webhooks
 *   FREEMIUS_MONTHLY_PLAN_ID     – plan id charged for the monthly tier
 *   FREEMIUS_PLAN_IDS            – comma list of plan ids the app may select
 *                                  (defaults to just the monthly plan)
 *   TAKWA_ADMIN_SECRET           – protects the reconcile endpoint
 *   SUPABASE_URL / SUPABASE_SERVICE_ROLE_KEY / SUPABASE_ANON_KEY
 *   TAKWA_WEB_BASE_URL           – public base URL of this app
 */

import { createClient, type SupabaseClient } from '@supabase/supabase-js';
import crypto from 'node:crypto';

const CHECKOUT_HOST = 'https://checkout.freemius.com';
const API_BASE = 'https://api.freemius.com/v1';

export interface FreemiusConfig {
  productId: string;
  publishableKey: string;
  secretKey: string;
  monthlyPlanId: string;
  allowedPlanIds: Set<string>;
}

/** Returns null when any required credential is missing — routes then answer
 *  503 `payments_not_configured` instead of half-working with wrong keys. */
export function freemiusConfig(): FreemiusConfig | null {
  const productId = process.env.FREEMIUS_PRODUCT_ID ?? '';
  const publishableKey = process.env.FREEMIUS_PUBLISHABLE_KEY ?? '';
  const secretKey = process.env.FREEMIUS_SECRET_KEY ?? '';
  const monthlyPlanId = process.env.FREEMIUS_MONTHLY_PLAN_ID ?? '';
  if (!productId || !publishableKey || !secretKey || !monthlyPlanId) return null;
  const planIds = new Set(
    (process.env.FREEMIUS_PLAN_IDS ?? monthlyPlanId)
      .split(',')
      .map((s) => s.trim())
      .filter(Boolean)
  );
  planIds.add(monthlyPlanId);
  return { productId, publishableKey, secretKey, monthlyPlanId, allowedPlanIds: planIds };
}

/**
 * Freemius signs every webhook delivery: HMAC-SHA256 over the RAW request
 * body with the product secret key, hex digest in the `x-signature` header.
 * Must be called with the exact bytes received — any JSON re-serialization
 * changes the digest. timingSafeEqual short-circuits on differing lengths,
 * so normalize both sides before comparing.
 */
export function verifyWebhookSignature(rawBody: string, signatureHeader: string | null, secretKey: string): boolean {
  if (!signatureHeader || !rawBody) return false;
  const expected = crypto.createHmac('sha256', secretKey).update(rawBody, 'utf8').digest();
  let provided: Buffer;
  try {
    provided = Buffer.from(hexToBytes(signatureHeader));
  } catch {
    return false;
  }
  if (provided.length !== expected.length) return false;
  return crypto.timingSafeEqual(provided, expected);
}

function hexToBytes(hex: string): number[] {
  const clean = hex.trim().toLowerCase();
  if (!/^[0-9a-f]+$/.test(clean) || clean.length % 2 !== 0) throw new Error('not hex');
  const out: number[] = [];
  for (let i = 0; i < clean.length; i += 2) out.push(parseInt(clean.slice(i, i + 2), 16));
  return out;
}

/** Constant-time compare for the reconcile endpoint's shared secret. */
export function secretsMatch(provided: string | null, expected: string | undefined): boolean {
  if (!expected || !provided) return false;
  const a = Buffer.from(provided);
  const b = Buffer.from(expected);
  if (a.length !== b.length) return false;
  return crypto.timingSafeEqual(a, b);
}

/**
 * Idempotency key for a delivery. Freemius normally carries a unique event
 * id; if a payload shape lacks one, fall back to the digest of the raw body
 * so a byte-identical redelivery can never double-apply.
 */
export function eventUid(body: Record<string, unknown>, rawBody: string): string {
  const direct = firstString(body, ['id', 'event_id', 'eventUid', 'event_uid']);
  if (direct) return direct;
  return 'sha256:' + crypto.createHash('sha256').update(rawBody, 'utf8').digest('hex');
}

export function firstString(obj: Record<string, unknown>, keys: string[]): string | null {
  for (const k of keys) {
    const v = obj[k];
    if (typeof v === 'string' && v.trim()) return v;
    if (typeof v === 'number') return String(v);
  }
  return null;
}

export function normalizePlanId(value: unknown, fallback: string): string {
  const s = typeof value === 'string' || typeof value === 'number' ? String(value).trim() : '';
  return /^[0-9A-Za-z_-]{1,40}$/.test(s) ? s : fallback;
}

/**
 * Builds the hosted checkout URL for a Takwa plan. Query-parameter names
 * follow the Freemius SaaS app-integration docs; if a dashboard-generated
 * "checkout link" ever disagrees, adjust HERE — this is the single place
 * the URL shape is defined (see docs/freemius-integration.md §Freemius
 * dashboard setup for how to compare).
 */
export function buildCheckoutUrl(
  cfg: FreemiusConfig,
  opts: { planId: string; userEmail?: string; userName?: string; custom?: unknown; locale?: string; webBase: string }
): string {
  const url = new URL(`${CHECKOUT_HOST}/app/${encodeURIComponent(cfg.productId)}/plan/${encodeURIComponent(opts.planId)}/`);
  url.searchParams.set('public_key', cfg.publishableKey);
  if (opts.userEmail) {
    url.searchParams.set('user_email', opts.userEmail);
    // Lock the identity so the entitlement we write after the webhook can
    // always be matched back to this Supabase user.
    url.searchParams.set('readonly_user', 'true');
  }
  if (opts.userName) url.searchParams.set('user_name', opts.userName);
  if (opts.custom) url.searchParams.set('custom', JSON.stringify(opts.custom));
  // Reuse the Chargily hop that bounces https → takwa:// back into the app.
  const locale = opts.locale === 'ar' ? 'ar' : 'en';
  const hop = (target: string) => `${opts.webBase}/${locale}/payment-redirect?to=${encodeURIComponent(target)}`;
  url.searchParams.set('success_url', hop('takwa://payment-success'));
  url.searchParams.set('cancel_url', hop('takwa://payment-failure'));
  return url.toString();
}

/**
 * Customer portal (cancel / renew / update card) link. Freemius exposes a
 * hosted billing portal for the buyer's account; the exact URL shape can
 * move, so it is an env template — `{PRODUCT_ID}`, `{PUBLIC_KEY}` and
 * `{USER_EMAIL}` are substituted. If the dashboard ever shows a different
 * portal URL, change FREEMIUS_PORTAL_URL; no redeploy of code needed.
 */
export function buildPortalUrl(cfg: FreemiusConfig, userEmail?: string): string {
  const template =
    process.env.FREEMIUS_PORTAL_URL ??
    'https://billing.freemius.com/app/{PRODUCT_ID}/account/?public_key={PUBLIC_KEY}';
  return template
    .replace('{PRODUCT_ID}', encodeURIComponent(cfg.productId))
    .replace('{PUBLIC_KEY}', encodeURIComponent(cfg.publishableKey))
    .replace('{USER_EMAIL}', userEmail ? encodeURIComponent(userEmail) : '');
}

let _admin: SupabaseClient | null = null;

/** Service-role client: the only writer of premium_entitlements /
 *  freemius_events, and the only way to resolve a buyer email → user id. */
export function supabaseAdmin(): SupabaseClient {
  const url = process.env.SUPABASE_URL ?? process.env.NEXT_PUBLIC_SUPABASE_URL;
  const key = process.env.SUPABASE_SERVICE_ROLE_KEY;
  if (!url || !key) throw new Error('SUPABASE_URL / SUPABASE_SERVICE_ROLE_KEY not configured');
  if (!_admin) _admin = createClient(url, key, { auth: { persistSession: false, autoRefreshToken: false } });
  return _admin;
}

/**
 * Resolves the caller of a mobile request: the app passes the Supabase
 * access token, we ask Supabase who it belongs to rather than parsing the
 * JWT ourselves (no JWKS dependency in this app).
 */
export async function userFromBearer(authorization: string | null): Promise<{ id: string; email: string | null } | null> {
  const token = authorization?.startsWith('Bearer ') ? authorization.slice('Bearer '.length).trim() : null;
  if (!token) return null;
  const url = process.env.SUPABASE_URL ?? process.env.NEXT_PUBLIC_SUPABASE_URL;
  const anonKey = process.env.SUPABASE_ANON_KEY ?? process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY;
  if (!url || !anonKey) throw new Error('SUPABASE_URL / SUPABASE_ANON_KEY not configured');
  const res = await fetch(`${url}/auth/v1/user`, {
    headers: { Authorization: `Bearer ${token}`, apikey: anonKey },
  });
  if (!res.ok) return null;
  const user = (await res.json().catch(() => null)) as { id?: string; email?: string } | null;
  return user?.id ? { id: user.id, email: user.email ?? null } : null;
}

/** Thin wrapper over api.freemius.com (Bearer secret key). */
export async function freemiusApi(
  cfg: FreemiusConfig,
  path: string,
  init?: RequestInit
): Promise<{ ok: boolean; status: number; json?: Record<string, unknown>; error?: string }> {
  const res = await fetch(`${API_BASE}${path}`, {
    ...init,
    headers: {
      Authorization: `Bearer ${cfg.secretKey}`,
      'Content-Type': 'application/json',
      Accept: 'application/json',
      ...init?.headers,
    },
  });
  if (!res.ok) {
    const body = await res.text().catch(() => '');
    console.error(`[freemius] ${path} failed (${res.status}):`, body.slice(0, 500));
    // Never proxy Freemius' error body to the client — it can echo keys.
    return { ok: false, status: 502, error: 'freemius_request_failed' };
  }
  return { ok: true, status: 200, json: (await res.json()) as Record<string, unknown> };
}

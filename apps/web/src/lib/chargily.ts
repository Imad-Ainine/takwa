/**
 * Server-side Chargily Pay V2 helpers.
 *
 * The CHARGILY_SECRET_KEY lives ONLY here (Vercel env) — never in the
 * mobile client. The app calls /api/payments/checkout, which proxies to
 * Chargily with the secret key attached.
 *
 * Environment variables (server-side only):
 *   CHARGILY_SECRET_KEY          – test_sk_… (sandbox) or sk_… (live)
 *   CHARGILY_SUBSCRIPTION_AMOUNT – monthly amount in whole DZD (default 200)
 *   TAKWA_WEB_BASE_URL           – public base URL of this app; defaults to
 *                                  the incoming request origin
 */

const SUPPORTED_LOCALES = new Set(['ar', 'en', 'fr']);
const SUPPORTED_METHODS = new Set(['edahabia', 'cib']);

/** Chargily picks the endpoint from the key mode; the key prefix tells us which. */
export function chargilyApiBase(secretKey: string): string | null {
  if (secretKey.startsWith('test_')) return 'https://pay.chargily.net/test/api/v2';
  if (secretKey.startsWith('sk_')) return 'https://pay.chargily.net/api/v2';
  return null;
}

/**
 * Chargily hands back `http://pay.chargily.dz/<mode>/checkouts/<id>/pay`.
 * Android Custom Tabs refuse non-https links, and pay.chargily.dz does not
 * complete a TCP handshake from every network — the identical checkout page
 * is served on pay.chargily.net, so normalize before returning to the app.
 */
export function normalizeCheckoutUrl(raw: string): string {
  try {
    const url = new URL(raw);
    if (url.hostname === 'pay.chargily.dz') url.hostname = 'pay.chargily.net';
    if (url.protocol === 'http:') url.protocol = 'https:';
    return url.toString();
  } catch {
    return raw;
  }
}

export function sanitizeLocale(value: unknown): string {
  return typeof value === 'string' && SUPPORTED_LOCALES.has(value) ? value : 'en';
}

export function sanitizePaymentMethod(value: unknown): string {
  return typeof value === 'string' && SUPPORTED_METHODS.has(value) ? value : 'edahabia';
}

export function subscriptionAmountDzd(): number {
  const parsed = Number.parseInt(process.env.CHARGILY_SUBSCRIPTION_AMOUNT ?? '', 10);
  return Number.isFinite(parsed) && parsed > 0 ? parsed : 200;
}

export interface ChargilyCheckoutResponse {
  id: string;
  checkout_url: string;
  status: string;
}

/**
 * Calls Chargily with the secret key and reduces the response to the three
 * fields the mobile client is allowed to see.
 */
export async function chargilyFetch(
  path: string,
  init?: RequestInit
): Promise<{ ok: boolean; status: number; data: ChargilyCheckoutResponse | null; error?: string }> {
  const secret = process.env.CHARGILY_SECRET_KEY;
  if (!secret) {
    return { ok: false, status: 503, data: null, error: 'payments_not_configured' };
  }
  const base = chargilyApiBase(secret);
  if (!base) {
    console.error('[chargily] CHARGILY_SECRET_KEY has an unrecognised prefix (expected test_sk_… or sk_…)');
    return { ok: false, status: 503, data: null, error: 'payments_not_configured' };
  }

  const res = await fetch(`${base}${path}`, {
    ...init,
    headers: {
      Authorization: `Bearer ${secret}`,
      'Content-Type': 'application/json',
      Accept: 'application/json',
      ...init?.headers,
    },
  });

  if (!res.ok) {
    const body = await res.text().catch(() => '');
    console.error(`[chargily] ${path} failed (${res.status}):`, body.slice(0, 500));
    // Do not leak Chargily's error body (it may echo request details) — the
    // mobile client only needs to know the attempt failed.
    return { ok: false, status: 502, data: null, error: 'chargily_request_failed' };
  }

  const json = (await res.json()) as Record<string, unknown>;
  return {
    ok: true,
    status: 200,
    data: {
      id: String(json.id ?? ''),
      checkout_url: normalizeCheckoutUrl(String(json.checkout_url ?? '')),
      status: String(json.status ?? 'pending'),
    },
  };
}

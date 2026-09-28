import { NextRequest, NextResponse } from 'next/server';
import { freemiusApi, freemiusConfig, normalizePlanId, supabaseAdmin, userFromBearer } from '@/lib/freemius';

/**
 * POST /api/payments/freemius/change-plan
 *
 * Upgrades/downgrades an existing Freemius subscription. Freemius exposes
 * this as a checkout-link on the buyer's license, which pre-fills the
 * hosted checkout with proration — the actual entitlement update still
 * arrives through the webhook as `license.plan.changed`, so this route
 * cannot grant anything by itself.
 *
 * Users without a server-side license (Chargily supporters, guests) get
 * 404 no_active_license and the app routes them to a normal new checkout.
 */
export const dynamic = 'force-dynamic';

export async function POST(request: NextRequest) {
  const cfg = freemiusConfig();
  if (!cfg) {
    return NextResponse.json({ error: 'payments_not_configured' }, { status: 503 });
  }

  let user: { id: string; email: string | null } | null = null;
  try {
    user = await userFromBearer(request.headers.get('authorization'));
  } catch {
    return NextResponse.json({ error: 'auth_backend_unavailable' }, { status: 503 });
  }
  if (!user) {
    return NextResponse.json({ error: 'sign_in_required' }, { status: 401 });
  }

  let body: Record<string, unknown> = {};
  try {
    body = (await request.json()) as Record<string, unknown>;
  } catch {
    // Empty body = nothing to change; rejected below.
  }
  const planId = normalizePlanId(body.plan_id, '');
  if (!planId || !cfg.allowedPlanIds.has(planId)) {
    return NextResponse.json({ error: 'plan_not_allowed' }, { status: 400 });
  }

  const db = supabaseAdmin();
  const { data: entitlement } = await db
    .from('premium_entitlements')
    .select('license_id, source')
    .eq('user_id', user.id)
    .maybeSingle();
  if (entitlement?.source !== 'freemius' || !entitlement?.license_id) {
    return NextResponse.json({ error: 'no_active_license' }, { status: 404 });
  }

  const webBase = (process.env.TAKWA_WEB_BASE_URL ?? request.nextUrl.origin).replace(/\/$/, '');
  const locale = body.locale === 'ar' ? 'ar' : 'en';
  const hop = (target: string) => `${webBase}/${locale}/payment-redirect?to=${encodeURIComponent(target)}`;

  const result = await freemiusApi(
    cfg,
    `/products/${encodeURIComponent(cfg.productId)}/licenses/${encodeURIComponent(String(entitlement.license_id))}/checkout/link.json`,
    {
      method: 'POST',
      body: JSON.stringify({
        plan_id: planId,
        public_key: cfg.publishableKey,
        success_url: hop('takwa://payment-success'),
        cancel_url: hop('takwa://payment-failure'),
      }),
    }
  );
  if (!result.ok || !result.json) {
    return NextResponse.json({ error: result.error ?? 'freemius_request_failed' }, { status: result.status });
  }

  // The link endpoint has shipped under a couple of shapes — take whichever
  // field carries the URL instead of guessing one.
  const data = (result.json.data ?? result.json) as Record<string, unknown>;
  const checkoutUrl =
    (typeof data.checkout_url === 'string' && data.checkout_url) ||
    (typeof data.url === 'string' && data.url) ||
    (typeof data.link === 'string' && data.link) ||
    null;
  if (!checkoutUrl || !checkoutUrl.startsWith('https://')) {
    console.error('[freemius] unexpected change-plan link response:', Object.keys(data));
    return NextResponse.json({ error: 'freemius_unexpected_response' }, { status: 502 });
  }
  return NextResponse.json({ checkout_url: checkoutUrl, plan_id: planId });
}

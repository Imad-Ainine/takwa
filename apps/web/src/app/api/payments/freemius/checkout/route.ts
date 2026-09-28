import { NextRequest, NextResponse } from 'next/server';
import {
  buildCheckoutUrl,
  freemiusConfig,
  normalizePlanId,
  userFromBearer,
} from '@/lib/freemius';

/**
 * POST /api/payments/freemius/checkout
 *
 * Creates a Freemius hosted-checkout session for a signed-in Takwa user.
 * The client sends only its Supabase access token — the Freemius keys and
 * the buyer identity (locked with readonly_user) stay server-side, and the
 * echoed `custom.takwa_user_id` is what the webhook uses to attribute the
 * purchase back to this exact account.
 *
 * Body: { plan_id?: string, locale?: 'ar' | 'en' }
 *   plan_id must be one of FREEMIUS_PLAN_IDS (default: monthly plan only),
 *   so the app can never be tricked into charging an attacker-chosen plan.
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
    // Empty body = defaults.
  }

  const planId = normalizePlanId(body.plan_id, cfg.monthlyPlanId);
  if (!cfg.allowedPlanIds.has(planId)) {
    return NextResponse.json({ error: 'plan_not_allowed' }, { status: 400 });
  }
  const locale = body.locale === 'ar' ? 'ar' : 'en';

  const webBase = (process.env.TAKWA_WEB_BASE_URL ?? request.nextUrl.origin).replace(/\/$/, '');
  const checkoutUrl = buildCheckoutUrl(cfg, {
    planId,
    userEmail: user.email ?? undefined,
    custom: { takwa_user_id: user.id },
    locale,
    webBase,
  });

  return NextResponse.json({ checkout_url: checkoutUrl, plan_id: planId });
}

import { NextRequest, NextResponse } from 'next/server';
import { buildPortalUrl, freemiusConfig, userFromBearer } from '@/lib/freemius';

/**
 * POST /api/payments/freemius/portal
 *
 * Returns the Freemius customer-portal URL for the signed-in user, where
 * they cancel, resume, or change the card behind their subscription. The
 * app never gets the publishable/secret keys — same proxy rule as checkout.
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

  return NextResponse.json({ portal_url: buildPortalUrl(cfg, user.email ?? undefined) });
}

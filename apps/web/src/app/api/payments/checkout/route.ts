import { NextRequest, NextResponse } from 'next/server';
import {
  chargilyFetch,
  sanitizeLocale,
  sanitizePaymentMethod,
  subscriptionAmountDzd,
} from '@/lib/chargily';

/**
 * POST /api/payments/checkout
 *
 * Creates a Chargily Pay V2 checkout on behalf of the mobile app, which no
 * longer ships the Chargily secret key. The server — not the client — owns
 * the amount and the success/failure redirect URLs (built from a whitelisted
 * locale), so the endpoint cannot be used to craft arbitrary-amount or
 * open-redirect checkouts.
 *
 * Body (all optional, all validated):
 *   payment_method – "edahabia" (default) or "cib"
 *   locale         – "ar" | "en" | "fr" (default "en")
 *   description    – text shown on the hosted page (truncated to 200 chars)
 */
export const dynamic = 'force-dynamic';

export async function POST(request: NextRequest) {
  let body: Record<string, unknown> = {};
  try {
    body = (await request.json()) as Record<string, unknown>;
  } catch {
    // An empty/invalid body just means "use defaults".
  }

  const locale = sanitizeLocale(body.locale);
  const paymentMethod = sanitizePaymentMethod(body.payment_method);
  const description =
    typeof body.description === 'string' && body.description.trim()
      ? body.description.trim().slice(0, 200)
      : undefined;

  const webBase = (process.env.TAKWA_WEB_BASE_URL ?? request.nextUrl.origin).replace(/\/$/, '');
  const redirectUrl = (appSchemeUrl: string) =>
    `${webBase}/${locale}/payment-redirect?to=${encodeURIComponent(appSchemeUrl)}`;

  const result = await chargilyFetch('/checkouts', {
    method: 'POST',
    body: JSON.stringify({
      amount: subscriptionAmountDzd(),
      currency: 'dzd',
      payment_method: paymentMethod,
      ...(description ? { description } : {}),
      success_url: redirectUrl('takwa://payment-success'),
      failure_url: redirectUrl('takwa://payment-failure'),
      locale,
      metadata: { source: 'takwa-mobile' },
    }),
  });

  if (!result.ok || !result.data) {
    return NextResponse.json({ error: result.error ?? 'checkout_failed' }, { status: result.status });
  }
  return NextResponse.json(result.data);
}

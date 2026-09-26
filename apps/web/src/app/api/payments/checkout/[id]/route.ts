import { NextRequest, NextResponse } from 'next/server';
import { chargilyFetch } from '@/lib/chargily';

/**
 * GET /api/payments/checkout/{id}
 *
 * Proxies the Chargily checkout-status read so the mobile app can verify a
 * payment without holding the secret key. A redirect back from the hosted
 * page is never treated as proof of payment — the app polls this until the
 * status leaves pending/processing.
 */
export const dynamic = 'force-dynamic';

export async function GET(
  _request: NextRequest,
  { params }: { params: Promise<{ id: string }> }
) {
  const { id } = await params;

  // The id is embedded in an outbound URL path segment — restrict it to the
  // charset Chargily ids use before it reaches fetch().
  if (!/^[A-Za-z0-9_-]{1,64}$/.test(id)) {
    return NextResponse.json({ error: 'invalid_checkout_id' }, { status: 400 });
  }

  const result = await chargilyFetch(`/checkouts/${id}`);
  if (!result.ok || !result.data) {
    return NextResponse.json({ error: result.error ?? 'checkout_lookup_failed' }, { status: result.status });
  }
  return NextResponse.json(result.data);
}

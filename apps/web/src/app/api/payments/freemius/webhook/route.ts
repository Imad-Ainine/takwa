import { NextRequest, NextResponse } from 'next/server';
import { freemiusConfig, verifyWebhookSignature } from '@/lib/freemius';
import { processFreemiusBody } from '@/lib/freemius-db';

/**
 * POST /api/payments/freemius/webhook — Freemius SaaS real-time updates.
 *
 * Freemius POSTs every license/payment event here with an HMAC-SHA256
 * `x-signature` over the raw body. We verify, log (idempotent via the
 * unique event uid), and fold the event into premium_entitlements.
 *
 * Retry policy: anything the handler understands but cannot apply (e.g.
 * buyer email matched to no account yet) answers 200 anyway — the event is
 * stored `failed` and /reconcile retries it later. Only a storage outage
 * answers 5xx, so Freemius redelivers without hammering on permanent
 * business failures.
 */
export const dynamic = 'force-dynamic';

export async function POST(request: NextRequest) {
  const cfg = freemiusConfig();
  if (!cfg) {
    return NextResponse.json({ error: 'payments_not_configured' }, { status: 503 });
  }

  const raw = await request.text();
  if (!verifyWebhookSignature(raw, request.headers.get('x-signature'), cfg.secretKey)) {
    return NextResponse.json({ error: 'invalid_signature' }, { status: 401 });
  }

  let body: Record<string, unknown>;
  try {
    body = JSON.parse(raw) as Record<string, unknown>;
  } catch {
    // Never retryable — tell Freemius it landed so it stops redelivering.
    return NextResponse.json({ error: 'invalid_json' }, { status: 400 });
  }

  const result = await processFreemiusBody(raw, body);
  if (result.outcome === 'failed' && result.detail === 'event_log_insert_failed') {
    return NextResponse.json({ error: 'storage_unavailable' }, { status: 500 });
  }
  return NextResponse.json({ ok: true, outcome: result.outcome });
}

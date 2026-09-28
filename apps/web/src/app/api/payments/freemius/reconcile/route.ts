import { NextRequest, NextResponse } from 'next/server';
import { secretsMatch, supabaseAdmin } from '@/lib/freemius';
import { processStoredEvent } from '@/lib/freemius-db';

/**
 * POST /api/payments/freemius/reconcile
 *
 * Retries every freemius_events row that is still `received`/`failed`
 * (storage outage at delivery time, buyer email that matched no account
 * then but does now, out-of-order guard false-positives after a fix).
 *
 * Protected by the TAKWA_ADMIN_SECRET shared header — not user-callable.
 * Intended for manual ops runs and, optionally, a Vercel Cron (see
 * docs/freemius-integration.md §Operational troubleshooting).
 */
export const dynamic = 'force-dynamic';

export async function POST(request: NextRequest) {
  if (!secretsMatch(request.headers.get('x-takwa-admin-secret'), process.env.TAKWA_ADMIN_SECRET)) {
    return NextResponse.json({ error: 'unauthorized' }, { status: 401 });
  }

  const db = supabaseAdmin();
  const { data: pending, error } = await db
    .from('freemius_events')
    .select('id, payload')
    .in('apply_status', ['received', 'failed'])
    .order('id', { ascending: true })
    .limit(100);
  if (error) {
    return NextResponse.json({ error: 'event_query_failed' }, { status: 500 });
  }

  const summary = { processed: 0, applied: 0, ignored: 0, failed: 0 };
  for (const row of pending ?? []) {
    summary.processed += 1;
    const result = await processStoredEvent(row as { id: number; payload: Record<string, unknown> });
    if (result.outcome === 'applied') summary.applied += 1;
    else if (result.outcome === 'ignored') summary.ignored += 1;
    else summary.failed += 1;
  }
  return NextResponse.json({ ok: true, ...summary });
}

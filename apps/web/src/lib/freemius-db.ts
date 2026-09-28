/**
 * Freemius webhook → database application layer, shared by the webhook
 * route and the reconcile endpoint.
 *
 * Contract: EVERY delivered body is logged in freemius_events first (audit
 * trail + idempotency), only then applied to premium_entitlements. Anything
 * we cannot apply lands as `failed` with a reason, so reconcile can retry
 * after the missing precondition exists (e.g. buyer created their Supabase
 * account only after subscribing).
 */

import type { SupabaseClient } from '@supabase/supabase-js';
import { eventUid, firstString, supabaseAdmin } from './freemius.ts';
import { normalizeFreemiusEvent, deriveEntitlement, type NormalizedEvent, type EntitlementPatch } from './freemius-events.ts';

export interface ProcessResult {
  outcome: 'applied' | 'ignored' | 'failed' | 'duplicate';
  eventRowId?: number;
  detail?: string;
}

/** Parse → log (idempotent) → derive → resolve user → upsert entitlement. */
export async function processFreemiusBody(rawBody: string, body: Record<string, unknown>): Promise<ProcessResult> {
  const db = supabaseAdmin();
  const evt = normalizeFreemiusEvent(body);
  const uid = eventUid(body, rawBody);

  const { data: inserted, error: insertError } = await db
    .from('freemius_events')
    .upsert(
      {
        event_uid: uid,
        event_type: evt?.type ?? 'unknown',
        freemius_user_id: evt ? firstString(evt.user ?? {}, ['id']) ?? null : null,
        license_id: evt?.license ? firstString(evt.license, ['id']) ?? null : null,
        subscription_id: evt?.subscription ? firstString(evt.subscription, ['id']) ?? (evt.license ? firstString(evt.license, ['subscription_id']) : null) ?? null : null,
        payload: body,
      },
      { onConflict: 'event_uid', ignoreDuplicates: true }
    )
    .select('id');
  if (insertError) {
    console.error('[freemius] event log insert failed:', insertError.message);
    return { outcome: 'failed', detail: 'event_log_insert_failed' };
  }
  // ignoreDuplicates: an empty return means this exact delivery was seen before.
  const eventRowId = inserted?.[0]?.id as number | undefined;
  if (eventRowId === undefined) return { outcome: 'duplicate' };
  if (!evt) return finish(db, eventRowId, 'ignored', 'unrecognized_event_body');

  const derived = deriveEntitlement(evt, new Date());
  if ('ignore' in derived) return finish(db, eventRowId, 'ignored', derived.ignore);

  return applyToUser(db, evt, derived.patch, eventRowId);
}

/**
 * Resolve the Supabase owner of a derived patch and fold it into
 * premium_entitlements, guarding against out-of-order delivery. Shared by
 * the live webhook path and the reconcile retry path.
 */
async function applyToUser(
  db: SupabaseClient,
  evt: NormalizedEvent,
  patch: EntitlementPatch,
  eventRowId: number
): Promise<ProcessResult> {
  const userId = await resolveUserId(evt, patch.email);
  if (!userId) return finish(db, eventRowId, 'failed', 'no_matching_supabase_user');

  // Out-of-order guard: never let an older delivery overwrite a newer one.
  const { data: existing } = await db
    .from('premium_entitlements')
    .select('*')
    .eq('user_id', userId)
    .maybeSingle();
  if (existing?.last_event_id != null && Number(existing.last_event_id) >= eventRowId) {
    return finish(db, eventRowId, 'ignored', 'older_than_applied_event');
  }

  const row = {
    user_id: userId,
    source: 'freemius',
    status: patch.status,
    plan_id: patch.plan_id ?? existing?.plan_id ?? null,
    plan_title: patch.plan_title ?? existing?.plan_title ?? null,
    is_trial: patch.is_trial,
    cancel_at_period_end: patch.cancel_at_period_end,
    current_period_end: patch.current_period_end ?? existing?.current_period_end ?? null,
    email: patch.email ?? existing?.email ?? null,
    freemius_user_id: patch.freemius_user_id ?? existing?.freemius_user_id ?? null,
    license_id: patch.license_id ?? existing?.license_id ?? null,
    subscription_id: patch.subscription_id ?? existing?.subscription_id ?? null,
    last_event_id: eventRowId,
  };
  const { error: upsertError } = await db.from('premium_entitlements').upsert(row, { onConflict: 'user_id' });
  if (upsertError) {
    console.error('[freemius] entitlement upsert failed:', upsertError.message);
    return finish(db, eventRowId, 'failed', `entitlement_upsert_failed: ${upsertError.message}`);
  }
  return finish(db, eventRowId, 'applied');
}

/** Retry a previously stored event (used by /reconcile), e.g. an email that
 *  belonged to no account when it first arrived but does now. */
export async function processStoredEvent(eventRow: { id: number; payload: Record<string, unknown> }): Promise<ProcessResult> {
  const db = supabaseAdmin();
  const evt = normalizeFreemiusEvent(eventRow.payload);
  if (!evt) return { outcome: 'ignored', detail: 'unrecognized_event_body' };
  const derived = deriveEntitlement(evt, new Date());
  if ('ignore' in derived) return { outcome: 'ignored', detail: derived.ignore };
  return applyToUser(db, evt, derived.patch, eventRow.id);
}

/**
 * Prefer the takwa_user_id echoed via the checkout `custom` param — it is
 * exact. In practice Freemius' hosted checkout never echoes it: none of the
 * six events delivered by a real 2026-09-28 subscription carried a `custom`
 * key at all, so the email match below is the live attribution path. It is
 * safe because the checkout locks `readonly_user=true` to the signed-in
 * account's verified email.
 *
 * GoTrue's /auth/v1/admin/users has no email filter: an `?email=` param is
 * ignored and the call answers with the newest-first, unfiltered page.
 * Paging and matching here is therefore mandatory — reading `users[0]`
 * silently grants the entitlement to whoever signed up last.
 */
const USER_PAGE_SIZE = 1000;
const MAX_USER_PAGES = 20;

export async function findUserIdByEmail(email: string): Promise<string | null> {
  const url = process.env.SUPABASE_URL ?? process.env.NEXT_PUBLIC_SUPABASE_URL;
  const serviceKey = process.env.SUPABASE_SERVICE_ROLE_KEY;
  if (!url || !serviceKey) return null;
  const wanted = email.trim().toLowerCase();
  try {
    for (let page = 1; page <= MAX_USER_PAGES; page++) {
      const res = await fetch(
        `${url}/auth/v1/admin/users?page=${page}&per_page=${USER_PAGE_SIZE}`,
        { headers: { Authorization: `Bearer ${serviceKey}`, apikey: serviceKey } }
      );
      if (!res.ok) return null;
      const json = (await res.json()) as { users?: Array<{ id?: string; email?: string }> };
      const users = json.users ?? [];
      // GoTrue stores emails lowercased and enforces uniqueness, so the
      // first exact match is the only one.
      for (const u of users) {
        if (u.id && u.email?.trim().toLowerCase() === wanted) return u.id;
      }
      if (users.length < USER_PAGE_SIZE) return null;
    }
    return null;
  } catch {
    return null;
  }
}

async function resolveUserId(evt: NormalizedEvent, email: string | null): Promise<string | null> {
  if (evt.takwaUserId && /^[0-9a-fA-F-]{36}$/.test(evt.takwaUserId)) return evt.takwaUserId;
  if (!email) return null;
  return findUserIdByEmail(email);
}

async function finish(db: SupabaseClient, eventRowId: number, status: 'applied' | 'ignored' | 'failed', detail?: string): Promise<ProcessResult> {
  await db
    .from('freemius_events')
    .update({ apply_status: status, apply_error: detail ?? null, processed_at: new Date().toISOString() })
    .eq('id', eventRowId);
  return { outcome: status, eventRowId, detail };
}

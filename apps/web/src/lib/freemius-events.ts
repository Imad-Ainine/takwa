/**
 * Freemius webhook event interpretation — PURE functions only (no env, no
 * I/O, no imports) so they can be unit-tested with `node --test` directly
 * against recorded payloads. The route in app/api/payments/freemius/webhook
 * wires these to Supabase; all field-name tolerance lives here.
 *
 * Freemius has shipped webhook bodies under a couple of shapes over time
 * ({type, objects:{...}} and {event, payload:{...}}, dots or underscores in
 * the event name), and SaaS payloads carry the checkout `custom` echo on
 * the payment. Normalization accepts every variant; the integration doc
 * shows how to compare against a live test payload.
 */

type Dict = Record<string, unknown>;

const asDict = (v: unknown): Dict | null => (typeof v === 'object' && v !== null ? (v as Dict) : null);

function pick(obj: Dict | null, ...keys: string[]): unknown {
  if (!obj) return undefined;
  for (const k of keys) {
    const v = obj[k];
    if (v !== undefined && v !== null && v !== '') return v;
  }
  return undefined;
}

function pickString(obj: Dict | null, ...keys: string[]): string | null {
  const v = pick(obj, ...keys);
  if (typeof v === 'string' && v.trim()) return v;
  if (typeof v === 'number') return String(v);
  return null;
}

function pickBool(obj: Dict | null, ...keys: string[]): boolean | null {
  const v = pick(obj, ...keys);
  if (typeof v === 'boolean') return v;
  if (v === 'true') return true;
  if (v === 'false') return false;
  if (typeof v === 'number') return v === 1 ? true : v === 0 ? false : null;
  return null;
}

/** Freemius timestamps are unix seconds (often as decimal strings). */
export function parseFsDate(value: unknown): Date | null {
  if (value == null || value === '') return null;
  if (typeof value === 'number' || /^\d+(\.\d+)?$/.test(String(value))) {
    return new Date(Math.round(Number(value) * 1000));
  }
  const d = new Date(String(value));
  return Number.isNaN(d.getTime()) ? null : d;
}

/** Freemius echoes the checkout `custom` param back on the payment —
 *  as an object in some payload shapes, a JSON string in others. */
function asDictLoose(value: unknown): Dict | null {
  if (typeof value === 'string') {
    try {
      return asDict(JSON.parse(value));
    } catch {
      return null;
    }
  }
  return asDict(value);
}

export interface NormalizedEvent {
  type: string; // dotted lowercase, e.g. "license.updated"
  takwaUserId: string | null; // echoed checkout `custom`
  license: Dict | null;
  payment: Dict | null;
  subscription: Dict | null;
  user: Dict | null;
}

export function normalizeFreemiusEvent(body: Dict): NormalizedEvent | null {
  const rawType = pickString(body, 'type', 'event', 'name');
  if (!rawType) return null;
  const type = rawType.toLowerCase().replace(/_/g, '.');
  const content = asDict(pick(body, 'objects', 'payload', 'data', 'content')) ?? body;
  const license = asDict(pick(content, 'license', 'licence'));
  const payment = asDict(pick(content, 'payment', 'payments'));
  const subscription = asDict(pick(content, 'subscription'));
  const user = asDict(pick(content, 'user'));
  // Kept as the exact fast path, but the hosted checkout has never actually
  // echoed `custom` in a delivered event — see findUserIdByEmail in
  // freemius-db.ts, which is the attribution path in production.
  const custom =
    asDictLoose(pick(payment, 'custom')) ??
    asDictLoose(pick(license, 'custom')) ??
    asDictLoose(pick(content, 'custom'));
  const takwaUserId = pickString(custom, 'takwa_user_id', 'takwaUserId');
  return { type, takwaUserId, license, payment, subscription, user };
}

export type EntitlementStatus = 'trial' | 'active' | 'past_due' | 'canceled' | 'expired' | 'refunded';

export interface EntitlementPatch {
  status: EntitlementStatus;
  plan_id: string | null;
  plan_title: string | null;
  is_trial: boolean;
  cancel_at_period_end: boolean;
  current_period_end: string | null; // ISO
  email: string | null;
  freemius_user_id: string | null;
  license_id: string | null;
  subscription_id: string | null;
}

const REFUNDED_PAYMENT_STATUSES = new Set(['refunded', 'charged_back', 'chargeback', 'fraudulent']);
const PENDING_PAYMENT_STATUSES = new Set(['pending', 'failed', 'paused', 'incomplete', 'retry', 'scheduled']);

/**
 * Decide the entitlement state implied by one event. Returns `ignore`
 * (with a reason for the event log) for events that carry no entitlement
 * information (e.g. the dashboard "connection test" ping, install events).
 *
 * Precedence: refund/chargeback > expired > canceled (access may continue
 * to the paid period end) > trial > pending/failed renewal (past_due grace)
 * > active. `past_due` keeps access until current_period_end passes, which
 * is what the client's isPremiumActive check enforces.
 */
export function deriveEntitlement(evt: NormalizedEvent, now: Date): { patch: EntitlementPatch } | { ignore: string } {
  const { type, license, payment, subscription, user } = evt;

  const paymentStatus = (pickString(payment, 'status') ?? '').toLowerCase();
  const licenseStatus = (pickString(license, 'status', 'is_active') ?? '').toLowerCase();
  const expires =
    parseFsDate(pick(payment, 'expires', 'expiration')) ??
    parseFsDate(pick(license, 'expires', 'expiration')) ??
    parseFsDate(pick(subscription, 'expires', 'next_payment', 'trial_ends'));
  // `next_payment` in the FUTURE means the period currently runs until it.
  const nextPayment = parseFsDate(pick(payment, 'next_payment', 'renewal_date'));
  const periodEnd = nextPayment && nextPayment > now ? nextPayment : expires;

  const isTrial =
    (pickBool(payment, 'is_trial') ?? pickBool(license, 'is_trial') ?? false) ||
    paymentStatus === 'trial' ||
    type.includes('trial');

  const cancelRequested =
    type.includes('cancel') ||
    (pickBool(payment, 'is_cancelled', 'cancelled', 'cancel_at_period_end') ?? false) ||
    (pickBool(subscription, 'cancel_at_period_end', 'is_cancelled', 'cancelled') ?? false) ||
    licenseStatus === 'canceled' ||
    licenseStatus === 'cancelled';

  if (!license && !payment && !subscription && !user) {
    return { ignore: `event "${type}" carries no entitlement objects` };
  }

  let status: EntitlementStatus;
  if (REFUNDED_PAYMENT_STATUSES.has(paymentStatus) || type.includes('refund') || type.includes('chargeback')) {
    status = 'refunded';
  } else if (type.includes('expired') || (expires && expires <= now && !cancelRequested)) {
    status = 'expired';
  } else if (cancelRequested) {
    // Cancellation before period end keeps access; after it, expiry wins.
    status = periodEnd && periodEnd > now ? 'canceled' : 'expired';
  } else if (PENDING_PAYMENT_STATUSES.has(paymentStatus) || type.includes('past_due') || type.includes('payment_failed')) {
    status = 'past_due';
  } else if (isTrial) {
    status = 'trial';
  } else {
    status = 'active';
  }

  const email = pickString(user, 'email') ?? pickString(payment, 'payer_email');

  return {
    patch: {
      status,
      plan_id: pickString(license, 'plan_id', 'planId') ?? pickString(payment, 'plan_id'),
      plan_title: pickString(license, 'plan_title') ?? pickString(payment, 'plan_title'),
      is_trial: status === 'trial',
      cancel_at_period_end: cancelRequested && status === 'canceled',
      current_period_end: periodEnd ? periodEnd.toISOString() : null,
      email: email ? email.toLowerCase() : null,
      freemius_user_id: pickString(user, 'id') ?? pickString(license, 'user_id'),
      license_id: pickString(license, 'id'),
      subscription_id: pickString(subscription, 'id') ?? pickString(license, 'subscription_id') ?? pickString(payment, 'subscription_id'),
    },
  };
}

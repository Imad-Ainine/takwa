import { test } from 'node:test';
import assert from 'node:assert/strict';
import { normalizeFreemiusEvent, deriveEntitlement, parseFsDate } from './freemius-events.ts';

const NOW = new Date('2026-09-28T12:00:00Z');
const fsTs = (d: Date) => String(Math.floor(d.getTime() / 1000));
const FUTURE = fsTs(new Date('2026-10-15T00:00:00Z'));
const PAST = fsTs(new Date('2026-09-01T00:00:00Z'));
const USER_ID = '2f8fb4a6-0000-4000-8000-000000000001';

test('normalizes the {type, objects} shape with dotted event names', () => {
  const evt = normalizeFreemiusEvent({
    type: 'license.created',
    objects: {
      user: { id: 77, email: 'A@B.com' },
      license: { id: '10', plan_id: '42', expires: FUTURE },
      payment: { id: '9', status: 'Paid', custom: `{"takwa_user_id":"${USER_ID}"}` },
    },
  });
  assert.ok(evt);
  assert.equal(evt.type, 'license.created');
  assert.equal(evt.takwaUserId, USER_ID); // custom echoed as JSON string
  assert.equal(evt.user?.email, 'A@B.com'); // raw user object, lowercasing happens in derive
});

test('normalizes the {event, payload} shape with underscores and object custom', () => {
  const evt = normalizeFreemiusEvent({
    event: 'license_updated',
    payload: {
      license: { id: '10', plan_id: '42' },
      payment: { status: 'PAID', custom: { takwa_user_id: USER_ID } },
    },
  });
  assert.ok(evt);
  assert.equal(evt.type, 'license.updated');
  assert.equal(evt.takwaUserId, USER_ID);
});

test('bodies without a type normalize to null', () => {
  assert.equal(normalizeFreemiusEvent({ data: {} }), null);
});

test('paid license.created derives an active entitlement', () => {
  const evt = normalizeFreemiusEvent({
    type: 'license.created',
    objects: {
      user: { id: '77', email: 'Supporter@Example.org' },
      license: { id: '10', plan_id: '42', expires: FUTURE },
      payment: { id: '9', status: 'Paid', is_trial: false, next_payment: FUTURE },
    },
  })!;
  const derived = deriveEntitlement(evt, NOW);
  assert.ok('patch' in derived);
  const p = derived.patch;
  assert.equal(p.status, 'active');
  assert.equal(p.license_id, '10');
  assert.equal(p.plan_id, '42');
  assert.equal(p.email, 'supporter@example.org');
  assert.equal(p.current_period_end, new Date(Number(FUTURE) * 1000).toISOString());
});

test('trial payments derive trial status', () => {
  const evt = normalizeFreemiusEvent({
    type: 'payment.created',
    objects: {
      payment: { status: 'trial', is_trial: true, expires: FUTURE },
      license: { id: '11' },
    },
  })!;
  const derived = deriveEntitlement(evt, NOW);
  assert.ok('patch' in derived);
  assert.equal(derived.patch.status, 'trial');
  assert.equal(derived.patch.is_trial, true);
});

test('cancellation before period end keeps access and flags cancel_at_period_end', () => {
  const evt = normalizeFreemiusEvent({
    type: 'license.cancelled',
    objects: {
      license: { id: '10', expires: FUTURE },
      payment: { status: 'Paid', is_cancelled: true },
    },
  })!;
  const derived = deriveEntitlement(evt, NOW);
  assert.ok('patch' in derived);
  assert.equal(derived.patch.status, 'canceled');
  assert.equal(derived.patch.cancel_at_period_end, true);
});

test('cancellation after the paid period derives expired', () => {
  const evt = normalizeFreemiusEvent({
    type: 'license.cancelled',
    objects: { license: { id: '10', expires: PAST }, payment: { is_cancelled: true } },
  })!;
  const derived = deriveEntitlement(evt, NOW);
  assert.ok('patch' in derived);
  assert.equal(derived.patch.status, 'expired');
});

test('refunds and chargebacks revoke access', () => {
  for (const status of ['Refunded', 'Charged_back']) {
    const evt = normalizeFreemiusEvent({
      type: 'payment.updated',
      objects: { payment: { status, expires: FUTURE }, license: { id: '10' } },
    })!;
    const derived = deriveEntitlement(evt, NOW);
    assert.ok('patch' in derived);
    assert.equal(derived.patch.status, 'refunded', status);
  }
});

test('failed renewal (pending) derives past_due, not revoked', () => {
  const evt = normalizeFreemiusEvent({
    type: 'payment.created',
    objects: { payment: { status: 'Pending', expires: FUTURE }, license: { id: '10' } },
  })!;
  const derived = deriveEntitlement(evt, NOW);
  assert.ok('patch' in derived);
  assert.equal(derived.patch.status, 'past_due');
});

test('expiry events with a lapsed date derive expired', () => {
  const evt = normalizeFreemiusEvent({
    type: 'license.expired',
    objects: { license: { id: '10', expires: PAST } },
  })!;
  const derived = deriveEntitlement(evt, NOW);
  assert.ok('patch' in derived);
  assert.equal(derived.patch.status, 'expired');
});

test('plan-change events carry the new plan id', () => {
  const evt = normalizeFreemiusEvent({
    type: 'license.plan.changed',
    objects: {
      license: { id: '10', plan_id: '43', expires: FUTURE },
      payment: { status: 'Paid' },
    },
  })!;
  const derived = deriveEntitlement(evt, NOW);
  assert.ok('patch' in derived);
  assert.equal(derived.patch.status, 'active');
  assert.equal(derived.patch.plan_id, '43');
});

test('connection-test pings are ignored, not applied', () => {
  const evt = normalizeFreemiusEvent({ type: 'ping' })!;
  const derived = deriveEntitlement(evt, NOW);
  assert.ok('ignore' in derived);
});

test('parseFsDate accepts unix seconds (string/number), ISO, and rejects junk', () => {
  assert.deepEqual(parseFsDate(FUTURE), new Date(Number(FUTURE) * 1000));
  assert.deepEqual(parseFsDate(Number(FUTURE)), new Date(Number(FUTURE) * 1000));
  assert.deepEqual(parseFsDate('2026-10-15T00:00:00Z'), new Date('2026-10-15T00:00:00Z'));
  assert.equal(parseFsDate(''), null);
  assert.equal(parseFsDate('not a date'), null);
});

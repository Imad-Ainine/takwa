import { test } from 'node:test';
import assert from 'node:assert/strict';
import { createHmac } from 'node:crypto';
import {
  buildCheckoutUrl,
  eventUid,
  normalizePlanId,
  secretsMatch,
  verifyWebhookSignature,
  type FreemiusConfig,
} from './freemius.ts';

const SECRET = 'sk_test_0123456789';
const cfg: FreemiusConfig = {
  productId: '1234',
  publishableKey: 'pk_test_abc',
  secretKey: SECRET,
  monthlyPlanId: '42',
  allowedPlanIds: new Set(['42', '43']),
};

const sign = (body: string) => createHmac('sha256', SECRET).update(body, 'utf8').digest('hex');

test('valid x-signature passes verification', () => {
  const body = JSON.stringify({ type: 'license.created' });
  assert.equal(verifyWebhookSignature(body, sign(body), SECRET), true);
});

test('tampered body, wrong secret, missing or malformed header all fail', () => {
  const body = '{"type":"license.created"}';
  const good = sign(body);
  assert.equal(verifyWebhookSignature(body + 'x', good, SECRET), false);
  assert.equal(verifyWebhookSignature(body, good, 'sk_other'), false);
  assert.equal(verifyWebhookSignature(body, null, SECRET), false);
  assert.equal(verifyWebhookSignature(body, 'zzz', SECRET), false);
  // A short-but-hex signature must not crash timingSafeEqual's length assert.
  assert.equal(verifyWebhookSignature(body, 'abcd', SECRET), false);
  assert.equal(verifyWebhookSignature('', good, SECRET), false);
});

test('eventUid prefers the payload event id and falls back to a body digest', () => {
  assert.equal(eventUid({ id: '9001' }, '{"id":"9001"}'), '9001');
  assert.equal(eventUid({ id: 9001 }, 'x'), '9001');
  const a = eventUid({}, 'same-body');
  const b = eventUid({}, 'same-body');
  const c = eventUid({}, 'other-body');
  assert.match(a, /^sha256:/);
  assert.equal(a, b);
  assert.notEqual(a, c);
});

test('buildCheckoutUrl targets the SaaS app checkout with locked identity', () => {
  const url = buildCheckoutUrl(cfg, {
    planId: '42',
    userEmail: 'me@example.com',
    custom: { takwa_user_id: 'uid-1' },
    locale: 'ar',
    webBase: 'https://takwa-web.vercel.app',
  });
  const parsed = new URL(url);
  assert.equal(parsed.origin, 'https://checkout.freemius.com');
  assert.equal(parsed.pathname, '/app/1234/plan/42/');
  assert.equal(parsed.searchParams.get('public_key'), 'pk_test_abc');
  assert.equal(parsed.searchParams.get('user_email'), 'me@example.com');
  assert.equal(parsed.searchParams.get('readonly_user'), 'true');
  assert.deepEqual(JSON.parse(parsed.searchParams.get('custom')!), { takwa_user_id: 'uid-1' });
  // Redirect hop must come back through our own https relay (takwa:// only
  // exists as a custom scheme, which hosted checkouts refuse).
  const success = new URL(parsed.searchParams.get('success_url')!);
  assert.equal(success.origin, 'https://takwa-web.vercel.app');
  assert.equal(success.pathname, '/ar/payment-redirect');
  assert.equal(success.searchParams.get('to'), 'takwa://payment-success');
  assert.match(parsed.searchParams.get('cancel_url')!, /payment-failure/);
});

test('normalizePlanId keeps slug-like ids and rejects anything else', () => {
  assert.equal(normalizePlanId('43', '42'), '43');
  assert.equal(normalizePlanId(43, '42'), '43');
  assert.equal(normalizePlanId('43/../evil', '42'), '42');
  assert.equal(normalizePlanId(undefined, '42'), '42');
});

test('secretsMatch is constant-time-ish and null-safe', () => {
  assert.equal(secretsMatch('abc', 'abc'), true);
  assert.equal(secretsMatch('abc', 'abd'), false);
  assert.equal(secretsMatch('abc', undefined), false);
  assert.equal(secretsMatch(null, 'abc'), false);
});

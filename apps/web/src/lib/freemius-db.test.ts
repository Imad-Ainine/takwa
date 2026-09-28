import { test } from 'node:test';
import assert from 'node:assert/strict';
import { findUserIdByEmail } from './freemius-db.ts';

process.env.SUPABASE_URL = 'https://example.supabase.co';
process.env.SUPABASE_SERVICE_ROLE_KEY = 'service-role-key';

const PAGES = 1000;

/** Serve `pages` newest-first chunks; the GoTrue admin list has no email filter. */
function stubUsers(pages: Array<Array<{ id: string; email?: string }>>) {
  const calls: string[] = [];
  globalThis.fetch = (async (input: string) => {
    calls.push(String(input));
    const page = new URL(String(input)).searchParams.get('page');
    const index = Number(page) - 1;
    const users = pages[index] ?? [];
    return { ok: true, json: async () => ({ users }) } as Response;
  }) as typeof fetch;
  return calls;
}

test('matches the buyer email anywhere in the page instead of taking users[0]', async () => {
  const newest = { id: 'aaaaaaaa-0000-0000-0000-000000000001', email: 'sentagodimail@gmail.com' };
  const buyer = { id: 'db47a3d4-e4ce-4146-b7a8-4c93fba5fc13', email: 'imad.ainine11@gmail.com' };
  const calls = stubUsers([[newest, buyer], []]);

  assert.equal(await findUserIdByEmail('imad.ainine11@gmail.com'), buyer.id);
  assert.equal(calls.length, 1, 'a short page ends the scan');
});

test('returns null when no account has that email', async () => {
  const calls = stubUsers([
    [{ id: 'u1', email: 'someone@example.com' }],
  ]);
  assert.equal(await findUserIdByEmail('stranger@example.com'), null);
  assert.equal(calls.length, 1);
});

test('keeps paging through a full first page', async () => {
  const buyer = { id: 'buyer-id', email: 'buyer@example.com' };
  const fullPage = Array.from({ length: PAGES }, (_, i) => ({ id: `u${i}`, email: `u${i}@example.com` }));
  const calls = stubUsers([fullPage, [buyer]]);

  assert.equal(await findUserIdByEmail('buyer@example.com'), 'buyer-id');
  assert.equal(calls.length, 2);
});

test('email comparison ignores case and surrounding spaces', async () => {
  stubUsers([[{ id: 'x', email: 'Buyer@Example.com ' }]]);
  assert.equal(await findUserIdByEmail('  BUYER@example.com'), 'x');
});

test('a non-2xx GoTrue response yields null, never a guess', async () => {
  globalThis.fetch = (async () => ({ ok: false, status: 500, json: async () => ({}) }) as Response) as typeof fetch;
  assert.equal(await findUserIdByEmail('buyer@example.com'), null);
});

test('missing service-role env short-circuits without a request', async () => {
  delete process.env.SUPABASE_SERVICE_ROLE_KEY;
  let called = 0;
  globalThis.fetch = (async () => {
    called += 1;
    return { ok: true, json: async () => ({ users: [] }) } as Response;
  }) as typeof fetch;
  assert.equal(await findUserIdByEmail('buyer@example.com'), null);
  assert.equal(called, 0);
  process.env.SUPABASE_SERVICE_ROLE_KEY = 'service-role-key';
});

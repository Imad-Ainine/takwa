import { createServerClient } from '@supabase/ssr';
import { cookies } from 'next/headers';

/**
 * Supabase client for use in Server Components, Server Actions, and Route
 * Handlers. Must be created fresh per request (it closes over that
 * request's cookies) — never module-level singleton this.
 */
export async function createClient() {
	const cookieStore = await cookies();

	const url =
		process.env.NEXT_PUBLIC_SUPABASE_URL ||
		process.env.SUPABASE_URL ||
		'https://fmmgiykwebwruhxeztvs.supabase.co';
	const anonKey =
		process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY ||
		process.env.SUPABASE_ANON_KEY ||
		'';

	return createServerClient(
		url,
		anonKey,
		{
			cookies: {
				getAll() {
					return cookieStore.getAll();
				},
				setAll(cookiesToSet) {
					try {
						cookiesToSet.forEach(({ name, value, options }) =>
							cookieStore.set(name, value, options)
						);
					} catch {
						// Called from a Server Component render, which can't set
						// cookies — safe to ignore as long as proxy.ts is refreshing
						// the session on every request (see src/proxy.ts).
					}
				},
			},
		}
	);
}

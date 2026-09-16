import { createServerClient } from '@supabase/ssr';
import { NextResponse, type NextRequest } from 'next/server';

/**
 * Refreshes the Supabase auth session for one request/response pair.
 * Split out of proxy.ts so it can be layered onto whatever response
 * next-intl's own middleware produced, rather than the two middlewares
 * fighting over which response wins — see proxy.ts for how they combine.
 *
 * Mirrors Supabase's own documented pattern for Next.js middleware
 * (https://supabase.com/docs/guides/auth/server-side/nextjs): write
 * refreshed cookies onto both the request (so this request's Server
 * Components see them) and the response (so the browser keeps them).
 */
export async function updateSession(
	request: NextRequest,
	response: NextResponse
) {
	const supabaseUrl =
		process.env.NEXT_PUBLIC_SUPABASE_URL || process.env.SUPABASE_URL;
	const supabaseKey =
		process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY || process.env.SUPABASE_ANON_KEY;

	// If Supabase environment variables are missing (e.g. not configured on Vercel),
	// skip session refresh gracefully instead of crashing the middleware with a 500 error.
	if (!supabaseUrl || !supabaseKey) {
		return response;
	}

	try {
		const supabase = createServerClient(
			supabaseUrl,
			supabaseKey,
			{
				cookies: {
					getAll() {
						return request.cookies.getAll();
					},
					setAll(cookiesToSet) {
						cookiesToSet.forEach(({ name, value }) =>
							request.cookies.set(name, value)
						);
						cookiesToSet.forEach(({ name, value, options }) =>
							response.cookies.set(name, value, options)
						);
					},
				},
			}
		);

		// Triggers token refresh if expired
		await supabase.auth.getUser();
	} catch (error) {
		console.error('[Supabase Middleware] Session refresh error:', error);
	}

	return response;
}

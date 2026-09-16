import createMiddleware from 'next-intl/middleware';
import type { NextRequest } from 'next/server';
import { routing } from './i18n/routing';
import { updateSession } from './lib/supabase/middleware';

const intlMiddleware = createMiddleware(routing);

// Combines next-intl's locale routing with Supabase's session refresh in
// one proxy, since Next.js only runs a single middleware/proxy per
// request — layering a second one on top would silently replace this
// one rather than run alongside it. next-intl resolves locale
// redirects/rewrites first; Supabase's refreshed auth cookies are then
// written onto that same response instead of a separate one, so both
// take effect together (see lib/supabase/middleware.ts for why the
// refresh itself is split out).
export default async function proxy(request: NextRequest) {
	const response = intlMiddleware(request);
	return updateSession(request, response);
}

export const config = {
	// Match all pathnames except for:
	// - API routes
	// - _next (Next.js internals)
	// - _vercel (Vercel internals)
	// - static files (e.g. /favicon.ico, /logo.png, etc.)
	matcher: ['/', '/(ar|en|fr)/:path*', '/((?!api|_next|_vercel|.*\\..*).*)'],
};

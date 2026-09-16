import { NextResponse } from 'next/server';
import { createClient } from '@supabase/supabase-js';

/**
 * GET /api/releases/latest
 *
 * Returns the current APK release metadata by reading the manifest.json
 * published to Supabase Storage after each CI release.  This avoids the
 * need to trigger a full Vercel redeploy just to update the version number.
 *
 * Falls back to NEXT_PUBLIC_APK_* env vars when Supabase is unreachable
 * (e.g. local development without credentials).
 *
 * Environment variables:
 *   SUPABASE_URL             – Supabase project URL
 *   SUPABASE_SERVICE_ROLE_KEY – Service-role key (server-side only)
 *   SUPABASE_APK_BUCKET      – Storage bucket name (defaults to "apk-releases")
 */
export const dynamic = 'force-dynamic'; // Never cache — always fetch fresh manifest

interface ReleaseManifest {
  version: string;
  apkUrl: string;
  size: string;
  sizeBytes?: number;
  sha256: string;
  sha1: string;
  releasedAt: string;
  githubRelease?: string;
}

async function fetchManifestFromSupabase(): Promise<ReleaseManifest | null> {
  const supabaseUrl = process.env.SUPABASE_URL;
  const serviceRoleKey = process.env.SUPABASE_SERVICE_ROLE_KEY;
  const bucket = process.env.SUPABASE_APK_BUCKET || 'apk-releases';

  if (!supabaseUrl || !serviceRoleKey) return null;

  const supabase = createClient(supabaseUrl, serviceRoleKey, {
    auth: { persistSession: false },
  });

  const { data, error } = await supabase.storage
    .from(bucket)
    .download('manifest.json');

  if (error || !data) {
    console.warn('[releases/latest] Manifest not found in Supabase:', error?.message);
    return null;
  }

  try {
    const text = await data.text();
    return JSON.parse(text) as ReleaseManifest;
  } catch {
    console.error('[releases/latest] Failed to parse manifest.json');
    return null;
  }
}

export async function GET() {
  // 1. Try dynamic Supabase manifest first (updated automatically by CI)
  const manifest = await fetchManifestFromSupabase();

  if (manifest?.version && manifest?.apkUrl) {
    return NextResponse.json(manifest, {
      headers: {
        // Revalidate every 60 seconds — short enough to pick up new releases fast
        'Cache-Control': 's-maxage=60, stale-while-revalidate=300',
      },
    });
  }

  // 2. Fall back to NEXT_PUBLIC_APK_* env vars (set at build time or in Vercel dashboard)
  const apkUrl = process.env.NEXT_PUBLIC_APK_URL || null;
  const version = process.env.NEXT_PUBLIC_APK_VERSION || null;
  const size = process.env.NEXT_PUBLIC_APK_SIZE || null;
  const sha256 = process.env.NEXT_PUBLIC_APK_SHA256 || null;
  const sha1 = process.env.NEXT_PUBLIC_APK_SHA1 || null;
  const releasedAt = process.env.NEXT_PUBLIC_APK_RELEASED_AT || null;

  if (!apkUrl || !version) {
    return NextResponse.json(
      { error: 'No APK release available yet.' },
      { status: 404 }
    );
  }

  return NextResponse.json({ version, apkUrl, size, sha256, sha1, releasedAt });
}

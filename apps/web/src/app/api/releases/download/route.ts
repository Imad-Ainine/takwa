import { NextRequest, NextResponse } from 'next/server';

/**
 * GET /api/releases/download?version=1.0.5
 *
 * Redirects to the GitHub Releases download URL for the requested APK version.
 * If no version is supplied it queries the GitHub Releases API for the latest.
 *
 * Environment variables required (server-side only):
 *   GITHUB_TOKEN – A GitHub PAT with `repo` scope (required for private repos)
 *   GITHUB_REPO  – "owner/repo" (defaults to "Imad-Ainine/Takwa")
 */

export async function GET(request: NextRequest) {
  const { searchParams } = new URL(request.url);
  const githubRepo = process.env.GITHUB_REPO || 'Imad-Ainine/Takwa';
  const githubToken = process.env.GITHUB_TOKEN;

  let version = searchParams.get('version');

  // Reject anything that isn't a plain semver-ish version before it reaches
  // the GitHub URL we redirect to — this is user-supplied input embedded
  // directly into a URL path segment.
  if (version && !/^\d+\.\d+\.\d+$/.test(version)) {
    version = null;
  }

  // If no version supplied, resolve the latest from GitHub Releases API
  if (!version) {
    try {
      const headers: Record<string, string> = {
        Accept: 'application/vnd.github.v3+json',
        'User-Agent': 'Takwa-App',
      };
      if (githubToken) headers['Authorization'] = `Bearer ${githubToken}`;

      const res = await fetch(
        `https://api.github.com/repos/${githubRepo}/releases/latest`,
        { next: { revalidate: 60 }, headers }
      );
      if (res.ok) {
        const data = await res.json();
        version = (data.tag_name || '').replace(/^v/, '') || null;
      }
    } catch {
      // fall through to env var fallback
    }
  }

  // Final fallback: env var or hardcoded latest
  version = version || process.env.NEXT_PUBLIC_APK_VERSION || '1.0.5';

  // Build the GitHub Releases direct-download URL
  const downloadUrl = `https://github.com/${githubRepo}/releases/download/v${version}/takwa-v${version}.apk`;

  // Redirect directly to GitHub — no signed URL needed since GitHub Releases are public
  return NextResponse.redirect(downloadUrl, { status: 302 });
}

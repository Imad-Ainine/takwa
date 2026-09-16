import { createClient } from '@supabase/supabase-js';

export interface ReleaseInfo {
  version: string;
  apkUrl: string;
  size: string;
  sha256: string;
  sha1: string;
  downloadFilename: string;
}

/**
 * Automatically resolves the latest released APK metadata.
 * 1. Checks Supabase Storage manifest.json first — release-apk.yml publishes
 *    it (with a service-role key, no rate limit) as the very last step of
 *    every release, so it's the most reliable "source of truth" and needs
 *    no Vercel redeploy to pick up a new version.
 * 2. Falls back to the GitHub Releases API. NOTE: unauthenticated requests
 *    are rate-limited to 60/hour — set a server-side GITHUB_TOKEN env var on
 *    Vercel to avoid this silently falling through on a busy deploy.
 * 3. Falls back to NEXT_PUBLIC_APK_* environment variables.
 *
 * If none of the above resolve, version/apkUrl come back as empty strings
 * rather than a hardcoded version number — a stale-but-plausible-looking
 * fallback (e.g. "v1.0.5") is worse than an honestly empty one, since callers
 * can detect the empty string and hide the download/version UI instead of
 * showing a number that quietly drifts further from reality with every
 * release. Always check `release.apkUrl`/`release.version` for truthiness
 * before rendering them.
 */
export async function getLatestRelease(): Promise<ReleaseInfo> {
  const envVersion = process.env.NEXT_PUBLIC_APK_VERSION || '';
  const envUrl = process.env.NEXT_PUBLIC_APK_URL || (envVersion ? `/api/releases/download?version=${envVersion}` : '');
  const envSize = process.env.NEXT_PUBLIC_APK_SIZE || '';
  const envSha256 = process.env.NEXT_PUBLIC_APK_SHA256 || '';
  const envSha1 = process.env.NEXT_PUBLIC_APK_SHA1 || '';

  // 1. Try Supabase Storage manifest first
  const supabaseUrl = process.env.SUPABASE_URL;
  const serviceRoleKey = process.env.SUPABASE_SERVICE_ROLE_KEY;
  const bucket = process.env.SUPABASE_APK_BUCKET || 'apk-releases';

  if (supabaseUrl && serviceRoleKey) {
    try {
      const supabase = createClient(supabaseUrl, serviceRoleKey, {
        auth: { persistSession: false },
      });

      const { data, error } = await supabase.storage
        .from(bucket)
        .download('manifest.json');

      if (!error && data) {
        const manifest = JSON.parse(await data.text());
        if (manifest.version && manifest.apkUrl) {
          return {
            version: manifest.version,
            apkUrl: manifest.apkUrl,
            size: manifest.size || envSize,
            sha256: manifest.sha256 || envSha256,
            sha1: manifest.sha1 || envSha1,
            downloadFilename: `takwa-v${manifest.version}.apk`,
          };
        }
      }
    } catch (err) {
      console.warn('[getLatestRelease] Error checking Supabase storage:', err);
    }
  }

  // 2. Try GitHub Releases API
  // For private repos (or to avoid the 60/hour unauthenticated rate limit)
  // this needs a server-side GITHUB_TOKEN env var on Vercel.
  try {
    const repo = process.env.GITHUB_REPO || 'Imad-Ainine/Takwa';
    const githubToken = process.env.GITHUB_TOKEN; // server-side only, never NEXT_PUBLIC_

    const headers: Record<string, string> = {
      Accept: 'application/vnd.github.v3+json',
      'User-Agent': 'Takwa-App',
    };
    if (githubToken) {
      headers['Authorization'] = `Bearer ${githubToken}`;
    }

    const res = await fetch(`https://api.github.com/repos/${repo}/releases/latest`, {
      next: { revalidate: 60 },
      headers,
    });

    if (res.ok) {
      const release = await res.json();
      const version = (release.tag_name || '').replace(/^v/, '');
      const apkAsset = release.assets?.find((a: { name?: string }) => a.name?.endsWith('.apk'));

      if (version && apkAsset) {
        const sizeMb = (apkAsset.size / (1024 * 1024)).toFixed(2) + ' MB';
        const sha256Match = release.body?.match(/SHA-256\s*\|\s*`([a-fA-F0-9]+)`/);
        const sha1Match = release.body?.match(/SHA-1\s*\|\s*`([a-fA-F0-9]+)`/);

        return {
          version,
          apkUrl: apkAsset.browser_download_url,
          size: sizeMb,
          sha256: sha256Match ? sha256Match[1] : envSha256,
          sha1: sha1Match ? sha1Match[1] : envSha1,
          downloadFilename: apkAsset.name || `takwa-v${version}.apk`,
        };
      }
    } else if (res.status === 403) {
      console.warn('[getLatestRelease] GitHub API rate-limited (set GITHUB_TOKEN on Vercel to fix)');
    }
  } catch (err) {
    console.warn('[getLatestRelease] Error checking GitHub Releases API:', err);
  }

  // 3. Explicit env var override, if configured
  if (envVersion && envUrl) {
    return {
      version: envVersion,
      apkUrl: envUrl,
      size: envSize,
      sha256: envSha256,
      sha1: envSha1,
      downloadFilename: `takwa-v${envVersion}.apk`,
    };
  }

  // 4. Nothing resolved — return empty rather than a fabricated version.
  return {
    version: '',
    apkUrl: '',
    size: '',
    sha256: '',
    sha1: '',
    downloadFilename: '',
  };
}

/**
 * The iOS install link (TestFlight public link, or an App Store link once
 * published) — set via the NEXT_PUBLIC_IOS_APP_URL env var in the Vercel
 * project settings. Unlike the Android APK there's no GitHub Release asset
 * or checksum to resolve automatically: TestFlight builds are uploaded
 * straight to App Store Connect by release-testflight.yml (see
 * docs/ios-testflight-setup.md), and Apple never exposes a public,
 * machine-readable "latest build" URL the way GitHub Releases does — the
 * Public Link itself is a fixed URL you copy once from App Store Connect
 * after enabling it, so an env var is the correct source of truth here.
 *
 * Returns an empty string (never a placeholder) until that link exists, so
 * callers can hide the iOS download UI instead of showing a dead link.
 */
export function getIosAppUrl(): string {
  return process.env.NEXT_PUBLIC_IOS_APP_URL || '';
}

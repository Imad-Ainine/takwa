import { getTranslations } from 'next-intl/server';
import LandingPage from '@/components/landing/LandingPage';
import { getLatestRelease, getIosAppUrl } from '@/lib/releases';

export const revalidate = 60;

/**
 * Landing page — Server Component.
 * Dynamically queries the latest release metadata from GitHub Releases API
 * (with Supabase fallback) so any newly published release is immediately reflected.
 */
export default async function Home() {
  await getTranslations('HomePage'); // preload translations on server

  const release = await getLatestRelease();
  const iosUrl = getIosAppUrl();

  return (
    <LandingPage
      apkUrl={release.apkUrl}
      apkVersion={release.version}
      apkSize={release.size}
      sha256={release.sha256}
      sha1={release.sha1}
      iosUrl={iosUrl}
    />
  );
}


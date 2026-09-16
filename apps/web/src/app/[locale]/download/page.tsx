import { getTranslations } from 'next-intl/server';
import DownloadSection from '@/components/landing/DownloadSection';
import { getLatestRelease, getIosAppUrl } from '@/lib/releases';

export const revalidate = 60;

/**
 * Dedicated Android + iOS download page — reuses the same DownloadSection
 * shown on the landing page so there's one source of truth for the
 * platform tabs, QR codes, checksums, and install guides.
 */
export default async function DownloadPage() {
	await getTranslations('HomePage'); // preload translations on server

	const release = await getLatestRelease();
	const iosUrl = getIosAppUrl();

	return (
		<main id="main-content">
			<DownloadSection
				apkUrl={release.apkUrl}
				apkVersion={release.version}
				apkSize={release.size}
				sha256={release.sha256}
				sha1={release.sha1}
				iosUrl={iosUrl}
			/>
		</main>
	);
}

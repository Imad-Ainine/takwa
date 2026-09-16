import { getTranslations } from 'next-intl/server';
import { redirect } from '@/i18n/routing';
import { createClient } from '@/lib/supabase/server';
import { getLatestRelease } from '@/lib/releases';
import { signOut } from './actions';
import styles from './dashboard.module.css';

/**
 * Dashboard — shows user info + APK early-access download card.
 * APK metadata is dynamically resolved via getLatestRelease().
 */
export default async function DashboardPage({
	params,
}: {
	params: Promise<{ locale: string }>;
}) {
	const { locale } = await params;
	const t = await getTranslations('Dashboard');

	const supabase = await createClient();
	const {
		data: { user },
	} = await supabase.auth.getUser();

	if (!user) {
		redirect({ href: '/login', locale });
	}

	const release = await getLatestRelease();
	const apkUrl = release.apkUrl;
	const apkVersion = release.version;
	const apkSize = release.size;
	const apkSha1 = release.sha1;
	const apkSha256 = release.sha256;
	const downloadFilename = release.downloadFilename;

	return (
		<div className={styles.page}>
			<div className={styles.grid}>

				{/* ── Welcome card ── */}
				<div className={`${styles.card} ${styles.welcomeCard}`}>
					<div className={styles.avatarRing}>
						<span className={styles.avatarEmoji}>🌙</span>
					</div>
					<h1 className={`amiri gold-text ${styles.greeting}`}>{t('title')}</h1>
					<p className={styles.welcome}>{t('welcome', { email: user?.email ?? '' })}</p>
					<p className={styles.placeholderNote}>{t('placeholderNote')}</p>
					<form action={signOut}>
						<button id="sign-out-btn" type="submit" className={`btn-outline ${styles.signOutBtn}`}>
							{t('signOut')}
						</button>
					</form>
				</div>

				{/* ── APK Download card ── */}
				<div className={`${styles.card} ${styles.downloadCard}`}>
					{/* Decorative top glow */}
					<div className={styles.downloadGlow} aria-hidden="true" />

					<div className={styles.downloadHeader}>
						<div className={styles.androidIcon}>🤖</div>
						<div>
							<span className={styles.earlyBadge}>{t('download.badge')}</span>
							<h2 className={`amiri ${styles.downloadTitle}`}>{t('download.title')}</h2>
							<p className={styles.downloadSubtitle}>{t('download.subtitle')}</p>
						</div>
					</div>

					<div className={styles.downloadMeta}>
						<div className={styles.metaPill}>
							<span className={styles.metaIcon}>📱</span>
							<span>{t('download.platform')}</span>
						</div>
						{apkVersion && (
							<div className={styles.metaPill}>
								<span className={styles.metaIcon}>🏷️</span>
								<span>{t('download.version', { version: apkVersion })}</span>
							</div>
						)}
						{apkSize && (
							<div className={styles.metaPill}>
								<span className={styles.metaIcon}>⚖️</span>
								<span>{t('download.size', { size: apkSize })}</span>
							</div>
						)}
					</div>

					{apkUrl ? (
						<a
							id="download-apk-btn"
							href={apkUrl}
							download={downloadFilename}
							className={styles.downloadBtn}
						>
							<span className={styles.downloadBtnIcon}>⬇️</span>
							{t('download.button')}
						</a>
					) : (
						<button
							id="download-apk-unavailable"
							type="button"
							disabled
							className={styles.downloadBtnDisabled}
						>
							<span className={styles.downloadBtnIcon}>⏳</span>
							{t('download.unavailable')}
						</button>
					)}

					<p className={styles.instructions}>{t('download.instructions')}</p>

					{apkSha256 && (
						<div className={styles.sha1Row}>
							<span className={styles.sha1Label}>SHA-256</span>
							<code className={styles.sha1Hash}>{apkSha256}</code>
						</div>
					)}

					{apkSha1 && (
						<div className={styles.sha1Row}>
							<span className={styles.sha1Label}>{t('download.sha1Label')}</span>
							<code className={styles.sha1Hash}>{apkSha1}</code>
						</div>
					)}
				</div>

			</div>
		</div>
	);
}

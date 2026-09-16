import { getTranslations } from 'next-intl/server';
import { redirect } from '@/i18n/routing';
import { createClient } from '@/lib/supabase/server';
import { getLatestRelease } from '@/lib/releases';
import {
	getAchievements,
	getProfileSummary,
	getRecentRecords,
	getTodayRecord,
} from '@/lib/dashboard';
import { signOut } from './actions';
import styles from './dashboard.module.css';

const PRAYER_KEYS = ['fajr', 'dhuhr', 'asr', 'maghrib', 'isha'] as const;

/**
 * Dashboard — user info, APK early-access download card, and a read-only
 * view of the same data the mobile app syncs to Supabase (today's summary,
 * recent history, achievements). See docs/specs/web-dashboard-parity.md.
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

	const [release, profile, todayRecord, recentRecords, achievements] = await Promise.all([
		getLatestRelease(),
		getProfileSummary(supabase, user!.id),
		getTodayRecord(supabase, user!.id),
		getRecentRecords(supabase, user!.id),
		getAchievements(supabase, user!.id),
	]);
	const apkUrl = release.apkUrl;
	const apkVersion = release.version;
	const apkSize = release.size;
	const apkSha1 = release.sha1;
	const apkSha256 = release.sha256;
	const downloadFilename = release.downloadFilename;

	const dateFormatter = new Intl.DateTimeFormat(locale, {
		month: 'short',
		day: 'numeric',
	});

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

					{profile && (
						<div className={styles.statsRow}>
							<div className={styles.metaPill}>
								<span className={styles.metaIcon}>🔥</span>
								<span>{t('stats.currentStreak')}: {profile.currentStreak}</span>
							</div>
							<div className={styles.metaPill}>
								<span className={styles.metaIcon}>🏅</span>
								<span>{t('stats.highestStreak')}: {profile.highestStreak}</span>
							</div>
							<div className={styles.metaPill}>
								<span className={styles.metaIcon}>✨</span>
								<span>{t('stats.totalPoints')}: {profile.totalPoints}</span>
							</div>
							<div className={styles.metaPill}>
								<span className={styles.metaIcon}>📖</span>
								<span>{t('stats.quranPagesTotal')}: {profile.quranPages}</span>
							</div>
						</div>
					)}

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

			<div className={styles.sections}>

				{/* ── Today's summary ── */}
				<div className={styles.card}>
					<h2 className={`amiri gold-text ${styles.sectionTitle}`}>{t('today.title')}</h2>
					{todayRecord ? (
						<>
							<div className={styles.prayerRow}>
								{PRAYER_KEYS.map((key) => {
									const status = todayRecord[`${key}Status` as const];
									const doneLike = status === 'performed' || status === 'qadaa';
									return (
										<div
											key={key}
											className={`${styles.prayerBadge} ${doneLike ? styles.prayerBadgeDone : ''}`}
										>
											<span className={styles.prayerName}>{t(`prayerNames.${key}`)}</span>
											<span className={styles.prayerStatusLabel}>{t(`prayerStatus.${status}` as 'prayerStatus.performed')}</span>
										</div>
									);
								})}
							</div>
							<div className={styles.statsRow}>
								<div className={styles.metaPill}>
									<span className={styles.metaIcon}>📖</span>
									<span>{t('today.quranPages')}: {todayRecord.quranPages}</span>
								</div>
								<div className={styles.metaPill}>
									<span className={styles.metaIcon}>🌅</span>
									<span>{t('today.morningAdhkar')}: {todayRecord.morningAdhkar ? t('today.done') : t('today.notDone')}</span>
								</div>
								<div className={styles.metaPill}>
									<span className={styles.metaIcon}>🌙</span>
									<span>{t('today.eveningAdhkar')}: {todayRecord.eveningAdhkar ? t('today.done') : t('today.notDone')}</span>
								</div>
								<div className={styles.metaPill}>
									<span className={styles.metaIcon}>🕌</span>
									<span>{t('today.fasting')}: {t(`fastingType.${todayRecord.fastingType}` as 'fastingType.none')}</span>
								</div>
								<div className={styles.metaPill}>
									<span className={styles.metaIcon}>⭐</span>
									<span>{t('today.netPoints')}: {todayRecord.netPoints}</span>
								</div>
							</div>
						</>
					) : (
						<p className={styles.placeholderNote}>{t('today.empty')}</p>
					)}
				</div>

				{/* ── Recent history ── */}
				<div className={styles.card}>
					<h2 className={`amiri gold-text ${styles.sectionTitle}`}>{t('history.title')}</h2>
					{recentRecords.length > 0 ? (
						<table className={styles.historyTable}>
							<thead>
								<tr>
									<th>{t('history.dateHeader')}</th>
									<th>{t('history.prayersHeader')}</th>
									<th>{t('history.quranHeader')}</th>
									<th>{t('history.pointsHeader')}</th>
								</tr>
							</thead>
							<tbody>
								{recentRecords.map((r) => {
									const performedCount = [
										r.fajrStatus,
										r.dhuhrStatus,
										r.asrStatus,
										r.maghribStatus,
										r.ishaStatus,
									].filter((s) => s === 'performed' || s === 'qadaa').length;
									return (
										<tr key={r.date}>
											<td>{dateFormatter.format(new Date(`${r.date}T00:00:00`))}</td>
											<td>{performedCount}/5</td>
											<td>{r.quranPages}</td>
											<td>{r.netPoints}</td>
										</tr>
									);
								})}
							</tbody>
						</table>
					) : (
						<p className={styles.placeholderNote}>{t('history.empty')}</p>
					)}
				</div>

				{/* ── Achievements ── */}
				<div className={styles.card}>
					<h2 className={`amiri gold-text ${styles.sectionTitle}`}>{t('achievements.title')}</h2>
					{achievements.length > 0 ? (
						<div className={styles.achievementsGrid}>
							{achievements.map((a) => (
								<div key={a.id} className={styles.achievementCard}>
									<span className={styles.achievementEmoji}>{a.emoji}</span>
									<div>
										<p className={styles.achievementTitle}>{a.titleAr}</p>
										<p className={styles.achievementDesc}>{a.descAr}</p>
										<p className={styles.achievementMeta}>
											{dateFormatter.format(new Date(a.earnedAt))} • +{a.pointsReward} {t('achievements.pointsSuffix')}
										</p>
									</div>
								</div>
							))}
						</div>
					) : (
						<p className={styles.placeholderNote}>{t('achievements.empty')}</p>
					)}
				</div>

			</div>
		</div>
	);
}

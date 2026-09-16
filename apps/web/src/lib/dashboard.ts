import type { SupabaseClient } from '@supabase/supabase-js';

/**
 * Read-only dashboard data — reads the same tables the mobile app already
 * syncs to Supabase (see apps/mobile/docs/schema.sql), rather than adding
 * any new write path. See docs/specs/web-dashboard-parity.md.
 *
 * Row-level security on `profiles`/`daily_records`/`achievements` is the
 * enforcement boundary (same as the mobile app's client-side Supabase
 * calls) — every query here is scoped to the signed-in user's own `userId`,
 * but a caller must not treat that as a substitute for RLS actually being
 * configured correctly on those tables.
 */

export interface ProfileSummary {
	totalPoints: number;
	currentStreak: number;
	highestStreak: number;
	quranPages: number;
}

export interface DailyRecordRow {
	date: string; // 'YYYY-MM-DD'
	fajrStatus: string;
	dhuhrStatus: string;
	asrStatus: string;
	maghribStatus: string;
	ishaStatus: string;
	quranPages: number;
	morningAdhkar: boolean;
	eveningAdhkar: boolean;
	fastingType: string;
	netPoints: number;
}

export interface AchievementRow {
	id: number;
	titleAr: string;
	descAr: string;
	emoji: string;
	pointsReward: number;
	earnedAt: string;
}

export async function getProfileSummary(
	supabase: SupabaseClient,
	userId: string
): Promise<ProfileSummary | null> {
	const { data, error } = await supabase
		.from('profiles')
		.select('total_points, current_streak, highest_streak, quran_pages')
		.eq('id', userId)
		.maybeSingle();

	if (error) throw error;
	if (!data) return null;

	return {
		totalPoints: data.total_points ?? 0,
		currentStreak: data.current_streak ?? 0,
		highestStreak: data.highest_streak ?? 0,
		quranPages: data.quran_pages ?? 0,
	};
}

function mapDailyRecord(row: Record<string, unknown>): DailyRecordRow {
	return {
		date: row.date as string,
		fajrStatus: (row.fajr_status as string) ?? 'notDue',
		dhuhrStatus: (row.dhuhr_status as string) ?? 'notDue',
		asrStatus: (row.asr_status as string) ?? 'notDue',
		maghribStatus: (row.maghrib_status as string) ?? 'notDue',
		ishaStatus: (row.isha_status as string) ?? 'notDue',
		quranPages: (row.quran_pages as number) ?? 0,
		morningAdhkar: Boolean(row.morning_adhkar),
		eveningAdhkar: Boolean(row.evening_adhkar),
		fastingType: (row.fasting_type as string) ?? 'none',
		netPoints: (row.net_points as number) ?? 0,
	};
}

/**
 * Today's record, keyed off the *server's* UTC date. The mobile app stores
 * `date` as the device's local calendar date with no timezone column, so
 * this can be off by one day right around midnight for the user — an
 * accepted limitation for v1 (see the spec's open questions), not a bug to
 * chase without a real timezone field to fix it properly.
 */
export async function getTodayRecord(
	supabase: SupabaseClient,
	userId: string
): Promise<DailyRecordRow | null> {
	const today = new Date().toISOString().slice(0, 10);
	const { data, error } = await supabase
		.from('daily_records')
		.select(
			'date, fajr_status, dhuhr_status, asr_status, maghrib_status, isha_status, quran_pages, morning_adhkar, evening_adhkar, fasting_type, net_points'
		)
		.eq('user_id', userId)
		.eq('date', today)
		.maybeSingle();

	if (error) throw error;
	if (!data) return null;
	return mapDailyRecord(data);
}

export async function getRecentRecords(
	supabase: SupabaseClient,
	userId: string,
	limit = 14
): Promise<DailyRecordRow[]> {
	const { data, error } = await supabase
		.from('daily_records')
		.select(
			'date, fajr_status, dhuhr_status, asr_status, maghrib_status, isha_status, quran_pages, morning_adhkar, evening_adhkar, fasting_type, net_points'
		)
		.eq('user_id', userId)
		.order('date', { ascending: false })
		.limit(limit);

	if (error) throw error;
	return (data ?? []).map(mapDailyRecord);
}

export async function getAchievements(
	supabase: SupabaseClient,
	userId: string
): Promise<AchievementRow[]> {
	const { data, error } = await supabase
		.from('achievements')
		.select('id, title_ar, desc_ar, emoji, points_reward, earned_at')
		.eq('user_id', userId)
		.order('earned_at', { ascending: false });

	if (error) throw error;
	return (data ?? []).map(
		(row: {
			id: number;
			title_ar: string | null;
			desc_ar: string | null;
			emoji: string | null;
			points_reward: number | null;
			earned_at: string;
		}) => ({
			id: row.id,
			titleAr: row.title_ar ?? '',
			descAr: row.desc_ar ?? '',
			emoji: row.emoji ?? '🏆',
			pointsReward: row.points_reward ?? 0,
			earnedAt: row.earned_at,
		})
	);
}

import 'package:flutter/widgets.dart' show Locale;
import 'package:takwa/l10n/app_localizations.dart';

enum AchievementCategory { daily, milestone, ibadah, special }

class AchievementDefinition {
  final String id;
  final String titleAr;
  final String descAr;
  final String emoji;
  final int pointsReward;
  final AchievementCategory category;

  const AchievementDefinition({
    required this.id,
    required this.titleAr,
    required this.descAr,
    required this.emoji,
    this.pointsReward = 0,
    required this.category,
  });

  /// The full achievement catalog — this is the actual source of truth the
  /// UI renders from (the `achievements` table's own title_ar/desc_ar
  /// columns are only ever written at grant time and never read back for
  /// display; see the audit's "i18n & Accessibility" section). Copy comes
  /// from lib/l10n/app_ar.arb, same as the grant-time text in
  /// DailyRecordDao.checkAndGrantAchievements() — the app is Arabic-only
  /// at runtime today, so this is a straight port of what was previously
  /// hardcoded here, not a behavior change.
  static List<AchievementDefinition> get all {
    final l10n = lookupAppLocalizations(const Locale('ar'));
    return [
      // --- Daily Achievements ---
      AchievementDefinition(
        id: 'daily_muhasaba',
        titleAr: l10n.achievementDailyMuhasabaTitle,
        descAr: l10n.achievementDailyMuhasabaDesc,
        emoji: '📝',
        pointsReward: 10,
        category: AchievementCategory.daily,
      ),
      AchievementDefinition(
        id: 'morning_adhkar',
        titleAr: l10n.achievementMorningAdhkarTitle,
        descAr: l10n.achievementMorningAdhkarDesc,
        emoji: '🌅',
        pointsReward: 5,
        category: AchievementCategory.daily,
      ),
      AchievementDefinition(
        id: 'evening_adhkar',
        titleAr: l10n.achievementEveningAdhkarTitle,
        descAr: l10n.achievementEveningAdhkarDesc,
        emoji: '🌙',
        pointsReward: 5,
        category: AchievementCategory.daily,
      ),

      // --- Milestones ---
      AchievementDefinition(
        id: 'streak_3',
        titleAr: l10n.achievementStreak3Title,
        descAr: l10n.achievementStreak3Desc,
        emoji: '🌱',
        pointsReward: 20,
        category: AchievementCategory.milestone,
      ),
      AchievementDefinition(
        id: 'streak_7',
        titleAr: l10n.achievementStreak7Title,
        descAr: l10n.achievementStreak7Desc,
        emoji: '🌿',
        pointsReward: 50,
        category: AchievementCategory.milestone,
      ),
      AchievementDefinition(
        id: 'streak_30',
        titleAr: l10n.achievementStreak30Title,
        descAr: l10n.achievementStreak30Desc,
        emoji: '⚔️',
        pointsReward: 200,
        category: AchievementCategory.milestone,
      ),
      AchievementDefinition(
        id: 'points_100',
        titleAr: l10n.achievementPoints100Title,
        descAr: l10n.achievementPoints100Desc,
        emoji: '🎖️',
        pointsReward: 50,
        category: AchievementCategory.milestone,
      ),
      AchievementDefinition(
        id: 'points_1000',
        titleAr: l10n.achievementPoints1000Title,
        descAr: l10n.achievementPoints1000Desc,
        emoji: '🏆',
        pointsReward: 500,
        category: AchievementCategory.milestone,
      ),

      // --- Ibadah ---
      AchievementDefinition(
        id: 'quran_juz',
        titleAr: l10n.achievementQuranJuzTitle,
        descAr: l10n.achievementQuranJuzDesc,
        emoji: '📖',
        pointsReward: 100,
        category: AchievementCategory.ibadah,
      ),
      AchievementDefinition(
        id: 'fajr_on_time',
        titleAr: l10n.achievementFajrOnTimeTitle,
        descAr: l10n.achievementFajrOnTimeDesc,
        emoji: '🕌',
        pointsReward: 30,
        category: AchievementCategory.ibadah,
      ),
      AchievementDefinition(
        id: 'fasting_nafl',
        titleAr: l10n.achievementFastingNaflTitle,
        descAr: l10n.achievementFastingNaflDesc,
        emoji: '🌙',
        pointsReward: 40,
        category: AchievementCategory.ibadah,
      ),
      AchievementDefinition(
        id: 'tasbeeh_100',
        titleAr: l10n.achievementTasbeeh100Title,
        descAr: l10n.achievementTasbeeh100Desc,
        emoji: '📿',
        pointsReward: 20,
        category: AchievementCategory.ibadah,
      ),

      // --- Special ---
      AchievementDefinition(
        id: 'first_sadaqah',
        titleAr: l10n.achievementFirstSadaqahTitle,
        descAr: l10n.achievementFirstSadaqahDesc,
        emoji: '💰',
        pointsReward: 30,
        category: AchievementCategory.special,
      ),
      AchievementDefinition(
        id: 'ramadan_knight',
        titleAr: l10n.achievementRamadanKnightTitle,
        descAr: l10n.achievementRamadanKnightDesc,
        emoji: '✨',
        pointsReward: 100,
        category: AchievementCategory.special,
      ),
      AchievementDefinition(
        id: 'perfect_week_prayer',
        titleAr: l10n.achievementPerfectWeekPrayerTitle,
        descAr: l10n.achievementPerfectWeekPrayerDesc,
        emoji: '🕌',
        pointsReward: 150,
        category: AchievementCategory.special,
      ),
      AchievementDefinition(
        id: 'constant_reader',
        titleAr: l10n.achievementConstantReaderTitle,
        descAr: l10n.achievementConstantReaderDesc,
        emoji: '📚',
        pointsReward: 40,
        category: AchievementCategory.special,
      ),
    ];
  }
}

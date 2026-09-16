import 'dart:developer' as developer;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:takwa/core/supabase/sync_manager.dart';
import 'package:takwa/core/providers/database_providers.dart';
import 'package:takwa/features/achievements/domain/models/achievement_definition.dart';

class AchievementView {
  final AchievementDefinition definition;
  final bool isEarned;
  final DateTime? earnedAt;

  /// Whether the user has already seen this achievement's unlock
  /// animation. Meaningless (and left `true`, i.e. "nothing to
  /// celebrate") for achievements that haven't been earned yet.
  final bool seen;

  const AchievementView({
    required this.definition,
    required this.isEarned,
    this.earnedAt,
    this.seen = true,
  });

  /// True only for a freshly-earned achievement whose unlock animation
  /// hasn't played yet.
  bool get isNewlyUnlocked => isEarned && !seen;
}

final achievementsProvider = FutureProvider<List<AchievementView>>((ref) async {
  final statsDao = ref.watch(statsDaoProvider);
  final db = ref.watch(appDatabaseProvider);
  final syncManager = ref.read(syncManagerProvider);

  // 1. Check and grant new achievements automatically
  final newEarned = await statsDao.checkAndGrantAchievements();
  for (final ach in newEarned) {
    try {
      await syncManager.syncAchievement(ach);
    } catch (e) {
      developer.log('Cannot sync to Supabase: $e', name: 'Achievements');
    }
  }

  // 2. Fetch earned achievements from DB
  final earnedList = await (db.select(db.achievements)).get();
  final earnedMap = {for (var a in earnedList) a.type: a};

  // 3. Map all definitions to AchievementView
  return AchievementDefinition.all.map((def) {
    final earned = earnedMap[def.id];
    return AchievementView(
      definition: def,
      isEarned: earned != null,
      earnedAt: earned?.earnedAt,
      seen: earned?.seen ?? true,
    );
  }).toList();
});

/// إجمالي عدد الإنجازات المحققة
final earnedAchievementsCountProvider = Provider<int>((ref) {
  final all = ref.watch(achievementsProvider).value ?? [];
  return all.where((a) => a.isEarned).length;
});

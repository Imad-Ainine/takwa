import 'package:flutter/widgets.dart' show Locale;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:takwa/core/providers/auth_providers.dart';
import 'package:takwa/core/providers/database_providers.dart';
import 'package:takwa/core/supabase/supabase_config.dart';
import 'package:takwa/features/circles/domain/circle_models.dart';
import 'package:takwa/l10n/app_localizations.dart';

// ── My circles ──────────────────────────────────────────────────
class MyCirclesNotifier extends AsyncNotifier<List<CircleSummary>> {
  @override
  Future<List<CircleSummary>> build() async {
    final raw = await ref.read(supabaseServiceProvider).getMyCircles();
    return raw.map(CircleSummary.fromMap).toList();
  }

  Future<void> refresh() async {
    ref.invalidateSelf();
    await future;
  }

  /// See docs/specs/family-community-features.md's data-model section —
  /// 'circle_joined' fires once, the first time this user has ever created
  /// or joined a circle. Same locale-agnostic grant-time text approach as
  /// StatsDao.checkAndGrantAchievements() (the app is Arabic-only at
  /// runtime today; see that method's own comment).
  Future<void> _grantCircleJoinedAchievement() async {
    final l10n = lookupAppLocalizations(const Locale('ar'));
    await ref
        .read(statsDaoProvider)
        .tryGrantAchievement(
          'circle_joined',
          l10n.achievementCircleJoinedTitle,
          l10n.achievementCircleJoinedDesc,
          '👨‍👩‍👧‍👦',
          30,
        );
  }

  Future<CircleSummary> create(String name) async {
    final map = await ref.read(supabaseServiceProvider).createCircle(name);
    await refresh();
    await _grantCircleJoinedAchievement();
    return CircleSummary.fromMap(map);
  }

  Future<CircleSummary> join(String inviteCode) async {
    final map = await ref
        .read(supabaseServiceProvider)
        .joinCircleByCode(inviteCode);
    await refresh();
    await _grantCircleJoinedAchievement();
    return CircleSummary.fromMap(map);
  }

  Future<void> leave(String circleId) async {
    await ref.read(supabaseServiceProvider).leaveCircle(circleId);
    await refresh();
  }

  Future<void> rename(String circleId, String newName) async {
    await ref
        .read(supabaseServiceProvider)
        .renameCircle(circleId: circleId, newName: newName);
    await refresh();
  }

  Future<void> delete(String circleId) async {
    await ref.read(supabaseServiceProvider).deleteCircle(circleId);
    await refresh();
  }
}

final myCirclesProvider =
    AsyncNotifierProvider<MyCirclesNotifier, List<CircleSummary>>(
      MyCirclesNotifier.new,
    );

// ── A single circle's leaderboard ──────────────────────────────
class CircleLeaderboardNotifier
    extends FamilyAsyncNotifier<List<CircleMemberRow>, String> {
  @override
  Future<List<CircleMemberRow>> build(String circleId) async {
    final raw = await ref
        .read(supabaseServiceProvider)
        .getCircleLeaderboard(circleId);
    final rows = raw.map(CircleMemberRow.fromMap).toList();
    await _grantStreakMatchAchievement(rows);
    return rows;
  }

  /// 'circle_streak_match' — docs/specs/family-community-features.md's data
  /// model names it alongside 'circle_joined'. The leaderboard is the only
  /// place a user's peers appear with their streaks, so this is where the
  /// comparison can happen; it reads the *local* streak because
  /// `get_circle_leaderboard` NULLs the caller's own row unless they opted
  /// into sharing, which would silently disable the achievement for
  /// non-sharing users. Peers still only appear with a streak when they
  /// opted in (R4), so nothing unshared is ever compared.
  Future<void> _grantStreakMatchAchievement(List<CircleMemberRow> rows) async {
    try {
      final myId = ref.read(supabaseUserProvider).value?.id;
      if (myId == null) return;

      final myStreak = await ref.read(statsDaoProvider).getCurrentStreak();
      if (!matchesSharedStreak(rows, myUserId: myId, myStreak: myStreak)) {
        return;
      }

      final l10n = lookupAppLocalizations(const Locale('ar'));
      await ref
          .read(statsDaoProvider)
          .tryGrantAchievement(
            'circle_streak_match',
            l10n.achievementCircleStreakMatchTitle,
            l10n.achievementCircleStreakMatchDesc,
            '🤝',
            40,
          );
    } catch (_) {
      // A failed achievement check must not blank the leaderboard.
    }
  }

  Future<void> refresh() async {
    ref.invalidateSelf();
    await future;
  }

  Future<void> removeMember(String circleId, String userId) async {
    await ref
        .read(supabaseServiceProvider)
        .removeCircleMember(circleId: circleId, userId: userId);
    ref.invalidateSelf();
    await future;
  }
}

final circleLeaderboardProvider = AsyncNotifierProvider.family<
  CircleLeaderboardNotifier,
  List<CircleMemberRow>,
  String
>(CircleLeaderboardNotifier.new);

/// Reactions the current device's user has received in a given circle —
/// see docs/specs/family-community-features.md R6.
final circleReactionsReceivedProvider = FutureProvider.family
    .autoDispose<List<CircleReactionReceived>, ({String circleId, String myUserId})>((
      ref,
      args,
    ) async {
      final raw = await ref
          .read(supabaseServiceProvider)
          .getCircleReactionsReceived(args.circleId, args.myUserId);
      return raw.map(CircleReactionReceived.fromMap).toList();
    });

// ── This device's own sharing toggles for a circle ─────────────
// Read off the leaderboard's own row rather than a separate query — the
// leaderboard already returns every member including the caller with all
// fields populated (sharing your own signal with yourself is meaningless,
// but the RPC doesn't special-case the caller, so the row is complete).
final myCircleMembershipProvider = Provider.family<CircleMemberRow?, ({String circleId, String myUserId})>(
  (ref, args) {
    final rows = ref.watch(circleLeaderboardProvider(args.circleId)).valueOrNull;
    if (rows == null) return null;
    for (final r in rows) {
      if (r.userId == args.myUserId) return r;
    }
    return null;
  },
);

// ── Unread reaction badge count per circle (R5) ────────────────
/// Returns the count of reactions received by the current user in [circleId]
/// that are newer than the last-visited timestamp stored in [SettingsDao].
/// - Returns 0 silently on any error (a missing badge is less disruptive
///   than a broken layout).
/// - Treats null last-visited (first-ever visit) as "all reactions unread".
final circleUnreadCountProvider =
    FutureProvider.family.autoDispose<int, String>((ref, circleId) async {
  try {
    final uid = ref.watch(supabaseUserProvider).value?.id;
    if (uid == null) return 0;

    final lastVisited = await ref
        .read(settingsDaoProvider)
        .getCircleLastVisited(circleId);

    final raw = await ref
        .read(supabaseServiceProvider)
        .getCircleReactionsReceived(circleId, uid);

    final reactions = raw.map(CircleReactionReceived.fromMap).toList();

    if (lastVisited == null) return reactions.length;
    return reactions.where((r) => r.createdAt.isAfter(lastVisited)).length;
  } catch (_) {
    return 0;
  }
});

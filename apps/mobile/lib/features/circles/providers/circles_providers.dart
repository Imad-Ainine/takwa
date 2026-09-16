import 'package:flutter/widgets.dart' show Locale;
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
    return raw.map(CircleMemberRow.fromMap).toList();
  }

  Future<void> refresh() async {
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

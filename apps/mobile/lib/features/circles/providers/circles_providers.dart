import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:takwa/core/supabase/supabase_config.dart';
import 'package:takwa/features/circles/domain/circle_models.dart';

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

  Future<CircleSummary> create(String name) async {
    final map = await ref.read(supabaseServiceProvider).createCircle(name);
    await refresh();
    return CircleSummary.fromMap(map);
  }

  Future<CircleSummary> join(String inviteCode) async {
    final map = await ref
        .read(supabaseServiceProvider)
        .joinCircleByCode(inviteCode);
    await refresh();
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

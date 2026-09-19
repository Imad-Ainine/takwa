import 'package:collection/collection.dart';

/// A fixed, pre-approved encouragement phrase — no free text, so there is
/// nothing here that ever needs moderation. Keys must match the CHECK
/// constraint on `circle_reactions.phrase_key` in
/// supabase/migrations/20260916120000_add_family_circles.sql.
enum ReactionPhrase {
  duaForYou('dua_for_you', '🤲'),
  keepGoing('keep_going', '💪'),
  proudOfYou('proud_of_you', '🌟'),
  youCanDoIt('you_can_do_it', '🔥'),
  mashallah('mashallah', '✨');

  final String key;
  final String emoji;
  const ReactionPhrase(this.key, this.emoji);

  static ReactionPhrase? fromKey(String key) =>
      ReactionPhrase.values.where((p) => p.key == key).firstOrNull;
}

class CircleSummary {
  final String id;
  final String name;
  final String inviteCode;
  final String ownerId;
  final int memberCount;

  const CircleSummary({
    required this.id,
    required this.name,
    required this.inviteCode,
    required this.ownerId,
    required this.memberCount,
  });

  factory CircleSummary.fromMap(Map<String, dynamic> map) => CircleSummary(
    id: map['id'] as String,
    name: map['name'] as String,
    inviteCode: map['invite_code'] as String,
    ownerId: map['owner_id'] as String,
    memberCount: (map['member_count'] as num?)?.toInt() ?? 1,
  );
}

/// A reaction this user has received in a circle — the read side of R6.
class CircleReactionReceived {
  final String id;
  final String fromUserId;
  final String phraseKey;
  final DateTime createdAt;

  const CircleReactionReceived({
    required this.id,
    required this.fromUserId,
    required this.phraseKey,
    required this.createdAt,
  });

  factory CircleReactionReceived.fromMap(Map<String, dynamic> map) =>
      CircleReactionReceived(
        id: map['id'] as String,
        fromUserId: map['from_user_id'] as String,
        phraseKey: map['phrase_key'] as String,
        createdAt: DateTime.parse(map['created_at'] as String),
      );
}

/// One row of a circle's leaderboard. Any signal the member hasn't opted
/// into sharing arrives here as null — the UI must render that as hidden,
/// never as zero (see the spec's R8).
class CircleMemberRow {
  final String userId;
  final String? username;
  final String? avatarEmoji;
  final int? currentStreak;
  final int? totalPoints;
  final int? quranPages;
  final bool? checklistDoneToday;
  final bool shareStreak;
  final bool sharePoints;
  final bool shareChecklistDone;
  final bool shareQuranPages;

  const CircleMemberRow({
    required this.userId,
    this.username,
    this.avatarEmoji,
    this.currentStreak,
    this.totalPoints,
    this.quranPages,
    this.checklistDoneToday,
    this.shareStreak = false,
    this.sharePoints = false,
    this.shareChecklistDone = false,
    this.shareQuranPages = false,
  });

  factory CircleMemberRow.fromMap(Map<String, dynamic> map) {
    final currentStreak = (map['current_streak'] as num?)?.toInt();
    final totalPoints = (map['total_points'] as num?)?.toInt();
    final quranPages = (map['quran_pages'] as num?)?.toInt();
    final checklistDone = map['checklist_done_today'] as bool?;

    return CircleMemberRow(
      userId: map['user_id'] as String,
      username: map['username'] as String?,
      avatarEmoji: map['avatar_emoji'] as String?,
      currentStreak: currentStreak,
      totalPoints: totalPoints,
      quranPages: quranPages,
      checklistDoneToday: checklistDone,
      shareStreak: (map['share_streak'] as bool?) ?? (currentStreak != null),
      sharePoints: (map['share_points'] as bool?) ?? (totalPoints != null),
      shareChecklistDone:
          (map['share_checklist_done'] as bool?) ?? (checklistDone != null),
      shareQuranPages:
          (map['share_quran_pages'] as bool?) ?? (quranPages != null),
    );
  }
}

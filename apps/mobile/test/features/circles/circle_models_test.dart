// Coverage for the circle domain model — the privacy-critical part of
// docs/specs/family-community-features.md: what the leaderboard RPC gives
// back has to stay "hidden" (null) rather than "zero" for signals a member
// didn't opt into sharing (R4/R8), and the streak-match achievement has to
// respect the same rule.

import 'package:flutter_test/flutter_test.dart';
import 'package:takwa/features/circles/domain/circle_models.dart';

void main() {
  CircleMemberRow row(
    String id, {
    Object? currentStreak = _absent,
    Object? totalPoints = _absent,
  }) {
    return CircleMemberRow.fromMap({
      'user_id': id,
      'username': 'member-$id',
      'current_streak': currentStreak == _absent ? null : currentStreak,
      'total_points': totalPoints == _absent ? null : totalPoints,
      'quran_pages': null,
      'checklist_done_today': null,
      'share_streak': currentStreak != null && currentStreak != _absent,
      'share_points': totalPoints != null && totalPoints != _absent,
      'share_checklist_done': false,
      'share_quran_pages': false,
    });
  }

  group('CircleMemberRow.fromMap', () {
    test('an unshared signal stays null, never 0', () {
      final r = row('u1');
      expect(r.currentStreak, isNull);
      expect(r.totalPoints, isNull);
      expect(r.shareStreak, isFalse);
    });

    test('a shared streak of 0 is still 0, not hidden', () {
      final r = row('u1', currentStreak: 0);
      expect(r.currentStreak, 0);
      expect(r.shareStreak, isTrue);
    });

    test('missing share_* flags are inferred from the values present', () {
      final r = CircleMemberRow.fromMap({
        'user_id': 'u1',
        'current_streak': 12,
      });
      expect(r.shareStreak, isTrue);
      expect(r.sharePoints, isFalse);
    });
  });

  group('matchesSharedStreak', () {
    test('matches a peer who shares the same streak', () {
      final rows = [row('me', currentStreak: 7), row('other', currentStreak: 7)];
      expect(
        matchesSharedStreak(rows, myUserId: 'me', myStreak: 7),
        isTrue,
      );
    });

    test('never matches my own row', () {
      final rows = [row('me', currentStreak: 7)];
      expect(
        matchesSharedStreak(rows, myUserId: 'me', myStreak: 7),
        isFalse,
      );
    });

    test('a peer hiding their streak cannot match', () {
      final rows = [row('other')];
      expect(
        matchesSharedStreak(rows, myUserId: 'me', myStreak: 7),
        isFalse,
      );
    });

    test('a zero streak is not an achievement even against a shared zero', () {
      final rows = [row('other', currentStreak: 0)];
      expect(
        matchesSharedStreak(rows, myUserId: 'me', myStreak: 0),
        isFalse,
      );
    });
  });

  group('ReactionPhrase', () {
    test('every key parses back, and free text does not', () {
      for (final phrase in ReactionPhrase.values) {
        expect(ReactionPhrase.fromKey(phrase.key), phrase);
      }
      expect(ReactionPhrase.fromKey('anything_else'), isNull);
    });
  });
}

const _absent = Object();

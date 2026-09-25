// Locks in the corpus invariants the adhkar/dua rewrite depends on.
//
// Two of the bugs this guards against shipped silently: a dhikr filed under a
// category its own `category:` field contradicts (so it appeared in two tabs
// or the wrong one), and truncated/placeholder Arabic in a shipped item.
// `id` is also load-bearing — favorites persist these ints (`favorite_adhkar`,
// `favorite_duas`), so a duplicate id silently merges two users' favorites.
import 'package:flutter_test/flutter_test.dart';
import 'package:takwa/features/adhkar/data/adhkar_data.dart';
import 'package:takwa/features/duas/data/duas_data.dart';

/// The markers a copy-paste or a `.substring()` truncation leaves behind.
bool _hasBadMarker(String text) => const [
  '...',
  'TODO',
  'placeholder',
  'نص الذكر',
  'النص هنا',
].any(text.contains);

void main() {
  group('adhkar corpus', () {
    test(
      'every category is present, non-empty, and holds only its own items',
      () {
        for (final cat in AdhkarCategory.values) {
          final list = kAdhkarData[cat];
          expect(
            list,
            isNotNull,
            reason: '${cat.name} missing from kAdhkarData',
          );
          expect(list!, isNotEmpty, reason: '${cat.name} has no adhkar');
          for (final item in list) {
            expect(
              item.category,
              cat,
              reason:
                  'dhikr ${item.id} is in ${cat.name} but says ${item.category.name}',
            );
          }
        }
      },
    );

    test('ids are unique', () {
      final ids = kAllAdhkar.map((i) => i.id).toList();
      expect(ids.toSet(), hasLength(ids.length));
    });

    test('every dhikr has text, a repetition count and a source', () {
      for (final item in kAllAdhkar) {
        expect(item.arabic.trim(), isNotEmpty, reason: 'dhikr ${item.id}');
        expect(
          _hasBadMarker(item.arabic),
          isFalse,
          reason: 'dhikr ${item.id} has placeholder or truncated text',
        );
        expect(item.count, greaterThan(0), reason: 'dhikr ${item.id}');
        expect(
          item.source?.trim(),
          isNot(isEmpty),
          reason: 'dhikr ${item.id} cites no source',
        );
      }
    });

    test('category labels and icons resolve for every category', () {
      for (final cat in AdhkarCategory.values) {
        expect(cat.arabicLabel, isNotEmpty);
        expect(cat.emoji, isNotEmpty);
      }
    });

    test('misc stays last: callers fall back to it by position', () {
      expect(AdhkarCategory.values.last, AdhkarCategory.misc);
    });
  });

  group('dua corpus', () {
    final all = kDuasData.values.expand((l) => l).toList();

    test(
      'every category is present, non-empty, and holds only its own items',
      () {
        for (final cat in DuaCategory.values) {
          final list = kDuasData[cat];
          expect(list, isNotNull, reason: '${cat.name} missing from kDuasData');
          expect(list!, isNotEmpty, reason: '${cat.name} has no dua');
          for (final item in list) {
            expect(
              item.category,
              cat,
              reason:
                  'dua ${item.id} is in ${cat.name} but says ${item.category.name}',
            );
          }
        }
      },
    );

    test('ids are unique', () {
      final ids = all.map((i) => i.id).toList();
      expect(ids.toSet(), hasLength(ids.length));
    });

    test('every dua has text and a source', () {
      for (final item in all) {
        expect(item.arabic.trim(), isNotEmpty, reason: 'dua ${item.id}');
        expect(
          _hasBadMarker(item.arabic),
          isFalse,
          reason: 'dua ${item.id} has placeholder or truncated text',
        );
        expect(
          item.source.trim(),
          isNot(isEmpty),
          reason: 'dua ${item.id} cites no source',
        );
      }
    });

    test('general stays last: it is the pool callers fall back to', () {
      expect(DuaCategory.values.last, DuaCategory.general);
    });
  });
}

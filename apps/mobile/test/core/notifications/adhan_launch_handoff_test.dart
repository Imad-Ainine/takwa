// The `pending_adhan` marker crosses a process boundary as a raw string:
// OverlayBackgroundService writes it before starting the app, AdhanAutoTrigger
// reads it in the process that starts. A format change on one side alone would
// fail silently, so the encode/decode pair is pinned here.

import 'package:flutter_test/flutter_test.dart';

import 'package:takwa/core/notifications/adhan_auto_trigger.dart';

void main() {
  final at = DateTime.utc(2026, 9, 25, 5, 12, 30);

  String encode({
    String key = 'Fajr',
    String nameAr = 'الفجر',
    DateTime? when,
  }) => AdhanAutoTrigger.pendingAdhanMarker(
    key: key,
    nameAr: nameAr,
    at: when ?? at,
  );

  group('pendingAdhanMarker / parsePendingAdhanMarker', () {
    test('round-trips the prayer key and Arabic name', () {
      final parsed = AdhanAutoTrigger.parsePendingAdhanMarker(
        encode(),
        now: at.add(const Duration(seconds: 2)),
      );
      expect(parsed?.key, 'Fajr');
      expect(parsed?.nameAr, 'الفجر');
    });

    test('reads back a marker the writer encoded from the same instant', () {
      final parsed = AdhanAutoTrigger.parsePendingAdhanMarker(
        encode(key: 'Dhuhr', nameAr: 'الظهر', when: at),
        now: at,
      );
      expect(parsed, (key: 'Dhuhr', nameAr: 'الظهر'));
    });

    test('accepts a marker at the far edge of the TTL', () {
      expect(
        AdhanAutoTrigger.parsePendingAdhanMarker(
          encode(),
          now: at.add(AdhanAutoTrigger.pendingAdhanTtl),
        ),
        isNotNull,
      );
    });

    test('rejects an abandoned marker once the TTL has passed', () {
      expect(
        AdhanAutoTrigger.parsePendingAdhanMarker(
          encode(),
          now: at.add(
            AdhanAutoTrigger.pendingAdhanTtl + const Duration(seconds: 1),
          ),
        ),
        isNull,
      );
    });

    test('rejects a marker from the future', () {
      expect(
        AdhanAutoTrigger.parsePendingAdhanMarker(
          encode(),
          now: at.subtract(const Duration(seconds: 1)),
        ),
        isNull,
      );
    });

    test('rejects absent, empty and malformed markers', () {
      for (final raw in <String?>[
        null,
        '',
        'Fajr|الفجر',
        'Fajr|الفجر|1|2',
        '|الفجر|${at.millisecondsSinceEpoch}',
        'Fajr|الفجر|not-a-timestamp',
      ]) {
        expect(
          AdhanAutoTrigger.parsePendingAdhanMarker(raw, now: at),
          isNull,
          reason: 'should reject $raw',
        );
      }
    });
  });
}

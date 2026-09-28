import 'package:flutter_test/flutter_test.dart';
import 'package:takwa/core/payments/premium_entitlement.dart';

void main() {
  final now = DateTime(2026, 9, 28, 12);
  DateTime daysFromNow(int d) => now.add(Duration(days: d));

  PremiumEntitlement row({
    required String status,
    DateTime? end,
    bool cancelAtPeriodEnd = false,
    bool isTrial = false,
  }) =>
      PremiumEntitlement(
        status: status,
        isTrial: isTrial,
        cancelAtPeriodEnd: cancelAtPeriodEnd,
        currentPeriodEnd: end,
      );

  group('PremiumEntitlement.isActiveAt', () {
    test('active with no known period end stays active', () {
      expect(row(status: 'active').isActiveAt(now), isTrue);
    });

    test('active before period end, expired after it', () {
      expect(row(status: 'active', end: daysFromNow(5)).isActiveAt(now), isTrue);
      expect(row(status: 'active', end: now).isActiveAt(now), isFalse);
    });

    test('trial is access until the trial ends', () {
      expect(row(status: 'trial', end: daysFromNow(3)).isActiveAt(now), isTrue);
      expect(row(status: 'trial', end: now).isActiveAt(now), isFalse);
    });

    test('past_due keeps access only until the paid period lapses', () {
      expect(row(status: 'past_due', end: daysFromNow(2)).isActiveAt(now), isTrue);
      expect(row(status: 'past_due', end: now.subtract(const Duration(days: 1)))
          .isActiveAt(now), isFalse);
      expect(row(status: 'past_due').isActiveAt(now), isFalse);
    });

    test('canceled keeps access until the period already paid for', () {
      expect(
          row(status: 'canceled', end: daysFromNow(10), cancelAtPeriodEnd: true)
              .isActiveAt(now),
          isTrue);
      expect(row(status: 'canceled', end: now).isActiveAt(now), isFalse);
    });

    test('expired and refunded are never active', () {
      expect(row(status: 'expired', end: daysFromNow(30)).isActiveAt(now), isFalse);
      expect(row(status: 'refunded', end: daysFromNow(30)).isActiveAt(now), isFalse);
    });
  });

  group('PremiumEntitlement.fromRow', () {
    test('parses a webhook-written Supabase row', () {
      final e = PremiumEntitlement.fromRow({
        'status': 'trial',
        'is_trial': true,
        'cancel_at_period_end': false,
        'current_period_end': '2026-10-05T00:00:00+00:00',
        'plan_title': 'Monthly',
        'plan_id': '42',
        'source': 'freemius',
        'email': 'A@B.com',
      });
      expect(e.status, 'trial');
      expect(e.isTrial, isTrue);
      expect(e.currentPeriodEnd!.toUtc(), DateTime.utc(2026, 10, 5));
      expect(e.planId, '42');
      expect(e.email, 'A@B.com');
    });

    test('unknown/missing status degrades to a non-active entitlement', () {
      final e = PremiumEntitlement.fromRow({'status': 'garbage'});
      expect(e.isActiveAt(DateTime.now()), isFalse);
      final missing = PremiumEntitlement.fromRow({});
      expect(missing.isActiveAt(DateTime.now()), isFalse);
    });
  });

  test('display collapses stale rows to the ended states', () {
    final lapsed = PremiumEntitlement(
      status: 'active',
      currentPeriodEnd: DateTime(2020),
    );
    expect(lapsed.display, PremiumDisplay.expired);
  });
}

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:takwa/core/payments/subscription_store.dart';

/// The Wise screen was replaced by Freemius, but the historical records it
/// wrote (and the Chargily ones) live in the `premium_payments` settings key
/// on installed devices. Parsing those must never break an old install.
void main() {
  test('legacy wise + chargily records parse alongside new freemius ones', () {
    final legacy = jsonEncode([
      {
        'channel': 'wise',
        'checkoutId': null,
        'status': 'user_declared',
        'amount': 1000,
        'currency': 'eur',
        'at': '2026-09-01T10:00:00.000',
      },
      {
        'channel': 'chargily',
        'checkoutId': 'chk_1',
        'status': 'paid',
        'amount': 20000,
        'currency': 'dzd',
        'at': '2026-09-10T10:00:00.000',
      },
      {
        'channel': 'freemius',
        'checkoutId': '42',
        'status': 'paid',
        'amount': 1000,
        'currency': 'eur',
        'at': '2026-09-27T10:00:00.000',
      },
    ]);

    final payments = (jsonDecode(legacy) as List<dynamic>)
        .map((e) => SupportPayment.fromJson(e as Map<String, dynamic>))
        .toList();

    expect(
      payments.map((p) => p.channel).toList(),
      [SupportChannel.wise, SupportChannel.chargily, SupportChannel.freemius],
    );
    expect(payments[0].status, 'user_declared');
    expect(payments[1].checkoutId, 'chk_1');
    expect(payments[2].amountMinor, 1000);
    expect(payments[2].at, DateTime.parse('2026-09-27T10:00:00.000'));
  });

  test('round-tripping a freemius record preserves the channel', () {
    final p = SupportPayment(
      channel: SupportChannel.freemius,
      checkoutId: '42',
      status: 'paid',
      amountMinor: 1000,
      currency: 'eur',
      at: DateTime(2026, 9, 27),
    );
    final back = SupportPayment.fromJson(
      jsonDecode(jsonEncode(p.toJson())) as Map<String, dynamic>,
    );
    expect(back.channel, SupportChannel.freemius);
    expect(back.currency, 'eur');
  });
}

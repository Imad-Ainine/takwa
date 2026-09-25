// Regression tests for the pure Zakat math in zakat_calculator.dart —
// deliberately Flutter/Drift-free so these run fast and pin down the rules
// (Nisab comparison, Hawl gating, 2.5% rate) independent of any UI.

import 'package:flutter_test/flutter_test.dart';
import 'package:takwa/features/zakat/domain/zakat_calculator.dart';

void main() {
  test('wealth below Nisab: no zakat due, reports the shortfall', () {
    final result = computeZakat(
      const ZakatInputs(
        cashAmount: 100,
        silverPricePerGram: 1, // Nisab = 595 * 1 = 595
        hawlConfirmed: true,
      ),
    );

    expect(result.meetsNisab, isFalse);
    expect(result.zakatDue, isFalse);
    expect(result.amountDue, 0);
    expect(result.shortfallToNisab, 495); // 595 - 100
  });

  test('wealth at/above Nisab with Hawl confirmed: 2.5% is due', () {
    final result = computeZakat(
      const ZakatInputs(
        cashAmount: 1000,
        silverPricePerGram: 1, // Nisab = 595
        hawlConfirmed: true,
      ),
    );

    expect(result.meetsNisab, isTrue);
    expect(result.zakatDue, isTrue);
    expect(result.amountDue, closeTo(25, 0.0001)); // 1000 * 0.025
    expect(result.shortfallToNisab, 0);
  });

  test('wealth above Nisab but Hawl not confirmed: nothing due yet', () {
    final result = computeZakat(
      const ZakatInputs(cashAmount: 1000, silverPricePerGram: 1),
    );

    expect(result.meetsNisab, isTrue);
    expect(result.zakatDue, isFalse);
    expect(result.amountDue, 0);
  });

  test('debt is deducted from zakatable wealth', () {
    final result = computeZakat(
      const ZakatInputs(
        cashAmount: 1000,
        debtAmount: 500,
        silverPricePerGram: 1,
        hawlConfirmed: true,
      ),
    );

    expect(result.netWealth, 500);
    expect(result.meetsNisab, isFalse); // 500 < 595 Nisab
  });

  test('gold and silver values are grams times user-supplied price', () {
    const inputs = ZakatInputs(goldGrams: 10, goldPricePerGram: 70);
    expect(inputs.goldWorth, 700);
  });

  test('a direct value is used when weight or price is missing', () {
    const inputs = ZakatInputs(goldValue: 900, silverValue: 100);
    expect(inputs.goldWorth, 900);
    expect(inputs.silverWorth, 100);
    expect(inputs.netWealth, 1000);
  });

  test('weight x price wins over a stale direct value, never both', () {
    const inputs = ZakatInputs(
      goldGrams: 10,
      goldPricePerGram: 70,
      goldValue: 5000,
    );
    expect(inputs.goldWorth, 700);
    expect(inputs.netWealth, 700);
  });

  test('no price supplied yields a zero Nisab threshold, not a false match', () {
    final result = computeZakat(
      const ZakatInputs(cashAmount: 100, hawlConfirmed: true),
    );
    expect(result.nisabThreshold, 0);
    expect(result.meetsNisab, isFalse);
  });

  test('gold Nisab basis uses the 85g threshold', () {
    final result = computeZakat(
      const ZakatInputs(
        cashAmount: 10000,
        goldPricePerGram: 100, // Nisab = 85 * 100 = 8500
        nisabBasis: ZakatNisabBasis.gold,
        hawlConfirmed: true,
      ),
    );
    expect(result.nisabThreshold, 8500);
    expect(result.meetsNisab, isTrue);
  });
}

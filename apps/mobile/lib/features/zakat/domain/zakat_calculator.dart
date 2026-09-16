/// Pure Zakat al-Mal math — kept free of Flutter/Drift so it's trivially
/// unit-testable and the single source of truth for both the live
/// calculator screen and (if ever needed) a re-derivation from history.
/// See docs/specs/zakat-calculator.md.
library;

/// Standard Nisab weights in grams, per the two commonly cited thresholds.
/// Silver is the more cautious/inclusive standard (lower zakatable floor)
/// and is what the calculator defaults to — see the spec's Goals section.
const double nisabGoldGrams = 85.0;
const double nisabSilverGrams = 595.0;

const double zakatRate = 0.025; // 2.5%

enum ZakatNisabBasis { gold, silver }

class ZakatInputs {
  final double cashAmount;
  final double bankAmount;
  final double goldGrams;
  final double goldPricePerGram;
  final double silverGrams;
  final double silverPricePerGram;
  final double tradeGoodsValue;
  final double debtAmount;
  final ZakatNisabBasis nisabBasis;
  final bool hawlConfirmed;

  const ZakatInputs({
    this.cashAmount = 0,
    this.bankAmount = 0,
    this.goldGrams = 0,
    this.goldPricePerGram = 0,
    this.silverGrams = 0,
    this.silverPricePerGram = 0,
    this.tradeGoodsValue = 0,
    this.debtAmount = 0,
    this.nisabBasis = ZakatNisabBasis.silver,
    this.hawlConfirmed = false,
  });

  double get goldValue => goldGrams * goldPricePerGram;
  double get silverValue => silverGrams * silverPricePerGram;

  /// Total assets minus deductible short-term debt. Can be negative if debt
  /// exceeds assets — callers should clamp for display, not silently floor
  /// it here (a negative value is meaningful: it shows the shortfall).
  double get netWealth =>
      cashAmount + bankAmount + goldValue + silverValue + tradeGoodsValue - debtAmount;
}

class ZakatResult {
  final double netWealth;
  final double nisabThreshold;
  final bool meetsNisab;
  final bool zakatDue;
  final double amountDue;

  /// How much more wealth is needed to reach Nisab. Zero once/if Nisab is
  /// already met.
  final double shortfallToNisab;

  const ZakatResult({
    required this.netWealth,
    required this.nisabThreshold,
    required this.meetsNisab,
    required this.zakatDue,
    required this.amountDue,
    required this.shortfallToNisab,
  });
}

/// Nisab threshold in the same currency as [pricePerGram], or 0 if no price
/// was supplied yet (nothing to compare against — the caller decides how to
/// present that, this stays a pure function).
double nisabThresholdFor(ZakatNisabBasis basis, {
  required double goldPricePerGram,
  required double silverPricePerGram,
}) {
  return switch (basis) {
    ZakatNisabBasis.gold => nisabGoldGrams * goldPricePerGram,
    ZakatNisabBasis.silver => nisabSilverGrams * silverPricePerGram,
  };
}

ZakatResult computeZakat(ZakatInputs inputs) {
  final nisab = nisabThresholdFor(
    inputs.nisabBasis,
    goldPricePerGram: inputs.goldPricePerGram,
    silverPricePerGram: inputs.silverPricePerGram,
  );
  final wealth = inputs.netWealth;
  final meetsNisab = nisab > 0 && wealth >= nisab;
  final due = meetsNisab && inputs.hawlConfirmed;

  return ZakatResult(
    netWealth: wealth,
    nisabThreshold: nisab,
    meetsNisab: meetsNisab,
    zakatDue: due,
    amountDue: due ? wealth * zakatRate : 0,
    shortfallToNisab: meetsNisab ? 0 : (nisab - wealth).clamp(0, double.infinity),
  );
}

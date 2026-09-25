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

  /// Value typed in directly, for users who know what their gold is worth but
  /// not what it weighs. Used only when the weight×price route is unavailable.
  final double goldValue;

  final double silverGrams;
  final double silverPricePerGram;
  final double silverValue;
  final double tradeGoodsValue;
  final double debtAmount;
  final ZakatNisabBasis nisabBasis;
  final bool hawlConfirmed;

  const ZakatInputs({
    this.cashAmount = 0,
    this.bankAmount = 0,
    this.goldGrams = 0,
    this.goldPricePerGram = 0,
    this.goldValue = 0,
    this.silverGrams = 0,
    this.silverPricePerGram = 0,
    this.silverValue = 0,
    this.tradeGoodsValue = 0,
    this.debtAmount = 0,
    this.nisabBasis = ZakatNisabBasis.silver,
    this.hawlConfirmed = false,
  });

  /// Weight × the entered price per gram wins whenever both are known, so
  /// reusing a saved calculation can't silently double-count the metal.
  double get goldWorth =>
      (goldGrams > 0 && goldPricePerGram > 0)
          ? goldGrams * goldPricePerGram
          : goldValue;

  double get silverWorth =>
      (silverGrams > 0 && silverPricePerGram > 0)
          ? silverGrams * silverPricePerGram
          : silverValue;

  /// Total assets minus deductible short-term debt. Can be negative if debt
  /// exceeds assets — callers should clamp for display, not silently floor
  /// it here (a negative value is meaningful: it shows the shortfall).
  double get netWealth =>
      cashAmount +
      bankAmount +
      goldWorth +
      silverWorth +
      tradeGoodsValue -
      debtAmount;
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

// ---------------------------------------------------------------------------
// Zakat al-Fitr
// ---------------------------------------------------------------------------

class ZakatFitrahInputs {
  /// Number of household members. Valid range: 1–99.
  final int members;

  /// Local staple-food price per person. Valid range: 0.01–999,999.99.
  final double pricePerPerson;

  /// Optional currency label for display purposes.
  final String currencyLabel;

  const ZakatFitrahInputs({
    required this.members,
    required this.pricePerPerson,
    this.currencyLabel = '',
  });
}

class ZakatFitrahResult {
  /// `members * pricePerPerson` rounded to 2 decimal places, or 0 when invalid.
  final double totalDue;

  /// `false` if either input is out of its valid range.
  final bool isValid;

  const ZakatFitrahResult({required this.totalDue, required this.isValid});
}

/// Computes Zakat al-Fitr for [inputs].
///
/// Returns `isValid = true` and `totalDue` rounded to 2 dp when:
///   - `members` is in [1, 99]
///   - `pricePerPerson` is in [0.01, 999,999.99]
///
/// Returns `isValid = false` and `totalDue = 0` otherwise.
ZakatFitrahResult computeZakatFitrah(ZakatFitrahInputs inputs) {
  final validMembers = inputs.members >= 1 && inputs.members <= 99;
  final validPrice =
      inputs.pricePerPerson >= 0.01 && inputs.pricePerPerson <= 999999.99;

  if (!validMembers || !validPrice) {
    return const ZakatFitrahResult(totalDue: 0, isValid: false);
  }

  final raw = inputs.members * inputs.pricePerPerson;
  // Round to 2 decimal places.
  final rounded = (raw * 100).round() / 100;
  return ZakatFitrahResult(totalDue: rounded, isValid: true);
}

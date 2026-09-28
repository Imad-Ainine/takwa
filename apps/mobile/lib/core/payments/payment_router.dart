/// Decides which payment rail (Chargily for Algeria, Freemius for the rest
/// of the world) a user should be routed to. Pure function, unit-tested.
///
/// There is no GPS/SIM lookup on purpose: the only payment-relevant country
/// signal the app can ask for without a permission prompt is the device
/// region, and that is exactly enough to pick a default. A manual override
/// (stored under [settingsOverrideKey] in the settings DAO) always wins, so
/// a misdetected traveler or an Algerian abroad is never locked out.
library;

enum PaymentRail { chargily, freemius }

class PaymentRouting {
  PaymentRouting._();

  /// Value stored under this settings key: `null`/`''` = auto,
  /// `'dz'` = Algeria (Chargily), `'intl'` = international (Freemius).
  static const settingsOverrideKey = 'payment_country_override';

  static PaymentRail suggest({
    String? countryCode,
    String? languageCode,
    String? overrideValue,
  }) {
    switch (overrideValue) {
      case 'dz':
        return PaymentRail.chargily;
      case 'intl':
        return PaymentRail.freemius;
    }
    final cc = (countryCode ?? '').toUpperCase();
    if (cc == 'DZ') return PaymentRail.chargily;
    // No usable region (bare `ar` locales are common on budget devices):
    // the app's primary audience is Algeria, so keep Chargily the default
    // rather than pushing an untested rail on ambiguous users.
    if (cc.isEmpty && (languageCode ?? '') == 'ar') return PaymentRail.chargily;
    return PaymentRail.freemius;
  }
}

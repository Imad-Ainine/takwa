import 'package:flutter_test/flutter_test.dart';
import 'package:takwa/core/payments/payment_router.dart';

void main() {
  group('PaymentRouting.suggest', () {
    test('Algerian device region goes to Chargily', () {
      expect(
        PaymentRouting.suggest(countryCode: 'DZ', languageCode: 'ar'),
        PaymentRail.chargily,
      );
      // country codes arrive lowercase from some locales
      expect(
        PaymentRouting.suggest(countryCode: 'dz', languageCode: 'fr'),
        PaymentRail.chargily,
      );
    });

    test('any other detected region goes to Freemius', () {
      expect(
        PaymentRouting.suggest(countryCode: 'FR', languageCode: 'ar'),
        PaymentRail.freemius,
      );
      expect(
        PaymentRouting.suggest(countryCode: 'DE', languageCode: 'de'),
        PaymentRail.freemius,
      );
    });

    test('unknown region with Arabic language keeps the Chargily default', () {
      // The app's primary audience is Algeria; ambiguous locales must not be
      // pushed onto the international rail by accident.
      expect(
        PaymentRouting.suggest(countryCode: '', languageCode: 'ar'),
        PaymentRail.chargily,
      );
      expect(PaymentRouting.suggest(languageCode: 'ar'), PaymentRail.chargily);
    });

    test('unknown region with a non-Arabic language goes to Freemius', () {
      expect(
        PaymentRouting.suggest(countryCode: '', languageCode: 'en'),
        PaymentRail.freemius,
      );
    });

    test('manual override always wins over detection', () {
      // Algerian abroad stays on Freemius…
      expect(
        PaymentRouting.suggest(
          countryCode: 'DZ',
          languageCode: 'ar',
          overrideValue: 'intl',
        ),
        PaymentRail.freemius,
      );
      // …and a misdetected traveler can force Chargily.
      expect(
        PaymentRouting.suggest(
          countryCode: 'CA',
          languageCode: 'fr',
          overrideValue: 'dz',
        ),
        PaymentRail.chargily,
      );
    });

    test('empty override value behaves like auto', () {
      expect(
        PaymentRouting.suggest(countryCode: 'DZ', overrideValue: ''),
        PaymentRail.chargily,
      );
    });
  });
}

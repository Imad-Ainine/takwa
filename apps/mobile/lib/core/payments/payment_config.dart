import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Chargily Pay V2 (CIB / Edahabia) configuration.
///
/// The app talks to Chargily exclusively through the Takwa web app's
/// checkout proxy (`/api/payments/checkout`, see apps/web
/// `src/app/api/payments/checkout`), which holds the Chargily SECRET key
/// server-side. NO Chargily credentials ship in the app — an APK-embedded
/// secret key would let anyone create/refund checkouts as the merchant.
///
/// The proxy also owns the charged amount and the success/failure redirect
/// URLs; the values below are display/local-record only.
class ChargilyConfig {
  ChargilyConfig._();

  /// Checkout amount in whole DZD (major units), mirrored from the proxy's
  /// `CHARGILY_SUBSCRIPTION_AMOUNT` — used for local payment records and UI
  /// display only; the server decides what is actually charged.
  static int get subscriptionAmountDzd =>
      int.tryParse(dotenv.env['CHARGILY_SUBSCRIPTION_AMOUNT'] ?? '') ?? 200;

  /// Same amount in centime (minor units) for local payment records.
  static int get subscriptionAmountCentime => subscriptionAmountDzd * 100;

  /// Base URL of the deployed web app, which hosts the checkout proxy and
  /// the `/payment-redirect` hop that bounces the browser back into the app
  /// after the card attempt (Chargily only accepts http(s) callbacks).
  static String get webBaseUrl =>
      dotenv.env['TAKWA_WEB_BASE_URL'] ?? 'https://takwa-web.vercel.app';
}

/// Freemius (Visa / Mastercard, international supporters) configuration.
///
/// The app never talks to Freemius directly: it asks the Takwa web app's
/// proxy (`/api/payments/freemius/*`, see apps/web) which holds the
/// Freemius keys server-side and returns a hosted-checkout URL — the same
/// no-secrets-in-APK rule as Chargily. Freemius reports the real plan and
/// price on its hosted page; the values below are display-only mirrors.
class FreemiusConfig {
  FreemiusConfig._();

  /// Monthly plan price in euros, e.g. `10` — display/local-record only;
  /// the Freemius plan (FREEMIUS_MONTHLY_PLAN_ID) decides what is charged.
  static double get monthlyEur =>
      double.tryParse(dotenv.env['FREEMIUS_MONTHLY_EUR'] ?? '') ?? 10.0;

  /// The Freemius plan bills in EUR; recorded with each local payment so the
  /// history never implies a currency the checkout did not charge.
  static const String currencyCode = 'eur';

  static String get monthlyDisplay => '€${monthlyEur.toStringAsFixed(2)}';

  /// Same web app that hosts the Chargily proxy and the payment-redirect hop.
  static String get webBaseUrl => ChargilyConfig.webBaseUrl;
}

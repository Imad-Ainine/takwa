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

/// Wise account details for the Visa/Mastercard path. The app never touches
/// card data: the user transfers to this account from within Wise
/// themselves, so these are display-only public recipient details.
/// Fill the WISE_* keys in `.env` when ready; until then the Wise flow
/// shows a "not configured yet" notice instead of breaking.
class WiseConfig {
  WiseConfig._();

  static String get iban => dotenv.env['WISE_IBAN'] ?? '';
  static String get accountNumber => dotenv.env['WISE_ACCOUNT_NUMBER'] ?? '';
  static String get sortCode => dotenv.env['WISE_SORT_CODE'] ?? '';
  static String get holderName => dotenv.env['WISE_HOLDER_NAME'] ?? '';
  static String get bankName => dotenv.env['WISE_BANK_NAME'] ?? '';

  /// Optional `wise.com/pay/me/…` or `wise.com/profile/…` link that opens
  /// the recipient profile directly in the Wise app / site.
  static String get profileLink => dotenv.env['WISE_PROFILE_LINK'] ?? '';

  /// Monthly amount in euro, e.g. `10`.
  static double get monthlyEur =>
      double.tryParse(dotenv.env['WISE_MONTHLY_EUR'] ?? '') ?? 10.0;

  /// Reference text the user should put on the transfer so incoming
  /// payments can be matched on the account statement.
  static String get paymentReference =>
      dotenv.env['WISE_PAYMENT_REFERENCE'] ?? 'TAKWA';

  static bool get isConfigured =>
      iban.isNotEmpty || accountNumber.isNotEmpty || profileLink.isNotEmpty;
}

import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Chargily Pay V2 (CIB / Edahabia) configuration, read from the app's
/// git-ignored `.env` — same pattern as [SupabaseConfig].
///
/// Chargily issues two credentials per project (Developers corner in the
/// Chargily Pay dashboard):
/// - `CHARGILY_SECRET_KEY` (`test_sk_…` / `sk_…`): the only key accepted as
///   the `Authorization: Bearer …` header on the REST API.
/// - `CHARGILY_PUBLIC_KEY` (`test_pk_…` / `pk_…`): client-side identifier,
///   safe to ship in the app; required for the checkout widget flow.
///
/// IMPORTANT: the SECRET key still ships inside local/dev builds through
/// `.env` (which already carries the Supabase service-role key). Before a
/// Play Store release, move the `createCheckout` call into a Supabase Edge
/// Function and point [apiBase] at that proxy — [ChargilyService] is a plain
/// class injected into the UI exactly so that swap is a one-file change.
class ChargilyConfig {
  ChargilyConfig._();

  /// `true` for live mode, `false`/unset for test mode.
  static bool get isLive =>
      (dotenv.env['CHARGILY_LIVE'] ?? '').toLowerCase() == 'true';

  static String get apiBase =>
      isLive
          ? 'https://pay.chargily.com/api/v2'
          : 'https://pay.chargily.com/test/api/v2';

  /// Secret bearer token from the Chargily dashboard (Developers corner).
  /// Used only for server-to-server calls ([ChargilyService]); never shown
  /// to the user.
  static String get secretKey =>
      dotenv.env['CHARGILY_SECRET_KEY'] ??
      (throw StateError(
        'CHARGILY_SECRET_KEY is missing — add it to apps/mobile/.env to '
        'enable CIB/Edahabia payments (see README "Environment variables").',
      ));

  /// Public (publishable) key from the same dashboard page. Kept available
  /// for client-side identification and widget-based checkout flows.
  static String get publicKey => dotenv.env['CHARGILY_PUBLIC_KEY'] ?? '';

  /// Optional override; defaults to 200 centime = 200.00 DZD.
  static int get subscriptionAmountCentime =>
      int.tryParse(dotenv.env['CHARGILY_SUBSCRIPTION_AMOUNT'] ?? '') ?? 200;

  /// Base URL of the deployed web app. Chargily only accepts http(s)
  /// success/failure URLs, so checkouts redirect to the web app's
  /// `/payment-redirect` hop, which forwards the browser to the app's
  /// custom scheme (see apps/web src/app/[locale]/payment-redirect).
  static String get webBaseUrl =>
      dotenv.env['TAKWA_WEB_BASE_URL'] ?? 'https://takwa-web.vercel.app';

  /// Builds the https callback URL that bounces [appSchemeUrl] back into
  /// the app, localized to the web app's supported locales.
  static String webRedirectUrl(String appSchemeUrl, {required String locale}) {
    const supported = {'ar', 'en', 'fr'};
    final loc = supported.contains(locale) ? locale : 'en';
    return Uri.parse('$webBaseUrl/$loc/payment-redirect').replace(
      queryParameters: {'to': appSchemeUrl},
    ).toString();
  }

  /// The secret key is what actually gates API access; the public key
  /// should be set alongside it but does not block the flow.
  static bool get isConfigured =>
      (dotenv.env['CHARGILY_SECRET_KEY'] ?? '').isNotEmpty;
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

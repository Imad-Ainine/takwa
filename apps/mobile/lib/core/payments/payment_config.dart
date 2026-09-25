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

  /// The host the REST API actually answers on (dev.chargily.com docs:
  /// "Test Mode Base Url https://pay.chargily.net/test/api/v2"). `pay.chargily
  /// .com` is not it — it never completes a TCP handshake, so every checkout
  /// sat until the request timeout and the UI showed
  /// "TimeoutException after 0:00:20: Future not completed". The hosted
  /// checkout *page* comes back on another host (`pay.chargily.dz` in
  /// `checkout_url`); see [ChargilyCheckout] for why the app rewrites it to
  /// this host before opening it.
  static String get apiBase => isLive
      ? 'https://pay.chargily.net/api/v2'
      : 'https://pay.chargily.net/test/api/v2';

  /// Secret bearer token from the Chargily dashboard (Developers corner).
  /// Used only for server-to-server calls ([ChargilyService]); never shown
  /// to the user. An empty value throws like a missing one — CI writes
  /// `CHARGILY_SECRET_KEY=` into the bundled .env when the GitHub secret
  /// is absent, and an empty Bearer token only surfaces as a confusing
  /// Chargily 401 at payment time.
  static String get secretKey {
    final key = dotenv.env['CHARGILY_SECRET_KEY'];
    if (key == null || key.isEmpty) {
      throw StateError(
        'CHARGILY_SECRET_KEY is missing or empty — add it to '
        'apps/mobile/.env (and to the GitHub Actions secrets for release '
        'builds) to enable CIB/Edahabia payments; see README '
        '"Environment variables".',
      );
    }
    return key;
  }

  /// Public (publishable) key from the same dashboard page. Kept available
  /// for client-side identification and widget-based checkout flows.
  static String get publicKey => dotenv.env['CHARGILY_PUBLIC_KEY'] ?? '';

  /// Checkout amount in whole DZD (major units) as sent to Chargily V2 —
  /// the API takes dinars, not centimes: the hosted page echoes the value
  /// verbatim (sending 20000 displayed as 20,000.00 DZD). Optional
  /// override; defaults to 200 DZD.
  static int get subscriptionAmountDzd =>
      int.tryParse(dotenv.env['CHARGILY_SUBSCRIPTION_AMOUNT'] ?? '') ?? 200;

  /// Same amount in centime (minor units) for local payment records.
  static int get subscriptionAmountCentime => subscriptionAmountDzd * 100;

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
    return Uri.parse(
      '$webBaseUrl/$loc/payment-redirect',
    ).replace(queryParameters: {'to': appSchemeUrl}).toString();
  }

  /// The secret key is what actually gates API access; the public key
  /// should be set alongside it but does not block the flow.
  static bool get isConfigured {
    try {
      return secretKey.isNotEmpty;
    } on StateError {
      return false;
    }
  }
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

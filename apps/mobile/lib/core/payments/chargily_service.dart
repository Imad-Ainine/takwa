import 'dart:convert';

import 'package:http/http.dart' as http;

import 'payment_config.dart';

/// Result of creating a Chargily checkout: enough to open the hosted page
/// and to poll this checkout's status afterwards.
class ChargilyCheckout {
  final String id;
  final Uri checkoutUrl;
  final String status;

  const ChargilyCheckout({
    required this.id,
    required this.checkoutUrl,
    required this.status,
  });

  bool get isPaid => status == 'paid';

  factory ChargilyCheckout.fromJson(Map<String, dynamic> json) {
    return ChargilyCheckout(
      id: json['id'] as String,
      checkoutUrl: _hostedCheckoutUrl(json['checkout_url'] as String? ?? ''),
      status: json['status'] as String? ?? 'pending',
    );
  }

  /// The checkout proxy already normalizes the hosted page URL, but keep the
  /// rewrite client-side too so a raw Chargily response can never open a
  /// non-https link (Android Custom Tabs refuse those) or the
  /// `pay.chargily.dz` host, which does not complete a TCP handshake from
  /// every network (measured: 20s connect timeout, IPv4 and IPv6) — the
  /// identical page is served on `pay.chargily.net`.
  static Uri _hostedCheckoutUrl(String raw) {
    final parsed = Uri.parse(raw);
    var url = parsed;
    if (parsed.host == 'pay.chargily.dz') {
      url = url.replace(host: 'pay.chargily.net');
    }
    if (url.scheme == 'http') url = url.replace(scheme: 'https');
    return url;
  }
}

/// Client for the Takwa web app's checkout proxy
/// (`POST/GET /api/payments/checkout`), which holds the Chargily SECRET key
/// server-side. The app itself ships no Chargily credentials: the proxy owns
/// the amount and the success/failure redirect URLs, and this client only
/// passes display hints (payment method, description, locale).
///
/// Pass a custom [client]/[baseUrl] in tests.
class ChargilyService {
  ChargilyService({http.Client? client, String? baseUrl})
    : _client = client ?? http.Client(),
      _baseUrlOverride = baseUrl;

  final http.Client _client;
  final String? _baseUrlOverride;

  /// Without this the UI would sit on "Preparing the checkout…" forever if
  /// the device's network stalls.
  static const _timeout = Duration(seconds: 20);

  String get _baseUrl =>
      _baseUrlOverride ?? '${ChargilyConfig.webBaseUrl}/api/payments/checkout';

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  /// Creates a checkout for the monthly support amount and returns the
  /// hosted payment page URL to open in the browser / in-app checkout view.
  /// After the card attempt the proxy's redirect hop brings the browser back
  /// into the app via `takwa://payment-success` / `takwa://payment-failure`.
  Future<ChargilyCheckout> createCheckout({
    String paymentMethod = 'edahabia',
    String? description,
    String? locale,
  }) async {
    final body = <String, dynamic>{
      'payment_method': paymentMethod,
      if (description != null) 'description': description,
      if (locale != null) 'locale': locale,
    };
    final res = await _client
        .post(Uri.parse(_baseUrl), headers: _headers, body: jsonEncode(body))
        .timeout(_timeout);
    _ensureOk(res, 'create checkout');
    return ChargilyCheckout.fromJson(
      jsonDecode(res.body) as Map<String, dynamic>,
    );
  }

  /// Reads a checkout back by id — `status` is one of pending / processing /
  /// paid / failed / canceled. Used to verify the payment after the hosted
  /// page redirects back, since the redirect alone is not proof of payment.
  Future<ChargilyCheckout> fetchCheckout(String id) async {
    final res = await _client
        .get(Uri.parse('$_baseUrl/${Uri.encodeComponent(id)}'), headers: _headers)
        .timeout(_timeout);
    _ensureOk(res, 'fetch checkout');
    return ChargilyCheckout.fromJson(
      jsonDecode(res.body) as Map<String, dynamic>,
    );
  }

  void _ensureOk(http.Response res, String what) {
    if (res.statusCode >= 200 && res.statusCode < 300) return;
    throw ChargilyException(what, res.statusCode, res.body);
  }
}

class ChargilyException implements Exception {
  final String operation;
  final int statusCode;
  final String body;
  const ChargilyException(this.operation, this.statusCode, this.body);

  @override
  String toString() => 'Chargily $operation failed ($statusCode): $body';
}

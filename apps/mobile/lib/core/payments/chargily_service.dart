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

  /// Chargily hands back an `http://` checkout URL; Android Custom Tabs
  /// silently refuse non-https links, so upgrade to https (the page serves
  /// it fine) before anyone tries to open it.
  static Uri _hostedCheckoutUrl(String raw) {
    final url = Uri.parse(raw);
    return url.scheme == 'http' ? url.replace(scheme: 'https') : url;
  }
}

/// Thin client over Chargily Pay V2's checkout endpoints.
///
/// All calls authenticate with the SECRET key (`CHARGILY_SECRET_KEY`,
/// `Bearer …` header) as required by the REST API; the public key is only
/// used client-side. Test mode is the default; set `CHARGILY_LIVE=true` in
/// `.env` for production. Pass a custom [client] in tests.
class ChargilyService {
  ChargilyService({http.Client? client, String? baseUrl, String? secretKey})
    : _client = client ?? http.Client(),
      _baseUrlOverride = baseUrl,
      _secretKeyOverride = secretKey;

  final http.Client _client;
  final String? _baseUrlOverride;
  final String? _secretKeyOverride;

  /// Without this the UI would sit on "Preparing the checkout…" forever if
  /// the device's network stalls.
  static const _timeout = Duration(seconds: 20);

  String get _baseUrl => _baseUrlOverride ?? ChargilyConfig.apiBase;
  String get _secretKey => _secretKeyOverride ?? ChargilyConfig.secretKey;

  Map<String, String> get _headers => {
    'Authorization': 'Bearer $_secretKey',
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  /// Creates a checkout for the monthly support amount (in centime, as
  /// Chargily expects integer minor units) and returns the hosted payment
  /// page URL to open in the browser / in-app checkout view.
  ///
  /// [successUrl]/[failureUrl] are where Chargily's page redirects the
  /// browser after the card attempt — custom app scheme links
  /// (`takwa://payment-success`) work and bring the user back to the app.
  Future<ChargilyCheckout> createCheckout({
    int? amount,
    String currency = 'dzd',
    String paymentMethod = 'edahabia',
    String? description,
    String? successUrl,
    String? failureUrl,
    String? locale,
    Map<String, String>? metadata,
  }) async {
    final body = <String, dynamic>{
      'amount': amount ?? ChargilyConfig.subscriptionAmountCentime,
      'currency': currency,
      'payment_method': paymentMethod,
      if (description != null) 'description': description,
      if (successUrl != null) 'success_url': successUrl,
      if (failureUrl != null) 'failure_url': failureUrl,
      if (locale != null) 'locale': locale,
      if (metadata != null) 'metadata': metadata,
    };
    final res = await _client
        .post(Uri.parse('$_baseUrl/checkouts'), headers: _headers, body: jsonEncode(body))
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
        .get(Uri.parse('$_baseUrl/checkouts/$id'), headers: _headers)
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

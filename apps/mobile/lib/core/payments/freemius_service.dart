import 'dart:convert';

import 'package:http/http.dart' as http;

import 'payment_config.dart';

/// A Freemius hosted-checkout session handed back by the Takwa web proxy.
class FreemiusSession {
  final Uri checkoutUrl;
  final String planId;

  const FreemiusSession({required this.checkoutUrl, required this.planId});

  factory FreemiusSession.fromJson(Map<String, dynamic> json) => FreemiusSession(
    checkoutUrl: Uri.parse(json['checkout_url'] as String),
    planId: json['plan_id'] as String? ?? '',
  );
}

/// The Freemius customer portal (cancel / renew / update card), built
/// server-side from the Freemius product id + publishable key.
class FreemiusPortal {
  final Uri url;
  const FreemiusPortal({required this.url});

  factory FreemiusPortal.fromJson(Map<String, dynamic> json) =>
      FreemiusPortal(url: Uri.parse(json['portal_url'] as String));
}

/// Client for the Takwa web app's Freemius proxy
/// (`/api/payments/freemius/*`). The app ships no Freemius credentials —
/// same rule as the Chargily proxy client — and authenticates with the
/// signed-in user's Supabase access token, which is what ties the purchase
/// (and the entitlement the webhook writes) to this account.
class FreemiusService {
  FreemiusService({http.Client? client, String? baseUrl})
    : _client = client ?? http.Client(),
      _baseUrlOverride = baseUrl;

  final http.Client _client;
  final String? _baseUrlOverride;

  /// Matches the Chargily client: without it the UI could sit on
  /// "Preparing the checkout…" forever behind a stalled socket.
  static const _timeout = Duration(seconds: 20);

  String get _baseUrl => _baseUrlOverride ?? '${FreemiusConfig.webBaseUrl}/api/payments/freemius';

  Map<String, String> _headers(String accessToken) => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    'Authorization': 'Bearer $accessToken',
  };

  /// New subscription checkout. [accessToken] is the Supabase session token;
  /// a null/empty one is rejected client-side because the proxy answers
  /// 401 `sign_in_required` anyway and the UI wants to distinguish "not
  /// signed in" from "payment failed".
  Future<FreemiusSession> createCheckout({
    required String accessToken,
    String? planId,
    String? locale,
  }) {
    return _postSession(
      'checkout',
      accessToken,
      <String, dynamic>{
        if (planId != null) 'plan_id': planId,
        if (locale != null) 'locale': locale,
      },
    );
  }

  /// Upgrade/downgrade of an existing Freemius license (prorated checkout).
  Future<FreemiusSession> changePlan({
    required String accessToken,
    required String planId,
    String? locale,
  }) {
    return _postSession(
      'change-plan',
      accessToken,
      <String, dynamic>{'plan_id': planId, if (locale != null) 'locale': locale},
    );
  }

  Future<FreemiusPortal> portal({required String accessToken, String? locale}) async {
    final res = await _client
        .post(
          Uri.parse('$_baseUrl/portal'),
          headers: _headers(accessToken),
          body: jsonEncode(<String, dynamic>{if (locale != null) 'locale': locale}),
        )
        .timeout(_timeout);
    _ensureOk(res, 'portal');
    return FreemiusPortal.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  Future<FreemiusSession> _postSession(
    String path,
    String accessToken,
    Map<String, dynamic> body,
  ) async {
    if (accessToken.trim().isEmpty) {
      throw const FreemiusException('create checkout', 401, 'sign_in_required');
    }
    final res = await _client
        .post(Uri.parse('$_baseUrl/$path'), headers: _headers(accessToken), body: jsonEncode(body))
        .timeout(_timeout);
    _ensureOk(res, path);
    return FreemiusSession.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  void _ensureOk(http.Response res, String what) {
    if (res.statusCode >= 200 && res.statusCode < 300) return;
    String? code;
    try {
      code = (jsonDecode(res.body) as Map<String, dynamic>)['error'] as String?;
    } catch (_) {
      // Not the proxy answering. An undeployed route returns Next's HTML 404
      // document, which must not be dumped verbatim into the payment screen.
      final body = res.body.trim();
      code = body.startsWith('<') ? null : _snippet(body);
    }
    throw FreemiusException(what, res.statusCode, code ?? 'http_${res.statusCode}');
  }

  static String _snippet(String body) =>
      body.length <= 120 ? body : '${body.substring(0, 120)}…';
}

class FreemiusException implements Exception {
  final String operation;
  final int statusCode;

  /// Machine-readable proxy error (`sign_in_required`, `plan_not_allowed`,
  /// `payments_not_configured`, …) when the proxy sent one.
  final String code;

  const FreemiusException(this.operation, this.statusCode, this.code);

  bool get isSignInRequired => code == 'sign_in_required';

  @override
  String toString() => 'Freemius $operation failed ($statusCode): $code';
}

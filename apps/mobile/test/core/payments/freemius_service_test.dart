import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:takwa/core/payments/freemius_service.dart';
import 'package:takwa/core/payments/payment_config.dart';

/// Captures the outgoing request and replies with a canned response.
class _StubClient extends http.BaseClient {
  http.BaseRequest? lastRequest;
  String? lastBody;
  http.Response nextResponse = http.Response(
    '{"checkout_url":"https://checkout.freemius.com/app/1234/plan/5678/","plan_id":"5678"}',
    200,
  );

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    lastRequest = request;
    if (request is http.Request) lastBody = utf8.decode(request.bodyBytes);
    return http.StreamedResponse(
      Stream.value(nextResponse.bodyBytes),
      nextResponse.statusCode,
    );
  }
}

void main() {
  late _StubClient client;
  late FreemiusService service;

  setUp(() {
    dotenv.loadFromString(envString: 'TAKWA_TEST_PLACEHOLDER=1');
    client = _StubClient();
    service = FreemiusService(
      client: client,
      baseUrl: 'https://takwa-web.vercel.app/api/payments/freemius',
    );
  });

  group('FreemiusService', () {
    test('createCheckout authenticates with the Supabase token only', () async {
      await service.createCheckout(accessToken: 'sat_abc', locale: 'ar');

      final request = client.lastRequest!;
      expect(request.method, 'POST');
      expect(request.url.path, '/api/payments/freemius/checkout');
      expect(request.headers['Authorization'], 'Bearer sat_abc');
      // The Freemius keys live on the proxy; nothing Freemius-credential-ish
      // may ever leave the app.
      final body = jsonDecode(client.lastBody!) as Map<String, dynamic>;
      expect(body.containsKey('locale'), isTrue);
      expect(body.containsKey('public_key'), isFalse);
      expect(body.containsKey('secret_key'), isFalse);
      expect(body.containsKey('custom'), isFalse); // server injects the user id
    });

    test('createCheckout rejects an empty token before any network call',
        () async {
      expect(
        service.createCheckout(accessToken: '  '),
        throwsA(
          isA<FreemiusException>()
              .having((e) => e.statusCode, 'statusCode', 401)
              .having((e) => e.isSignInRequired, 'isSignInRequired', isTrue),
        ),
      );
      expect(client.lastRequest, isNull);
    });

    test('parses the session response into an https checkout URL', () async {
      final session = await service.createCheckout(accessToken: 'sat_abc');
      expect(session.checkoutUrl.scheme, 'https');
      expect(session.checkoutUrl.host, 'checkout.freemius.com');
      expect(session.planId, '5678');
    });

    test('changePlan posts the plan id to the change-plan route', () async {
      await service.changePlan(accessToken: 'sat_abc', planId: '9999');
      expect(client.lastRequest!.url.path,
          '/api/payments/freemius/change-plan');
      final body = jsonDecode(client.lastBody!) as Map<String, dynamic>;
      expect(body['plan_id'], '9999');
    });

    test('proxy error codes are surfaced machine-readably', () async {
      client.nextResponse = http.Response('{"error":"sign_in_required"}', 401);
      await expectLater(
        service.createCheckout(accessToken: 'sat_expired'),
        throwsA(
          isA<FreemiusException>()
              .having((e) => e.code, 'code', 'sign_in_required')
              .having((e) => e.isSignInRequired, 'isSignInRequired', isTrue),
        ),
      );
    });

    test('non-JSON text failures keep a short body snippet as the code',
        () async {
      client.nextResponse = http.Response('upstream unavailable', 502);
      await expectLater(
        service.portal(accessToken: 'sat_abc'),
        throwsA(
          isA<FreemiusException>().having(
            (e) => e.code,
            'code',
            'upstream unavailable',
          ),
        ),
      );
    });

    test('an HTML error page never reaches the message', () async {
      // A not-yet-deployed proxy route answers with Next's 404 document; the
      // payment screen renders this string directly.
      client.nextResponse = http.Response(
        '<!DOCTYPE html><html><head><title>404: This page could not be found.'
        '</title></head><body>...</body></html>',
        404,
      );
      await expectLater(
        service.createCheckout(accessToken: 'sat_abc'),
        throwsA(
          isA<FreemiusException>()
              .having((e) => e.statusCode, 'statusCode', 404)
              .having((e) => e.code, 'code', 'http_404')
              .having(
                (e) => e.toString().contains('<html'),
                'toString',
                isFalse,
              ),
        ),
      );
    });

    test('portal returns the server-built billing portal URL', () async {
      client.nextResponse = http.Response(
        '{"portal_url":"https://billing.freemius.com/app/1234/account/"}',
        200,
      );
      final portal = await service.portal(accessToken: 'sat_abc');
      expect(portal.url.host, 'billing.freemius.com');
    });

    test('the default endpoint is the deployed web proxy, never Freemius',
        () async {
      // The app must never point at api.freemius.com / checkout directly —
      // that would require shipping the secret key inside the APK.
      final defaultService = FreemiusService(client: client);
      client.nextResponse = http.Response(
        '{"portal_url":"https://billing.freemius.com/app/1/account/"}',
        200,
      );
      await defaultService.portal(accessToken: 'sat_abc');
      expect(
        client.lastRequest!.url.toString(),
        'https://takwa-web.vercel.app/api/payments/freemius/portal',
      );
    });
  });

  group('FreemiusConfig', () {
    // The Freemius plan bills in USD, so the mirror must never render a euro
    // sign — a buyer seeing €10 and charged $10 is a trust problem.
    test(r'monthly price defaults to $10.00 and honors overrides', () {
      dotenv.loadFromString(envString: 'TAKWA_TEST_PLACEHOLDER=1');
      expect(FreemiusConfig.monthlyUsd, 10.0);
      expect(FreemiusConfig.monthlyDisplay, r'$10.00');
      expect(FreemiusConfig.currencyCode, 'usd');
      dotenv.loadFromString(envString: 'FREEMIUS_MONTHLY_USD=7');
      expect(FreemiusConfig.monthlyUsd, 7.0);
      expect(FreemiusConfig.monthlyDisplay, r'$7.00');
    });
  });
}

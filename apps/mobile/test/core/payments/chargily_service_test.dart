import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:takwa/core/payments/chargily_service.dart';
import 'package:takwa/core/payments/payment_config.dart';

/// Captures the outgoing request and replies with a canned response.
class _StubClient extends http.BaseClient {
  http.BaseRequest? lastRequest;
  String? lastBody;
  http.Response nextResponse = http.Response(
    '{"id":"chk_1","checkout_url":"http://pay.chargily.dz/test/checkouts/chk_1/pay","status":"pending"}',
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
  late ChargilyService service;

  setUp(() {
    client = _StubClient();
    service = ChargilyService(
      client: client,
      baseUrl: 'https://takwa-web.vercel.app/api/payments/checkout',
    );
  });

  group('ChargilyService', () {
    test('createCheckout posts to the web proxy without any Chargily auth',
        () async {
      await service.createCheckout(
        paymentMethod: 'edahabia',
        description: 'Support Takwa',
        locale: 'ar',
      );

      final request = client.lastRequest!;
      expect(request.method, 'POST');
      expect(request.url.path, '/api/payments/checkout');
      // The secret key lives server-side now; the client must never send one.
      expect(request.headers.containsKey('Authorization'), isFalse);

      final body = jsonDecode(client.lastBody!) as Map<String, dynamic>;
      expect(body['payment_method'], 'edahabia');
      expect(body['description'], 'Support Takwa');
      expect(body['locale'], 'ar');
      // Amount and redirect URLs are owned by the proxy, not the client.
      expect(body.containsKey('amount'), isFalse);
      expect(body.containsKey('success_url'), isFalse);
    });

    test(
      'createCheckout parses the hosted checkout url and forces https',
      () async {
        // Chargily returns http://…; Custom Tabs on Android refuse it, so the
        // model must upgrade to https:// even if the proxy forgot to.
        final checkout = await service.createCheckout();
        expect(checkout.id, 'chk_1');
        expect(checkout.checkoutUrl.scheme, 'https');
        expect(checkout.checkoutUrl.path, '/test/checkouts/chk_1/pay');
        expect(checkout.isPaid, isFalse);
      },
    );

    test('createCheckout moves the checkout page off pay.chargily.dz', () async {
      // pay.chargily.dz hangs at TCP connect from some networks; the identical
      // page is served on the API host, so that is what the app opens.
      final checkout = await service.createCheckout();
      expect(checkout.checkoutUrl.host, 'pay.chargily.net');
    });

    test('createCheckout keeps an already-usable checkout host', () async {
      client.nextResponse = http.Response(
        '{"id":"chk_2","checkout_url":"https://pay.chargily.net/test/checkouts/chk_2/pay","status":"pending"}',
        200,
      );

      final checkout = await service.createCheckout();
      expect(
        checkout.checkoutUrl.toString(),
        'https://pay.chargily.net/test/checkouts/chk_2/pay',
      );
    });

    test('fetchCheckout returns the verified status', () async {
      client.nextResponse = http.Response(
        '{"id":"chk_1","checkout_url":"","status":"paid"}',
        200,
      );

      final checkout = await service.fetchCheckout('chk_1');
      expect(client.lastRequest!.method, 'GET');
      expect(
        client.lastRequest!.url.path,
        '/api/payments/checkout/chk_1',
      );
      expect(checkout.status, 'paid');
      expect(checkout.isPaid, isTrue);
    });

    test('surfaces proxy errors as ChargilyException', () async {
      client.nextResponse = http.Response(
        '{"error":"payments_not_configured"}',
        503,
      );

      expect(
        service.createCheckout(),
        throwsA(
          isA<ChargilyException>().having(
            (e) => e.statusCode,
            'statusCode',
            503,
          ),
        ),
      );
    });

    test('the default endpoint is the deployed web proxy', () {
      // The app must never point at the Chargily REST API directly — that
      // would require shipping the secret key inside the APK.
      dotenv.loadFromString(envString: 'TAKWA_TEST_PLACEHOLDER=1');
      expect(
        ChargilyService(client: client)
            .createCheckout()
            .then((_) => client.lastRequest!.url.toString()),
        completion('https://takwa-web.vercel.app/api/payments/checkout'),
      );
    });
  });

  group('ChargilyConfig', () {
    test('webBaseUrl falls back to the deployed app and honors overrides', () {
      dotenv.loadFromString(envString: 'TAKWA_TEST_PLACEHOLDER=1');
      expect(ChargilyConfig.webBaseUrl, 'https://takwa-web.vercel.app');
      dotenv.loadFromString(envString: 'TAKWA_WEB_BASE_URL=https://staging.example');
      expect(ChargilyConfig.webBaseUrl, 'https://staging.example');
    });

    test('subscription amount defaults to 200 DZD / 20000 centime', () {
      dotenv.loadFromString(envString: 'TAKWA_TEST_PLACEHOLDER=1');
      expect(ChargilyConfig.subscriptionAmountDzd, 200);
      expect(ChargilyConfig.subscriptionAmountCentime, 20000);
      dotenv.loadFromString(envString: 'CHARGILY_SUBSCRIPTION_AMOUNT=350');
      expect(ChargilyConfig.subscriptionAmountDzd, 350);
    });
  });
}

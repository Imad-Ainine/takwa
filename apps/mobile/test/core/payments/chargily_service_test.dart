import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:takwa/core/payments/chargily_service.dart';

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
      baseUrl: 'https://pay.chargily.com/test/api/v2',
      secretKey: 'test_sk_secret123',
    );
  });

  group('ChargilyService', () {
    test('createCheckout authenticates with the secret key', () async {
      await service.createCheckout(
        amount: 10000,
        paymentMethod: 'edahabia',
        successUrl: 'takwa://payment-success',
      );

      final request = client.lastRequest!;
      expect(request.method, 'POST');
      expect(request.url.path, '/test/api/v2/checkouts');
      expect(
        request.headers['Authorization'],
        'Bearer test_sk_secret123',
      );

      final body = jsonDecode(client.lastBody!) as Map<String, dynamic>;
      expect(body['amount'], 10000);
      expect(body['currency'], 'dzd');
      expect(body['payment_method'], 'edahabia');
      expect(body['success_url'], 'takwa://payment-success');
    });

    test('createCheckout parses the hosted checkout url and forces https', () async {
      // Chargily returns http://…; Custom Tabs on Android refuse it, so the
      // model must upgrade to https://.
      final checkout = await service.createCheckout(amount: 10000);
      expect(checkout.id, 'chk_1');
      expect(checkout.checkoutUrl.scheme, 'https');
      expect(checkout.checkoutUrl.host, 'pay.chargily.dz');
      expect(checkout.checkoutUrl.path, '/test/checkouts/chk_1/pay');
      expect(checkout.isPaid, isFalse);
    });

    test('fetchCheckout returns the verified status', () async {
      client.nextResponse = http.Response(
        '{"id":"chk_1","checkout_url":"","status":"paid"}',
        200,
      );

      final checkout = await service.fetchCheckout('chk_1');
      expect(client.lastRequest!.method, 'GET');
      expect(client.lastRequest!.url.path, '/test/api/v2/checkouts/chk_1');
      expect(checkout.status, 'paid');
      expect(checkout.isPaid, isTrue);
    });

    test('surfaces API errors as ChargilyException', () async {
      client.nextResponse = http.Response('{"message":"bad key"}', 401);

      expect(
        service.createCheckout(amount: 10000),
        throwsA(
          isA<ChargilyException>().having(
            (e) => e.statusCode,
            'statusCode',
            401,
          ),
        ),
      );
    });
  });
}

import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:servnova_mobile/core/api/api_client.dart';
import 'package:servnova_mobile/core/api/api_exception.dart';

ApiClient client(MockClient mock) =>
    ApiClient(baseUrl: Uri.parse('https://api.test/api/v1'), httpClient: mock);

void main() {
  authTests();
  test('builds the URL under /api/v1 and sends Accept-Language fr', () async {
    late http.Request seen;
    final c = client(MockClient((r) async {
      seen = r;
      return http.Response('{"items":[]}', 200);
    }));
    final body = await c.getJson('/offers', query: {'q': 'plombier', 'limit': '20'});
    expect(body, {'items': []});
    expect(seen.url.toString(), 'https://api.test/api/v1/offers?q=plombier&limit=20');
    expect(seen.headers['Accept-Language'], 'fr');
  });

  test('refuses a non-HTTPS base URL unless explicitly allowed', () {
    expect(() => ApiClient(baseUrl: Uri.parse('http://api.test/api/v1')),
        throwsA(isA<ConfigException>()));
    expect(
        () => ApiClient(baseUrl: Uri.parse('http://localhost:5000/api/v1'), allowInsecure: true),
        returnsNormally);
  });

  test('maps problem+json to ApiException with code, field errors, retry-after', () async {
    final c = client(MockClient((r) async => http.Response(
          jsonEncode({
            'status': 429,
            'code': 'RATE_LIMITED',
            'traceId': 'abc',
            'errors': [
              {'field': 'q', 'code': 'TOO_LONG'}
            ],
          }),
          429,
          headers: {'retry-after': '12', 'content-type': 'application/problem+json'},
        )));
    try {
      await c.getJson('/offers');
      fail('should throw');
    } on ApiException catch (e) {
      expect(e.status, 429);
      expect(e.code, 'RATE_LIMITED');
      expect(e.retryAfterSeconds, 12);
      expect(e.traceId, 'abc');
      expect(e.fieldErrors.single.field, 'q');
    }
  });

  test('non-JSON error body becomes code UNKNOWN', () async {
    final c = client(MockClient((r) async => http.Response('<html>', 502)));
    await expectLater(c.getJson('/offers'),
        throwsA(isA<ApiException>().having((e) => e.code, 'code', 'UNKNOWN')));
  });

  test('transport failure and timeout become NetworkException', () async {
    final failing = client(MockClient((r) async => throw http.ClientException('down')));
    await expectLater(failing.getJson('/offers'), throwsA(isA<NetworkException>()));

    final slow = ApiClient(
      baseUrl: Uri.parse('https://api.test/api/v1'),
      timeout: const Duration(milliseconds: 10),
      httpClient: MockClient((r) async {
        await Future<void>.delayed(const Duration(milliseconds: 100));
        return http.Response('[]', 200);
      }),
    );
    await expectLater(slow.getJson('/offers'), throwsA(isA<NetworkException>()));
  });
}

void authTests() {
  test('attaches the bearer token and a JSON body on PATCH', () async {
    late http.Request seen;
    final c = ApiClient(
      baseUrl: Uri.parse('https://api.test/api/v1'),
      accessToken: () async => 'tok123',
      httpClient: MockClient((r) async {
        seen = r;
        return http.Response('{"ok":true}', 200);
      }),
    );
    final res = await c.patchJson('/providers/me', body: {'description': null, 'businessName': 'X'});
    expect(res, {'ok': true});
    expect(seen.method, 'PATCH');
    expect(seen.headers['Authorization'], 'Bearer tok123');
    expect(seen.headers['Content-Type'], startsWith('application/json'));
    expect(jsonDecode(seen.body), {'description': null, 'businessName': 'X'});
  });

  test('no Authorization header without a token; 204 returns null', () async {
    late http.Request seen;
    final c = ApiClient(
      baseUrl: Uri.parse('https://api.test/api/v1'),
      accessToken: () => null,
      httpClient: MockClient((r) async {
        seen = r;
        return http.Response('', 204);
      }),
    );
    expect(await c.postJson('/notifications/read-all'), isNull);
    expect(seen.method, 'POST');
    expect(seen.headers.containsKey('Authorization'), isFalse);
  });
}

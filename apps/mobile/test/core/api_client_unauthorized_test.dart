import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:servnova_mobile/core/api/api_client.dart';
import 'package:servnova_mobile/core/api/api_exception.dart';

http.Response problem(int status, String code) => http.Response(
      jsonEncode({'status': status, 'code': code}),
      status,
      headers: {'content-type': 'application/problem+json'},
    );

void main() {
  late String token;
  late int renewCalls;
  late bool renewResult;
  late List<http.Request> seen;

  ApiClient build(Future<http.Response> Function(http.Request, int attempt) answer,
      {String? initialToken = 'old'}) {
    token = initialToken ?? '';
    renewCalls = 0;
    renewResult = true;
    seen = [];
    return ApiClient(
      baseUrl: Uri.parse('https://api.test/api/v1'),
      httpClient: MockClient((r) async {
        seen.add(r);
        return answer(r, seen.length);
      }),
      accessToken: () => token.isEmpty ? null : token,
      onUnauthorized: () async {
        renewCalls++;
        if (renewResult) token = 'new';
        return renewResult;
      },
    );
  }

  test('a 401 on a protected route renews once and retries with the new token', () async {
    final c = build((r, n) async => n == 1 ? problem(401, 'TOKEN_EXPIRED') : http.Response('{"ok":true}', 200));
    final body = await c.postJson('/offers', body: {'a': 1});
    expect(body, {'ok': true});
    expect(renewCalls, 1);
    expect(seen, hasLength(2));
    expect(seen[0].headers['Authorization'], 'Bearer old');
    expect(seen[1].headers['Authorization'], 'Bearer new');
    expect(seen[1].body, seen[0].body, reason: 'the body is sent again unchanged');
  });

  test('when the renewal fails the original 401 is thrown and nothing is retried', () async {
    final c = build((r, n) async => problem(401, 'TOKEN_EXPIRED'));
    renewResult = false;
    await expectLater(
      c.getJson('/users/me'),
      throwsA(isA<ApiException>().having((e) => e.status, 'status', 401)),
    );
    expect(renewCalls, 1);
    expect(seen, hasLength(1));
  });

  test('a second 401 after the retry is thrown without a second renewal', () async {
    final c = build((r, n) async => problem(401, 'UNAUTHENTICATED'));
    await expectLater(c.getJson('/users/me'), throwsA(isA<ApiException>()));
    expect(renewCalls, 1);
    expect(seen, hasLength(2));
  });

  test('routes under /auth/ never trigger a renewal (wrong password is a 401 too)', () async {
    final c = build((r, n) async => problem(401, 'INVALID_CREDENTIALS'));
    await expectLater(
      c.postJson('/auth/login', body: {'phone': 'p', 'password': 'x'}),
      throwsA(isA<ApiException>().having((e) => e.code, 'code', 'INVALID_CREDENTIALS')),
    );
    expect(renewCalls, 0);
    expect(seen, hasLength(1));
  });

  test('without a token there is nothing to renew', () async {
    final c = build((r, n) async => problem(401, 'UNAUTHENTICATED'), initialToken: null);
    await expectLater(c.getJson('/offers'), throwsA(isA<ApiException>()));
    expect(renewCalls, 0);
  });

  test('other errors do not trigger a renewal', () async {
    final c = build((r, n) async => problem(403, 'FORBIDDEN'));
    await expectLater(c.getJson('/offers'), throwsA(isA<ApiException>()));
    expect(renewCalls, 0);
  });
}

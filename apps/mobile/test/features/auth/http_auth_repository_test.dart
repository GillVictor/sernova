import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:servnova_mobile/core/api/api_client.dart';
import 'package:servnova_mobile/core/api/api_exception.dart';
import 'package:servnova_mobile/features/auth/data/auth_repository.dart';

HttpAuthRepository repo(MockClient mock, {String? token}) => HttpAuthRepository(ApiClient(
      baseUrl: Uri.parse('https://api.test/api/v1'),
      httpClient: mock,
      accessToken: token == null ? null : () => token,
    ));

http.Response tokens(String a, String r) =>
    http.Response(jsonEncode({'accessToken': a, 'refreshToken': r}), 200);

http.Response problem(int status, String code) => http.Response(
      jsonEncode({'status': status, 'code': code}),
      status,
      headers: {'content-type': 'application/problem+json'},
    );

void main() {
  group('EP-004 login', () {
    test('POSTs phone and password to /auth/login and parses both tokens', () async {
      late http.Request seen;
      final r = repo(MockClient((req) async {
        seen = req;
        return tokens('acc', 'ref');
      }));
      final t = await r.login(phone: '+242060000000', password: 'secret');
      expect(seen.method, 'POST');
      expect(seen.url.toString(), 'https://api.test/api/v1/auth/login');
      expect(jsonDecode(seen.body), {'phone': '+242060000000', 'password': 'secret'});
      expect(t.accessToken, 'acc');
      expect(t.refreshToken, 'ref');
    });

    for (final c in const [
      (401, 'INVALID_CREDENTIALS'),
      (423, 'ACCOUNT_SUSPENDED'),
      (403, 'PHONE_NOT_VERIFIED'),
      (429, 'RATE_LIMITED'),
    ]) {
      test('surfaces ${c.$2} (${c.$1}) with its stable code', () async {
        final r = repo(MockClient((_) async => problem(c.$1, c.$2)));
        await expectLater(
          r.login(phone: 'p', password: 'x'),
          throwsA(isA<ApiException>()
              .having((e) => e.code, 'code', c.$2)
              .having((e) => e.status, 'status', c.$1)),
        );
      });
    }

    test('a body without tokens is a contract problem (UNKNOWN), not a crash', () async {
      final r = repo(MockClient((_) async => http.Response('{"accessToken":"a"}', 200)));
      await expectLater(
        r.login(phone: 'p', password: 'x'),
        throwsA(isA<ApiException>().having((e) => e.code, 'code', 'UNKNOWN')),
      );
    });

    test('empty tokens are rejected', () async {
      final r = repo(MockClient((_) async => tokens('', 'ref')));
      await expectLater(
        r.login(phone: 'p', password: 'x'),
        throwsA(isA<ApiException>().having((e) => e.code, 'code', 'UNKNOWN')),
      );
    });
  });

  group('EP-005 refresh', () {
    test('POSTs the refresh token in the body and returns the rotated pair', () async {
      late http.Request seen;
      final r = repo(MockClient((req) async {
        seen = req;
        return tokens('acc-2', 'ref-2');
      }));
      final t = await r.refresh('ref-1');
      expect(seen.url.path, '/api/v1/auth/refresh');
      expect(jsonDecode(seen.body), {'refreshToken': 'ref-1'});
      expect(seen.headers.containsKey('Authorization'), isFalse);
      expect(t.refreshToken, 'ref-2');
    });

    test('TOKEN_REVOKED (401) is surfaced', () async {
      final r = repo(MockClient((_) async => problem(401, 'TOKEN_REVOKED')));
      await expectLater(
        r.refresh('ref-1'),
        throwsA(isA<ApiException>().having((e) => e.code, 'code', 'TOKEN_REVOKED')),
      );
    });
  });

  group('EP-006 logout', () {
    test('POSTs the refresh token with the Bearer token and accepts 204', () async {
      late http.Request seen;
      final r = repo(
        MockClient((req) async {
          seen = req;
          return http.Response('', 204);
        }),
        token: 'acc',
      );
      await r.logout('ref-1');
      expect(seen.url.path, '/api/v1/auth/logout');
      expect(seen.headers['Authorization'], 'Bearer acc');
      expect(jsonDecode(seen.body), {'refreshToken': 'ref-1'});
    });

    test('a server error is surfaced to the caller', () async {
      final r = repo(MockClient((_) async => problem(401, 'UNAUTHENTICATED')), token: 'acc');
      await expectLater(r.logout('ref-1'), throwsA(isA<ApiException>()));
    });
  });
}

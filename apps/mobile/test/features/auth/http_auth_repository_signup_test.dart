import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:servnova_mobile/core/api/api_client.dart';
import 'package:servnova_mobile/core/api/api_exception.dart';
import 'package:servnova_mobile/features/auth/data/auth_repository.dart';

HttpAuthRepository repo(MockClient mock) => HttpAuthRepository(ApiClient(
      baseUrl: Uri.parse('https://api.test/api/v1'),
      httpClient: mock,
    ));

http.Response problem(int status, String code, {Object? errors, Map<String, String> extra = const {}}) =>
    http.Response(
      jsonEncode({'status': status, 'code': code, if (errors != null) 'errors': errors}),
      status,
      headers: {'content-type': 'application/problem+json', ...extra},
    );

void main() {
  group('EP-001 register', () {
    test('POSTs the contract fields to /auth/register and accepts 201', () async {
      late http.Request seen;
      final r = repo(MockClient((req) async {
        seen = req;
        return http.Response('{"userId":"u1"}', 201);
      }));
      await r.register(
        phone: '+242061234567',
        password: 'pw',
        displayName: 'Test User',
        language: 'fr',
        countryCode: 'CG',
        email: 'a@b.c',
      );
      expect(seen.method, 'POST');
      expect(seen.url.toString(), 'https://api.test/api/v1/auth/register');
      expect(jsonDecode(seen.body), {
        'phone': '+242061234567',
        'password': 'pw',
        'displayName': 'Test User',
        'language': 'fr',
        'countryCode': 'CG',
        'email': 'a@b.c',
      });
      expect(seen.headers.containsKey('Authorization'), isFalse);
    });

    test('the optional e-mail is left out when absent or blank', () async {
      final bodies = <Map<String, dynamic>>[];
      final r = repo(MockClient((req) async {
        bodies.add(jsonDecode(req.body) as Map<String, dynamic>);
        return http.Response('{"userId":"u1"}', 201);
      }));
      await r.register(phone: 'p', password: 'x', displayName: 'n', language: 'fr', countryCode: 'CG');
      await r.register(phone: 'p', password: 'x', displayName: 'n', language: 'fr', countryCode: 'CG', email: '');
      expect(bodies[0].containsKey('email'), isFalse);
      expect(bodies[1].containsKey('email'), isFalse);
    });

    test('PHONE_ALREADY_USED (409) is surfaced', () async {
      final r = repo(MockClient((_) async => problem(409, 'PHONE_ALREADY_USED')));
      await expectLater(
        r.register(phone: 'p', password: 'x', displayName: 'n', language: 'fr', countryCode: 'CG'),
        throwsA(isA<ApiException>().having((e) => e.code, 'code', 'PHONE_ALREADY_USED')),
      );
    });

    test('VALIDATION_FAILED (422) keeps the per-field errors', () async {
      final r = repo(MockClient((_) async => problem(422, 'VALIDATION_FAILED', errors: [
            {'field': 'password', 'code': 'TOO_SHORT'}
          ])));
      await expectLater(
        r.register(phone: 'p', password: 'x', displayName: 'n', language: 'fr', countryCode: 'CG'),
        throwsA(isA<ApiException>()
            .having((e) => e.code, 'code', 'VALIDATION_FAILED')
            .having((e) => e.fieldErrors.single.field, 'field', 'password')),
      );
    });

    test('RATE_LIMITED (429) keeps the Retry-After delay', () async {
      final r = repo(MockClient((_) async => problem(429, 'RATE_LIMITED', extra: {'retry-after': '30'})));
      await expectLater(
        r.register(phone: 'p', password: 'x', displayName: 'n', language: 'fr', countryCode: 'CG'),
        throwsA(isA<ApiException>().having((e) => e.retryAfterSeconds, 'retryAfter', 30)),
      );
    });
  });

  group('EP-002 verify-phone', () {
    test('POSTs phone and code, returns both tokens', () async {
      late http.Request seen;
      final r = repo(MockClient((req) async {
        seen = req;
        return http.Response(jsonEncode({'accessToken': 'acc', 'refreshToken': 'ref'}), 200);
      }));
      final t = await r.verifyPhone(phone: '+242061234567', code: '123456');
      expect(seen.url.path, '/api/v1/auth/verify-phone');
      expect(jsonDecode(seen.body), {'phone': '+242061234567', 'code': '123456'});
      expect(t.accessToken, 'acc');
      expect(t.refreshToken, 'ref');
    });

    for (final code in const ['CODE_INVALID', 'CODE_EXPIRED']) {
      test('$code (422) is surfaced', () async {
        final r = repo(MockClient((_) async => problem(422, code)));
        await expectLater(
          r.verifyPhone(phone: 'p', code: '0'),
          throwsA(isA<ApiException>().having((e) => e.code, 'code', code)),
        );
      });
    }

    test('a body without tokens is UNKNOWN, not a crash', () async {
      final r = repo(MockClient((_) async => http.Response('{}', 200)));
      await expectLater(
        r.verifyPhone(phone: 'p', code: '0'),
        throwsA(isA<ApiException>().having((e) => e.code, 'code', 'UNKNOWN')),
      );
    });
  });

  group('EP-003 resend-code', () {
    test('POSTs the phone and accepts 204', () async {
      late http.Request seen;
      final r = repo(MockClient((req) async {
        seen = req;
        return http.Response('', 204);
      }));
      await r.resendCode('+242061234567');
      expect(seen.url.path, '/api/v1/auth/resend-code');
      expect(jsonDecode(seen.body), {'phone': '+242061234567'});
    });

    test('RATE_LIMITED (429) is surfaced with its delay', () async {
      final r = repo(MockClient((_) async => problem(429, 'RATE_LIMITED', extra: {'retry-after': '60'})));
      await expectLater(
        r.resendCode('p'),
        throwsA(isA<ApiException>().having((e) => e.retryAfterSeconds, 'retryAfter', 60)),
      );
    });
  });
}

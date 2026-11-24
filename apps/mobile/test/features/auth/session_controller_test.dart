import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:servnova_mobile/core/api/api_exception.dart';
import 'package:servnova_mobile/features/auth/data/token_store.dart';
import 'package:servnova_mobile/features/auth/domain/auth_tokens.dart';
import 'package:servnova_mobile/features/auth/presentation/session_controller.dart';

import '../../support/stub_auth.dart';

void main() {
  late StubAuthRepository auth;
  late InMemoryTokenStore store;
  late SessionController session;

  setUp(() {
    auth = StubAuthRepository();
    store = InMemoryTokenStore();
    session = SessionController(auth: auth, store: store);
  });

  tearDown(() => session.dispose());

  group('login (EP-004)', () {
    test('starts in "restoring" until restore() has answered', () {
      expect(session.status, SessionStatus.restoring);
      expect(session.accessToken, isNull);
    });

    test('success: signed in, access token in memory, refresh token stored, phone trimmed', () async {
      final ok = await session.login(phone: '  +242060000000 ', password: 'secret');
      expect(ok, isTrue);
      expect(session.status, SessionStatus.signedIn);
      expect(session.accessToken, 'access-1');
      expect(await store.readRefreshToken(), 'refresh-1');
      expect(auth.loginCalls.single.phone, '+242060000000');
      expect(auth.loginCalls.single.password, 'secret');
      expect(session.failure, isNull);
    });

    test('INVALID_CREDENTIALS: stays signed out, nothing stored, failure exposed', () async {
      auth.loginError = const ApiException(status: 401, code: 'INVALID_CREDENTIALS');
      final ok = await session.login(phone: 'p', password: 'bad');
      expect(ok, isFalse);
      expect(session.status, SessionStatus.signedOut);
      expect(session.failure?.code, 'INVALID_CREDENTIALS');
      expect(session.accessToken, isNull);
      expect(await store.readRefreshToken(), isNull);
      expect(session.busy, isFalse);
    });

    test('network failure is reported as NETWORK', () async {
      auth.loginError = const NetworkException();
      expect(await session.login(phone: 'p', password: 'x'), isFalse);
      expect(session.failure?.code, 'NETWORK');
    });

    test('a new attempt clears the previous failure', () async {
      auth.loginError = const ApiException(status: 401, code: 'INVALID_CREDENTIALS');
      await session.login(phone: 'p', password: 'bad');
      auth.loginError = null;
      await session.login(phone: 'p', password: 'good');
      expect(session.failure, isNull);
      expect(session.status, SessionStatus.signedIn);
    });

    test('still signed in for this run when the token cannot be persisted', () async {
      final s = SessionController(auth: auth, store: FailingWriteTokenStore());
      addTearDown(s.dispose);
      expect(await s.login(phone: 'p', password: 'x'), isTrue);
      expect(s.status, SessionStatus.signedIn);
      expect(s.accessToken, 'access-1');
    });

    test('a second login while one is running is ignored', () async {
      final gate = Completer<void>();
      final slow = _SlowLogin(gate.future);
      final s = SessionController(auth: slow, store: store);
      addTearDown(s.dispose);
      final first = s.login(phone: 'p', password: 'x');
      final second = await s.login(phone: 'p', password: 'x');
      expect(second, isFalse);
      gate.complete();
      expect(await first, isTrue);
      expect(slow.loginCalls, hasLength(1));
    });
  });

  group('restore (EP-005 at start-up)', () {
    test('no stored token: signed out without calling the server', () async {
      await session.restore();
      expect(session.status, SessionStatus.signedOut);
      expect(auth.refreshCalls, isEmpty);
    });

    test('stored token: rotates it and signs in', () async {
      await store.writeRefreshToken('stored');
      await session.restore();
      expect(auth.refreshCalls, ['stored']);
      expect(session.status, SessionStatus.signedIn);
      expect(session.accessToken, 'access-2');
      expect(await store.readRefreshToken(), 'refresh-2', reason: 'rotation: the old token is replaced');
    });

    for (final code in const ['TOKEN_REVOKED', 'TOKEN_EXPIRED']) {
      test('$code: the stored token is dropped and the user signs in again', () async {
        await store.writeRefreshToken('stored');
        auth.refreshHandler = (_) async => throw ApiException(status: 401, code: code);
        await session.restore();
        expect(session.status, SessionStatus.signedOut);
        expect(await store.readRefreshToken(), isNull);
        expect(session.accessToken, isNull);
      });
    }

    test('network failure: signed out for now but the stored token is kept', () async {
      await store.writeRefreshToken('stored');
      auth.refreshHandler = (_) async => throw const NetworkException();
      await session.restore();
      expect(session.status, SessionStatus.signedOut);
      expect(session.failure?.code, 'NETWORK');
      expect(await store.readRefreshToken(), 'stored');
    });
  });

  group('refresh (rotation)', () {
    setUp(() async => session.login(phone: 'p', password: 'x'));

    test('replaces both tokens', () async {
      expect(await session.refresh(), isTrue);
      expect(auth.refreshCalls, ['refresh-1']);
      expect(session.accessToken, 'access-2');
      expect(await store.readRefreshToken(), 'refresh-2');
    });

    test('concurrent callers share one call: a token used twice would revoke the family', () async {
      final gate = Completer<AuthTokens>();
      auth.refreshHandler = (_) => gate.future;
      final a = session.refresh();
      final b = session.refresh();
      gate.complete(const AuthTokens(accessToken: 'access-2', refreshToken: 'refresh-2'));
      expect(await a, isTrue);
      expect(await b, isTrue);
      expect(auth.refreshCalls, hasLength(1));
    });

    test('a later refresh uses the rotated token, not the original one', () async {
      await session.refresh();
      auth.refreshHandler = (_) async =>
          const AuthTokens(accessToken: 'access-3', refreshToken: 'refresh-3');
      await session.refresh();
      expect(auth.refreshCalls, ['refresh-1', 'refresh-2']);
    });

    test('TOKEN_REVOKED while signed in: the session ends', () async {
      auth.refreshHandler = (_) async => throw const ApiException(status: 401, code: 'TOKEN_REVOKED');
      expect(await session.refresh(), isFalse);
      expect(session.status, SessionStatus.signedOut);
      expect(session.accessToken, isNull);
      expect(await store.readRefreshToken(), isNull);
    });

    test('a temporary failure keeps the session and the token', () async {
      auth.refreshHandler = (_) async => throw const ApiException(status: 503, code: 'UNKNOWN');
      expect(await session.refresh(), isFalse);
      expect(session.status, SessionStatus.signedIn);
      expect(await store.readRefreshToken(), 'refresh-1');
    });
  });

  group('logout (EP-006)', () {
    setUp(() async => session.login(phone: 'p', password: 'x'));

    test('revokes the stored refresh token, then forgets everything', () async {
      await session.logout();
      expect(auth.logoutCalls, ['refresh-1']);
      expect(session.status, SessionStatus.signedOut);
      expect(session.accessToken, isNull);
      expect(await store.readRefreshToken(), isNull);
    });

    test('the access token is still available while the server call is made', () async {
      String? seen;
      auth.onLogout = (_) => seen = session.accessToken;
      await session.logout();
      expect(seen, 'access-1', reason: 'EP-006 is authenticated');
    });

    test('signs out locally even when the server cannot be reached', () async {
      auth.logoutError = const NetworkException();
      await session.logout();
      expect(session.status, SessionStatus.signedOut);
      expect(await store.readRefreshToken(), isNull);
    });
  });
}

class _SlowLogin extends StubAuthRepository {
  _SlowLogin(this._gate);
  final Future<void> _gate;

  @override
  Future<AuthTokens> login({required String phone, required String password}) async {
    loginCalls.add((phone: phone, password: password));
    await _gate;
    return loginTokens;
  }
}

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

  test('login removes spaces and dashes typed inside the number', () async {
    await session.login(phone: ' +242 06-123 45 67 ', password: 'secret');
    expect(auth.loginCalls.single.phone, '+242061234567');
  });

  group('signInWith (tokens obtained by EP-002 after the phone check)', () {
    const tokens = AuthTokens(accessToken: 'acc', refreshToken: 'ref');

    test('signed in, access token in memory, refresh token stored', () async {
      await session.signInWith(tokens);
      expect(session.status, SessionStatus.signedIn);
      expect(session.accessToken, 'acc');
      expect(await store.readRefreshToken(), 'ref');
    });

    test('a previous login failure is cleared', () async {
      auth.loginError = const ApiException(status: 403, code: 'PHONE_NOT_VERIFIED');
      await session.login(phone: 'p', password: 'x');
      expect(session.failure?.code, 'PHONE_NOT_VERIFIED');
      await session.signInWith(tokens);
      expect(session.failure, isNull);
    });

    test('still signed in for this run when the token cannot be persisted', () async {
      final s = SessionController(auth: auth, store: FailingWriteTokenStore());
      addTearDown(s.dispose);
      await s.signInWith(tokens);
      expect(s.status, SessionStatus.signedIn);
      expect(s.accessToken, 'acc');
    });
  });
}

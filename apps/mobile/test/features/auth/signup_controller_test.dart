import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:servnova_mobile/core/api/api_exception.dart';
import 'package:servnova_mobile/features/auth/data/token_store.dart';
import 'package:servnova_mobile/features/auth/presentation/session_controller.dart';
import 'package:servnova_mobile/features/auth/presentation/signup_controller.dart';

import '../../support/stub_auth.dart';

void main() {
  late StubAuthRepository auth;
  late InMemoryTokenStore store;
  late SessionController session;
  late SignupController signup;

  setUp(() async {
    auth = StubAuthRepository();
    store = InMemoryTokenStore();
    session = SessionController(auth: auth, store: store);
    await session.restore(); // nothing stored: signed out
    signup = SignupController(auth: auth, session: session, countryCode: 'CG');
  });

  tearDown(() {
    signup.dispose();
    session.dispose();
  });

  group('register (EP-001)', () {
    test('sends the trimmed, normalized fields with language fr and the country', () async {
      final ok = await signup.register(
        phone: ' +242 06 123 45 67 ',
        password: 'pw',
        displayName: ' Test User ',
        email: '  ',
      );
      expect(ok, isTrue);
      expect(auth.registerCalls.single, (
        phone: '+242061234567',
        password: 'pw',
        displayName: 'Test User',
        language: 'fr',
        countryCode: 'CG',
        email: null,
      ));
      expect(signup.failure, isNull);
      expect(signup.busy, isFalse);
    });

    test('a filled e-mail is sent trimmed', () async {
      await signup.register(phone: '+242061234567', password: 'pw', displayName: 'n', email: ' a@b.c ');
      expect(auth.registerCalls.single.email, 'a@b.c');
    });

    test('registering does not sign the user in (the phone is not verified yet)', () async {
      await signup.register(phone: '+242061234567', password: 'pw', displayName: 'n');
      expect(session.status, SessionStatus.signedOut);
      expect(session.accessToken, isNull);
    });

    test('PHONE_ALREADY_USED is exposed as the failure', () async {
      auth.registerError = const ApiException(status: 409, code: 'PHONE_ALREADY_USED');
      expect(await signup.register(phone: '+242061234567', password: 'pw', displayName: 'n'), isFalse);
      expect(signup.failure?.code, 'PHONE_ALREADY_USED');
    });

    test('VALIDATION_FAILED keeps the fields the server rejected', () async {
      auth.registerError = const ApiException(
        status: 422,
        code: 'VALIDATION_FAILED',
        fieldErrors: [FieldError(field: 'password', code: 'TOO_SHORT')],
      );
      await signup.register(phone: '+242061234567', password: 'pw', displayName: 'n');
      expect(signup.failure?.code, 'VALIDATION_FAILED');
      expect(signup.failure?.fieldErrors.single.field, 'password');
    });

    test('offline is reported as NETWORK', () async {
      auth.registerError = const NetworkException();
      await signup.register(phone: '+242061234567', password: 'pw', displayName: 'n');
      expect(signup.failure?.code, 'NETWORK');
    });

    test('a second call while one is running is ignored', () async {
      final gate = Completer<void>();
      auth.registerGate = gate.future;
      final first = signup.register(phone: '+242061234567', password: 'pw', displayName: 'n');
      expect(signup.busy, isTrue);
      expect(await signup.register(phone: '+242061234567', password: 'pw', displayName: 'n'), isFalse);
      gate.complete();
      expect(await first, isTrue);
      expect(auth.registerCalls, hasLength(1));
    });
  });

  group('verifyPhone (EP-002)', () {
    test('success signs in: tokens adopted, refresh token stored', () async {
      final ok = await signup.verifyPhone(phone: '+242 06 123 45 67', code: ' 123456 ');
      expect(ok, isTrue);
      expect(auth.verifyCalls.single, (phone: '+242061234567', code: '123456'));
      expect(session.status, SessionStatus.signedIn);
      expect(session.accessToken, 'access-v');
      expect(await store.readRefreshToken(), 'refresh-v');
    });

    for (final code in const ['CODE_INVALID', 'CODE_EXPIRED']) {
      test('$code: stays signed out, nothing stored', () async {
        auth.verifyError = ApiException(status: 422, code: code);
        expect(await signup.verifyPhone(phone: '+242061234567', code: '000000'), isFalse);
        expect(signup.failure?.code, code);
        expect(session.status, SessionStatus.signedOut);
        expect(await store.readRefreshToken(), isNull);
      });
    }
  });

  group('resendCode (EP-003)', () {
    test('success: the new code is announced', () async {
      expect(await signup.resendCode('+242 06 123 45 67'), isTrue);
      expect(auth.resendCalls, ['+242061234567']);
      expect(signup.codeResent, isTrue);
      expect(signup.failure, isNull);
    });

    test('RATE_LIMITED: failure with the delay, no announcement', () async {
      auth.resendError = const ApiException(status: 429, code: 'RATE_LIMITED', retryAfterSeconds: 30);
      expect(await signup.resendCode('+242061234567'), isFalse);
      expect(signup.failure?.code, 'RATE_LIMITED');
      expect(signup.failure?.retryAfterSeconds, 30);
      expect(signup.codeResent, isFalse);
    });

    test('the announcement is cleared by the next action', () async {
      await signup.resendCode('+242061234567');
      auth.verifyError = const ApiException(status: 422, code: 'CODE_INVALID');
      await signup.verifyPhone(phone: '+242061234567', code: '1');
      expect(signup.codeResent, isFalse);
    });
  });

  test('clearFailure forgets the failure and the announcement', () async {
    auth.registerError = const ApiException(status: 409, code: 'PHONE_ALREADY_USED');
    await signup.register(phone: '+242061234567', password: 'pw', displayName: 'n');
    signup.clearFailure();
    expect(signup.failure, isNull);
    expect(signup.codeResent, isFalse);
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:servnova_mobile/core/api/api_exception.dart';
import 'package:servnova_mobile/core/l10n/strings.dart';
import 'package:servnova_mobile/core/theme/app_theme.dart';
import 'package:servnova_mobile/features/auth/data/token_store.dart';
import 'package:servnova_mobile/features/auth/presentation/session_controller.dart';
import 'package:servnova_mobile/features/auth/presentation/signup_controller.dart';
import 'package:servnova_mobile/features/auth/presentation/signup_page.dart';
import 'package:servnova_mobile/features/auth/presentation/verify_phone_page.dart';

import '../../support/stub_auth.dart';

const phoneKey = Key('signup-phone');
const nameKey = Key('signup-name');
const emailKey = Key('signup-email');
const passwordKey = Key('signup-password');
const confirmKey = Key('signup-confirm');
const submitKey = Key('signup-submit');

Future<StubAuthRepository> pumpSignup(WidgetTester tester, StubAuthRepository auth) async {
  tester.view.physicalSize = const Size(800, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final session = SessionController(auth: auth, store: InMemoryTokenStore());
  final signup = SignupController(auth: auth, session: session, countryCode: 'CG');
  addTearDown(() {
    signup.dispose();
    session.dispose();
  });
  await tester.pumpWidget(MaterialApp(theme: AppTheme.light(), home: SignupPage(controller: signup)));
  await tester.pumpAndSettle();
  return auth;
}

Future<void> fillAndSubmit(
  WidgetTester tester, {
  String phone = '+242 06 123 45 67',
  String name = 'Test User',
  String email = '',
  String password = 'pw-1',
  String? confirm,
}) async {
  await tester.enterText(find.byKey(phoneKey), phone);
  await tester.enterText(find.byKey(nameKey), name);
  await tester.enterText(find.byKey(emailKey), email);
  await tester.enterText(find.byKey(passwordKey), password);
  await tester.enterText(find.byKey(confirmKey), confirm ?? password);
  await tester.tap(find.byKey(submitKey));
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await Strings.load();
  });

  testWidgets('every field has its help tooltip', (tester) async {
    await pumpSignup(tester, StubAuthRepository());
    for (final k in ['phone', 'displayName', 'email', 'password', 'confirmPassword']) {
      expect(find.byTooltip(Strings.t('auth.signup.fields.$k.help')), findsOneWidget, reason: k);
    }
  });

  testWidgets('the passwords are hidden until the user asks to show them', (tester) async {
    await pumpSignup(tester, StubAuthRepository());
    bool obscured(Key k) => tester.widget<TextField>(find.byKey(k)).obscureText;
    expect(obscured(passwordKey), isTrue);
    expect(obscured(confirmKey), isTrue);
    await tester.tap(find.byTooltip(Strings.t('auth.signup.fields.password.show')));
    await tester.pump();
    expect(obscured(passwordKey), isFalse);
    expect(obscured(confirmKey), isFalse);
  });

  testWidgets('empty form: local messages, no request sent', (tester) async {
    final auth = await pumpSignup(tester, StubAuthRepository());
    await tester.tap(find.byKey(submitKey));
    await tester.pumpAndSettle();
    expect(find.text(Strings.t('auth.signup.validation.phoneRequired')), findsOneWidget);
    expect(find.text(Strings.t('auth.signup.validation.displayNameRequired')), findsOneWidget);
    expect(find.text(Strings.t('auth.signup.validation.passwordRequired')), findsOneWidget);
    expect(auth.registerCalls, isEmpty);
  });

  testWidgets('a number without the country code is refused locally', (tester) async {
    final auth = await pumpSignup(tester, StubAuthRepository());
    await fillAndSubmit(tester, phone: '06 123 45 67');
    expect(find.text(Strings.t('auth.signup.validation.phoneFormat')), findsOneWidget);
    expect(auth.registerCalls, isEmpty);
  });

  testWidgets('different passwords are refused locally', (tester) async {
    final auth = await pumpSignup(tester, StubAuthRepository());
    await fillAndSubmit(tester, password: 'pw-1', confirm: 'pw-2');
    expect(find.text(Strings.t('auth.signup.validation.passwordMismatch')), findsOneWidget);
    expect(auth.registerCalls, isEmpty);
  });

  testWidgets('an e-mail without @ is refused locally, a blank one is fine', (tester) async {
    final auth = await pumpSignup(tester, StubAuthRepository());
    await fillAndSubmit(tester, email: 'not-an-email');
    expect(find.text(Strings.t('auth.signup.validation.emailFormat')), findsOneWidget);
    expect(auth.registerCalls, isEmpty);
  });

  testWidgets('nominal: sends the fields, then asks for the SMS code', (tester) async {
    final auth = await pumpSignup(tester, StubAuthRepository());
    await fillAndSubmit(tester);
    expect(auth.registerCalls.single, (
      phone: '+242061234567',
      password: 'pw-1',
      displayName: 'Test User',
      language: 'fr',
      countryCode: 'CG',
      email: null,
    ));
    expect(find.byType(VerifyPhonePage), findsOneWidget);
    expect(find.text(Strings.t('auth.verify.intro', params: {'phone': '+242061234567'})), findsOneWidget);
  });

  testWidgets('PHONE_ALREADY_USED: message shown, stays on the form', (tester) async {
    final auth = StubAuthRepository()
      ..registerError = const ApiException(status: 409, code: 'PHONE_ALREADY_USED');
    await pumpSignup(tester, auth);
    await fillAndSubmit(tester);
    expect(find.text(Strings.error('PHONE_ALREADY_USED')), findsOneWidget);
    expect(find.byType(VerifyPhonePage), findsNothing);
  });

  testWidgets('VALIDATION_FAILED: the rejected field is marked', (tester) async {
    final auth = StubAuthRepository()
      ..registerError = const ApiException(
        status: 422,
        code: 'VALIDATION_FAILED',
        fieldErrors: [FieldError(field: 'password', code: 'TOO_SHORT')],
      );
    await pumpSignup(tester, auth);
    await fillAndSubmit(tester);
    expect(find.text(Strings.error('VALIDATION_FAILED')), findsOneWidget);
    expect(find.text(Strings.t('auth.signup.validation.fieldRejected')), findsOneWidget);
    expect(find.byType(VerifyPhonePage), findsNothing);
  });

  testWidgets('rate limit: shows the delay from Retry-After', (tester) async {
    final auth = StubAuthRepository()
      ..registerError = const ApiException(status: 429, code: 'RATE_LIMITED', retryAfterSeconds: 30);
    await pumpSignup(tester, auth);
    await fillAndSubmit(tester);
    expect(find.text(Strings.error('RATE_LIMITED', retryAfterSeconds: 30)), findsOneWidget);
  });

  testWidgets('offline: shows the network message', (tester) async {
    final auth = StubAuthRepository()..registerError = const NetworkException();
    await pumpSignup(tester, auth);
    await fillAndSubmit(tester);
    expect(find.text(Strings.error('NETWORK')), findsOneWidget);
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:servnova_mobile/core/api/api_exception.dart';
import 'package:servnova_mobile/core/l10n/strings.dart';
import 'package:servnova_mobile/core/theme/app_theme.dart';
import 'package:servnova_mobile/features/auth/data/token_store.dart';
import 'package:servnova_mobile/features/auth/presentation/session_controller.dart';
import 'package:servnova_mobile/features/auth/presentation/signup_controller.dart';
import 'package:servnova_mobile/features/auth/presentation/verify_phone_page.dart';

import '../../support/stub_auth.dart';

const codeKey = Key('verify-code');
const submitKey = Key('verify-submit');
const resendKey = Key('verify-resend');
const phone = '+242061234567';

Future<SessionController> pumpVerify(WidgetTester tester, StubAuthRepository auth) async {
  tester.view.physicalSize = const Size(800, 1500);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final session = SessionController(auth: auth, store: InMemoryTokenStore());
  await session.restore();
  final signup = SignupController(auth: auth, session: session, countryCode: 'CG');
  addTearDown(() {
    signup.dispose();
    session.dispose();
  });
  await tester.pumpWidget(
    MaterialApp(theme: AppTheme.light(), home: VerifyPhonePage(controller: signup, phone: phone)),
  );
  await tester.pumpAndSettle();
  return session;
}

Future<void> submitCode(WidgetTester tester, String code) async {
  await tester.enterText(find.byKey(codeKey), code);
  await tester.tap(find.byKey(submitKey));
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await Strings.load();
  });

  testWidgets('shows the number the code was sent to, and the code field has its help tooltip',
      (tester) async {
    await pumpVerify(tester, StubAuthRepository());
    expect(find.text(Strings.t('auth.verify.intro', params: {'phone': phone})), findsOneWidget);
    expect(find.byTooltip(Strings.t('auth.verify.fields.code.help')), findsOneWidget);
  });

  testWidgets('empty code: local message, no request sent', (tester) async {
    final auth = StubAuthRepository();
    await pumpVerify(tester, auth);
    await tester.tap(find.byKey(submitKey));
    await tester.pumpAndSettle();
    expect(find.text(Strings.t('auth.verify.validation.codeRequired')), findsOneWidget);
    expect(auth.verifyCalls, isEmpty);
  });

  testWidgets('nominal: sends phone and code, signs in', (tester) async {
    final auth = StubAuthRepository();
    final session = await pumpVerify(tester, auth);
    await submitCode(tester, '123456');
    expect(auth.verifyCalls.single, (phone: phone, code: '123456'));
    expect(session.status, SessionStatus.signedIn);
  });

  for (final code in const ['CODE_INVALID', 'CODE_EXPIRED']) {
    testWidgets('$code: its own message, still signed out', (tester) async {
      final auth = StubAuthRepository()..verifyError = ApiException(status: 422, code: code);
      final session = await pumpVerify(tester, auth);
      await submitCode(tester, '000000');
      expect(find.text(Strings.error(code)), findsOneWidget);
      expect(Strings.error(code), isNot(Strings.error('UNKNOWN')));
      expect(session.status, SessionStatus.signedOut);
    });
  }

  testWidgets('resend: asks for a new code and says so', (tester) async {
    final auth = StubAuthRepository();
    await pumpVerify(tester, auth);
    await tester.tap(find.byKey(resendKey));
    await tester.pumpAndSettle();
    expect(auth.resendCalls, [phone]);
    expect(find.text(Strings.t('auth.verify.resent')), findsOneWidget);
  });

  testWidgets('resend too soon: shows the delay', (tester) async {
    final auth = StubAuthRepository()
      ..resendError = const ApiException(status: 429, code: 'RATE_LIMITED', retryAfterSeconds: 45);
    await pumpVerify(tester, auth);
    await tester.tap(find.byKey(resendKey));
    await tester.pumpAndSettle();
    expect(find.text(Strings.error('RATE_LIMITED', retryAfterSeconds: 45)), findsOneWidget);
    expect(find.text(Strings.t('auth.verify.resent')), findsNothing);
  });

  testWidgets('offline: shows the network message', (tester) async {
    final auth = StubAuthRepository()..verifyError = const NetworkException();
    await pumpVerify(tester, auth);
    await submitCode(tester, '123456');
    expect(find.text(Strings.error('NETWORK')), findsOneWidget);
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:servnova_mobile/core/api/api_exception.dart';
import 'package:servnova_mobile/core/l10n/strings.dart';
import 'package:servnova_mobile/core/theme/app_theme.dart';
import 'package:servnova_mobile/features/auth/data/token_store.dart';
import 'package:servnova_mobile/features/auth/presentation/login_page.dart';
import 'package:servnova_mobile/features/auth/presentation/session_controller.dart';
import 'package:servnova_mobile/features/auth/presentation/signup_controller.dart';
import 'package:servnova_mobile/features/auth/presentation/signup_page.dart';
import 'package:servnova_mobile/features/auth/presentation/verify_phone_page.dart';

import '../../support/stub_auth.dart';

const createKey = Key('login-create-account');
const verifyKey = Key('login-verify-phone');

Future<void> pumpLogin(WidgetTester tester, StubAuthRepository auth, {required bool withSignup}) async {
  tester.view.physicalSize = const Size(800, 1800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final session = SessionController(auth: auth, store: InMemoryTokenStore());
  final signup = SignupController(auth: auth, session: session, countryCode: 'CG');
  addTearDown(() {
    signup.dispose();
    session.dispose();
  });
  await tester.pumpWidget(MaterialApp(
    theme: AppTheme.light(),
    home: LoginPage(session: session, signup: withSignup ? signup : null),
  ));
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await Strings.load();
  });

  testWidgets('"Créer un compte" opens the sign-up form', (tester) async {
    await pumpLogin(tester, StubAuthRepository(), withSignup: true);
    await tester.tap(find.byKey(createKey));
    await tester.pumpAndSettle();
    expect(find.byType(SignupPage), findsOneWidget);
  });

  testWidgets('without the sign-up flow (no controller) there is no such link', (tester) async {
    await pumpLogin(tester, StubAuthRepository(), withSignup: false);
    expect(find.byKey(createKey), findsNothing);
    expect(find.byKey(verifyKey), findsNothing);
  });

  testWidgets('PHONE_NOT_VERIFIED offers to verify the number, which opens the code page',
      (tester) async {
    final auth = StubAuthRepository()
      ..loginError = const ApiException(status: 403, code: 'PHONE_NOT_VERIFIED');
    await pumpLogin(tester, auth, withSignup: true);
    expect(find.byKey(verifyKey), findsNothing, reason: 'only after that error');

    await tester.enterText(find.byKey(const Key('login-phone')), '+242 06 123 45 67');
    await tester.enterText(find.byKey(const Key('login-password')), 'secret');
    await tester.tap(find.byKey(const Key('login-submit')));
    await tester.pumpAndSettle();
    expect(find.text(Strings.error('PHONE_NOT_VERIFIED')), findsOneWidget);

    await tester.tap(find.byKey(verifyKey));
    await tester.pumpAndSettle();
    expect(find.byType(VerifyPhonePage), findsOneWidget);
    expect(find.text(Strings.t('auth.verify.intro', params: {'phone': '+242061234567'})), findsOneWidget);
  });

  testWidgets('other login errors do not offer to verify the number', (tester) async {
    final auth = StubAuthRepository()
      ..loginError = const ApiException(status: 401, code: 'INVALID_CREDENTIALS');
    await pumpLogin(tester, auth, withSignup: true);
    await tester.enterText(find.byKey(const Key('login-phone')), '+242061234567');
    await tester.enterText(find.byKey(const Key('login-password')), 'bad');
    await tester.tap(find.byKey(const Key('login-submit')));
    await tester.pumpAndSettle();
    expect(find.byKey(verifyKey), findsNothing);
  });
}

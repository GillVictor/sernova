import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:servnova_mobile/core/api/api_exception.dart';
import 'package:servnova_mobile/core/l10n/strings.dart';
import 'package:servnova_mobile/core/theme/app_theme.dart';
import 'package:servnova_mobile/features/auth/data/token_store.dart';
import 'package:servnova_mobile/features/auth/presentation/login_page.dart';
import 'package:servnova_mobile/features/auth/presentation/session_controller.dart';

import '../../support/stub_auth.dart';

const phoneKey = Key('login-phone');
const passwordKey = Key('login-password');
const submitKey = Key('login-submit');

Future<SessionController> pumpLogin(WidgetTester tester, StubAuthRepository auth) async {
  tester.view.physicalSize = const Size(800, 1500);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final session = SessionController(auth: auth, store: InMemoryTokenStore());
  addTearDown(session.dispose);
  await tester.pumpWidget(MaterialApp(theme: AppTheme.light(), home: LoginPage(session: session)));
  await tester.pumpAndSettle();
  return session;
}

Future<void> submit(WidgetTester tester, {String phone = '', String password = ''}) async {
  await tester.enterText(find.byKey(phoneKey), phone);
  await tester.enterText(find.byKey(passwordKey), password);
  await tester.tap(find.byKey(submitKey));
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await Strings.load();
  });

  testWidgets('every field has its help tooltip', (tester) async {
    await pumpLogin(tester, StubAuthRepository());
    for (final k in ['phone', 'password']) {
      expect(find.byTooltip(Strings.t('auth.login.fields.$k.help')), findsOneWidget, reason: k);
    }
  });

  testWidgets('the password is hidden until the user asks to show it', (tester) async {
    await pumpLogin(tester, StubAuthRepository());
    bool obscured() => tester.widget<TextField>(find.byKey(passwordKey)).obscureText;
    expect(obscured(), isTrue);
    await tester.tap(find.byTooltip(Strings.t('auth.login.fields.password.show')));
    await tester.pump();
    expect(obscured(), isFalse);
  });

  testWidgets('empty fields: local messages, no request sent', (tester) async {
    final auth = StubAuthRepository();
    await pumpLogin(tester, auth);
    await submit(tester);
    expect(find.text(Strings.t('auth.login.validation.phoneRequired')), findsOneWidget);
    expect(find.text(Strings.t('auth.login.validation.passwordRequired')), findsOneWidget);
    expect(auth.loginCalls, isEmpty);
  });

  testWidgets('nominal: sends the credentials and signs in', (tester) async {
    final auth = StubAuthRepository();
    final session = await pumpLogin(tester, auth);
    await submit(tester, phone: '+242060000000', password: 'secret');
    expect(auth.loginCalls.single.phone, '+242060000000');
    expect(auth.loginCalls.single.password, 'secret');
    expect(session.status, SessionStatus.signedIn);
  });

  testWidgets('wrong credentials: the contract error is shown in French', (tester) async {
    final auth = StubAuthRepository()
      ..loginError = const ApiException(status: 401, code: 'INVALID_CREDENTIALS');
    final session = await pumpLogin(tester, auth);
    await submit(tester, phone: '+242060000000', password: 'bad');
    expect(find.text(Strings.error('INVALID_CREDENTIALS')), findsOneWidget);
    expect(session.status, SessionStatus.signedOut);
  });

  for (final code in const ['ACCOUNT_SUSPENDED', 'PHONE_NOT_VERIFIED']) {
    testWidgets('$code has its own message', (tester) async {
      final auth = StubAuthRepository()..loginError = ApiException(status: 423, code: code);
      await pumpLogin(tester, auth);
      await submit(tester, phone: 'p', password: 'x');
      expect(Strings.error(code), isNot(Strings.error('UNKNOWN')));
      expect(find.text(Strings.error(code)), findsOneWidget);
    });
  }

  testWidgets('rate limit: shows the delay from Retry-After', (tester) async {
    final auth = StubAuthRepository()
      ..loginError = const ApiException(status: 429, code: 'RATE_LIMITED', retryAfterSeconds: 30);
    await pumpLogin(tester, auth);
    await submit(tester, phone: 'p', password: 'x');
    expect(find.text(Strings.error('RATE_LIMITED', retryAfterSeconds: 30)), findsOneWidget);
  });

  testWidgets('offline: shows the network message', (tester) async {
    final auth = StubAuthRepository()..loginError = const NetworkException();
    await pumpLogin(tester, auth);
    await submit(tester, phone: 'p', password: 'x');
    expect(find.text(Strings.error('NETWORK')), findsOneWidget);
  });
}

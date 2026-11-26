import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:servnova_mobile/core/l10n/strings.dart';
import 'package:servnova_mobile/core/theme/app_theme.dart';
import 'package:servnova_mobile/features/auth/data/token_store.dart';
import 'package:servnova_mobile/features/auth/presentation/auth_gate.dart';
import 'package:servnova_mobile/features/auth/presentation/login_page.dart';
import 'package:servnova_mobile/features/auth/presentation/session_controller.dart';
import 'package:servnova_mobile/features/auth/presentation/signup_controller.dart';
import 'package:servnova_mobile/features/auth/presentation/signup_page.dart';
import 'package:servnova_mobile/features/auth/presentation/verify_phone_page.dart';

import '../../support/stub_auth.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await Strings.load();
  });

  testWidgets('login screen -> sign up -> SMS code -> signed in, with the stack cleared', (tester) async {
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final auth = StubAuthRepository();
    final session = SessionController(auth: auth, store: InMemoryTokenStore());
    final signup = SignupController(auth: auth, session: session, countryCode: 'CG');
    addTearDown(() {
      signup.dispose();
      session.dispose();
    });

    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.light(),
      home: AuthGate(
        session: session,
        signup: signup,
        signedInBuilder: (_) => const Scaffold(body: Text('signed-in-area')),
      ),
    ));
    await session.restore();
    await tester.pumpAndSettle();
    expect(find.byType(LoginPage), findsOneWidget);

    await tester.tap(find.byKey(const Key('login-create-account')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('signup-phone')), '+242 06 123 45 67');
    await tester.enterText(find.byKey(const Key('signup-name')), 'Test User');
    await tester.enterText(find.byKey(const Key('signup-password')), 'pw-1');
    await tester.enterText(find.byKey(const Key('signup-confirm')), 'pw-1');
    await tester.tap(find.byKey(const Key('signup-submit')));
    await tester.pumpAndSettle();
    expect(find.byType(VerifyPhonePage), findsOneWidget);

    await tester.enterText(find.byKey(const Key('verify-code')), '123456');
    await tester.tap(find.byKey(const Key('verify-submit')));
    await tester.pumpAndSettle();

    expect(session.status, SessionStatus.signedIn);
    expect(find.text('signed-in-area'), findsOneWidget);
    expect(find.byType(SignupPage), findsNothing, reason: 'the sign-up pages were removed');
    expect(find.byType(VerifyPhonePage), findsNothing);
  });
}

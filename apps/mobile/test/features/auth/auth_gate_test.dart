import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:servnova_mobile/core/l10n/strings.dart';
import 'package:servnova_mobile/core/theme/app_theme.dart';
import 'package:servnova_mobile/features/auth/data/token_store.dart';
import 'package:servnova_mobile/features/auth/presentation/auth_gate.dart';
import 'package:servnova_mobile/features/auth/presentation/login_page.dart';
import 'package:servnova_mobile/features/auth/presentation/session_controller.dart';

import '../../support/stub_auth.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await Strings.load();
  });

  late StubAuthRepository auth;
  late InMemoryTokenStore store;
  late SessionController session;

  Future<void> pumpGate(WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1500);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.light(),
      home: AuthGate(
        session: session,
        signedInBuilder: (_) => const Scaffold(body: Text('signed-in-area')),
      ),
    ));
    await tester.pump();
  }

  setUp(() {
    auth = StubAuthRepository();
    store = InMemoryTokenStore();
    session = SessionController(auth: auth, store: store);
  });

  tearDown(() => session.dispose());

  testWidgets('while the stored session is being checked: a spinner, no login form', (tester) async {
    await pumpGate(tester);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.byType(LoginPage), findsNothing);
    expect(find.text('signed-in-area'), findsNothing);
  });

  testWidgets('no stored session: the login page', (tester) async {
    await pumpGate(tester);
    await session.restore();
    await tester.pumpAndSettle();
    expect(find.byType(LoginPage), findsOneWidget);
    expect(find.text('signed-in-area'), findsNothing);
  });

  testWidgets('a valid stored session opens the signed-in area directly', (tester) async {
    await store.writeRefreshToken('stored');
    await pumpGate(tester);
    await session.restore();
    await tester.pumpAndSettle();
    expect(find.text('signed-in-area'), findsOneWidget);
    expect(find.byType(LoginPage), findsNothing);
  });

  testWidgets('logging out brings the login page back', (tester) async {
    await pumpGate(tester);
    await session.login(phone: 'p', password: 'x');
    await tester.pumpAndSettle();
    expect(find.text('signed-in-area'), findsOneWidget);

    await session.logout();
    await tester.pumpAndSettle();
    expect(find.byType(LoginPage), findsOneWidget);
    expect(find.text('signed-in-area'), findsNothing);
  });
}

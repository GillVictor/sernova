import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:servnova_mobile/core/api/api_exception.dart';
import 'package:servnova_mobile/core/l10n/strings.dart';
import 'package:servnova_mobile/core/theme/app_theme.dart';
import 'package:servnova_mobile/features/account/domain/account_summary.dart';
import 'package:servnova_mobile/features/account/presentation/client_account_page.dart';
import 'package:servnova_mobile/features/provider/domain/provider_models.dart';
import 'package:servnova_mobile/features/provider/presentation/become_provider_page.dart';

import '../../support/stub_catalog_repository.dart';
import '../../support/stub_space.dart';

Future<void> pumpAccount(WidgetTester tester, StubSpace s, {VoidCallback? onActivated}) async {
  tester.view.physicalSize = const Size(800, 2000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(MaterialApp(
    theme: AppTheme.light(),
    home: ClientAccountPage(
      account: s,
      provider: s,
      catalog: StubCatalogRepository(),
      onProviderActivated: onActivated,
    ),
  ));
  await tester.pumpAndSettle();
}

StubSpace simpleClient() => StubSpace()
  ..account = const AccountSummary(displayName: 'Awa N.', providerStatus: ProviderStatus.unknown);

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await Strings.load();
  });

  testWidgets('a simple client sees their name and the way to become a provider', (tester) async {
    await pumpAccount(tester, simpleClient());
    expect(find.text('Awa N.'), findsOneWidget);
    expect(find.byKey(const Key('account-become-provider')), findsOneWidget);
    expect(find.byKey(const Key('account-provider-active')), findsNothing);
  });

  testWidgets('an active provider is told so and gets no button', (tester) async {
    await pumpAccount(tester, StubSpace()); // active by default
    expect(find.byKey(const Key('account-provider-active')), findsOneWidget);
    expect(find.byKey(const Key('account-become-provider')), findsNothing);
  });

  testWidgets('the button opens the activation page', (tester) async {
    await pumpAccount(tester, simpleClient());
    await tester.tap(find.byKey(const Key('account-become-provider')));
    await tester.pumpAndSettle();
    expect(find.byType(BecomeProviderPage), findsOneWidget);
  });

  testWidgets('a failed load shows the error and can be retried', (tester) async {
    final s = simpleClient()..accountError = const NetworkException();
    await pumpAccount(tester, s);
    expect(find.text(Strings.error('NETWORK')), findsOneWidget);
    s.accountError = null;
    await tester.tap(find.text(Strings.t('common.retry')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('account-become-provider')), findsOneWidget);
  });
}

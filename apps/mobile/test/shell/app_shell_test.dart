import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:servnova_mobile/app_dependencies.dart';
import 'package:servnova_mobile/core/api/api_exception.dart';
import 'package:servnova_mobile/core/l10n/strings.dart';
import 'package:servnova_mobile/core/theme/app_theme.dart';
import 'package:servnova_mobile/features/account/domain/account_summary.dart';
import 'package:servnova_mobile/features/catalog/presentation/search_results_page.dart';
import 'package:servnova_mobile/features/provider/domain/provider_models.dart';
import 'package:servnova_mobile/shell/app_role.dart';
import 'package:servnova_mobile/shell/app_shell.dart';

import '../support/stub_catalog_repository.dart';
import '../support/stub_space.dart';

Future<void> pumpShell(
  WidgetTester tester,
  StubSpace s, {
  AppRole preferredRole = AppRole.client,
  NavPlacement placement = NavPlacement.rightRail,
}) async {
  tester.view.physicalSize = const Size(800, 1500);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(MaterialApp(
    theme: AppTheme.light(),
    home: AppShell(
      deps: AppDependencies(
        catalog: StubCatalogRepository(),
        provider: s,
        account: s,
        orders: s,
        requests: s,
        notifications: s,
      ),
      preferredRole: preferredRole,
      placement: placement,
    ),
  ));
  await tester.pumpAndSettle();
}

StubSpace simpleClient() => StubSpace()
  ..account = const AccountSummary(displayName: 'Awa N.', providerStatus: ProviderStatus.unknown);

String switchTip(String role) => Strings.t('shell.role.switchTo', params: {'role': role});

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await Strings.load();
  });

  testWidgets('a simple client sees no role buttons and the 4-entry client menu', (tester) async {
    await pumpShell(tester, simpleClient());

    expect(find.byTooltip(switchTip('Client')), findsNothing);
    expect(find.byTooltip(switchTip('Prestataire')), findsNothing);
    for (final label in ['Accueil', 'Demandes', 'Commandes', 'Compte']) {
      expect(find.text(label), findsOneWidget, reason: label);
    }
    expect(find.text('Mes offres'), findsNothing);
    expect(find.byType(SearchResultsPage), findsOneWidget);
  });

  testWidgets('an active provider sees both role buttons at the top of the menu', (tester) async {
    await pumpShell(tester, StubSpace());

    expect(find.byTooltip(switchTip('Client')), findsOneWidget);
    expect(find.byTooltip(switchTip('Prestataire')), findsOneWidget);
    expect(find.text('Mes offres'), findsNothing); // still in client mode
  });

  testWidgets('the menu is on the right of the pages', (tester) async {
    await pumpShell(tester, StubSpace());
    final rail = tester.getTopLeft(find.byType(NavigationRail)).dx;
    final page = tester.getTopLeft(find.byType(SearchResultsPage)).dx;
    expect(rail, greaterThan(page));
  });

  testWidgets('switching to the provider role changes menu and page', (tester) async {
    await pumpShell(tester, StubSpace());

    await tester.tap(find.byTooltip(switchTip('Prestataire')));
    await tester.pumpAndSettle();

    expect(find.text('Mes offres'), findsOneWidget);
    expect(find.text('Tableau de bord'), findsOneWidget);

    await tester.tap(find.byTooltip(switchTip('Client')));
    await tester.pumpAndSettle();
    expect(find.text('Mes offres'), findsNothing);
    expect(find.byType(SearchResultsPage), findsOneWidget);
  });

  testWidgets('the preferred provider role opens the dashboard when allowed', (tester) async {
    await pumpShell(tester, StubSpace(), preferredRole: AppRole.provider);
    expect(find.text('Tableau de bord'), findsOneWidget);
  });

  testWidgets('the preferred provider role is ignored without an active profile', (tester) async {
    await pumpShell(tester, simpleClient(), preferredRole: AppRole.provider);
    expect(find.text('Tableau de bord'), findsNothing);
    expect(find.byType(SearchResultsPage), findsOneWidget);
  });

  testWidgets('an account that cannot be loaded behaves as a simple client', (tester) async {
    final s = StubSpace()..accountError = const NetworkException();
    await pumpShell(tester, s);
    expect(find.byTooltip(switchTip('Prestataire')), findsNothing);
    expect(find.byType(SearchResultsPage), findsOneWidget);
  });

  testWidgets('an entry without screen shows the "bientôt disponible" page', (tester) async {
    await pumpShell(tester, simpleClient());
    await tester.tap(find.text('Commandes'));
    await tester.pumpAndSettle();
    expect(find.text(Strings.t('shell.comingSoon.title')), findsOneWidget);
  });

  testWidgets('"Voir les commandes" of the dashboard selects the Commandes tab', (tester) async {
    await pumpShell(tester, StubSpace(), preferredRole: AppRole.provider);

    await tester.tap(find.text('Voir les commandes'));
    await tester.pumpAndSettle();
    expect(find.text(Strings.t('shell.comingSoon.title')), findsOneWidget);
  });

  testWidgets('the avatar of the dashboard opens the Compte tab (professional profile)',
      (tester) async {
    await pumpShell(tester, StubSpace(), preferredRole: AppRole.provider);

    await tester.tap(find.text('JM'));
    await tester.pumpAndSettle();
    expect(find.text('Mon profil professionnel'), findsOneWidget);
  });

  testWidgets('the bottom-bar placement keeps the same behaviour', (tester) async {
    await pumpShell(tester, StubSpace(), placement: NavPlacement.bottomBar);
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.byType(NavigationRail), findsNothing);

    await tester.tap(find.byTooltip(switchTip('Prestataire')));
    await tester.pumpAndSettle();
    expect(find.text('Mes offres'), findsOneWidget);
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:servnova_mobile/core/l10n/strings.dart';
import 'package:servnova_mobile/core/theme/app_theme.dart';
import 'package:servnova_mobile/features/notifications/domain/notification_models.dart';
import 'package:servnova_mobile/features/provider/presentation/dashboard_page.dart';

import '../../support/stub_space.dart';

final _now = DateTime.utc(2026, 11, 21, 12);

Future<void> pumpDashboard(
  WidgetTester tester,
  StubSpace s, {
  VoidCallback? onOpenOrders,
  VoidCallback? onOpenProfile,
}) async {
  tester.view.physicalSize = const Size(800, 2600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(MaterialApp(
    theme: AppTheme.light(),
    home: ProviderDashboardPage(
      provider: s,
      account: s,
      orders: s,
      requests: s,
      notifications: s,
      now: () => _now,
      onOpenOrders: onOpenOrders,
      onOpenProfile: onOpenProfile,
    ),
  ));
  await tester.pumpAndSettle();
}

StubSpace withNotification() => StubSpace()
  ..notifications = [
    AppNotification(
      id: 'n1',
      content: 'Nouvelle commande reçue (#1024)',
      read: false,
      createdAt: _now.subtract(const Duration(hours: 1)),
    ),
  ];

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await Strings.load();
  });

  testWidgets('shows the four stats, the role chip and the title', (tester) async {
    await pumpDashboard(tester, withNotification());

    expect(find.text('Tableau de bord'), findsOneWidget);
    expect(find.text('Jean M. · Prestataire'), findsOneWidget);
    expect(find.text('Commandes en cours'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
    expect(find.text('12'), findsOneWidget);
    expect(find.text('96 %'), findsOneWidget);
    expect(find.text('4,7'), findsOneWidget);
    expect(find.text('Actif'), findsOneWidget);
    expect(find.text('Nouveau'), findsOneWidget);
    expect(find.text('Taux'), findsOneWidget);
  });

  testWidgets('lists the recent orders with reference, client and status', (tester) async {
    await pumpDashboard(tester, withNotification());

    expect(find.text('4 récentes'), findsOneWidget);
    expect(find.textContaining('Création de site vitrine'), findsOneWidget);
    expect(find.text('Client : Marie L.'), findsOneWidget);
    expect(find.text('En attente'), findsOneWidget);
    expect(find.text('En cours'), findsOneWidget);
    expect(find.text('Acceptée'), findsOneWidget);
    expect(find.text('Terminée'), findsOneWidget);
  });

  testWidgets('notifications show a relative time and can be marked as read', (tester) async {
    final s = withNotification();
    await pumpDashboard(tester, s);

    expect(find.text('Nouvelle commande reçue (#1024)'), findsOneWidget);
    expect(find.text('il y a 1 h'), findsOneWidget);

    await tester.tap(find.text('Tout marquer lu'));
    await tester.pumpAndSettle();
    expect(s.markAllReadCalls, 1);
    expect(find.text('Tout marquer lu'), findsNothing);
  });

  testWidgets('"Voir les commandes" only with a handler; avatar opens the profile', (tester) async {
    await pumpDashboard(tester, withNotification());
    expect(find.text('Voir les commandes'), findsNothing);

    var orders = false;
    var profile = false;
    await pumpDashboard(tester, withNotification(),
        onOpenOrders: () => orders = true, onOpenProfile: () => profile = true);
    await tester.tap(find.text('Voir les commandes'));
    await tester.tap(find.text('JM'));
    expect(orders, isTrue);
    expect(profile, isTrue);
  });

  testWidgets('a failing orders block shows a retry while the stats stay', (tester) async {
    final s = withNotification()..ordersError = Exception('boom');
    await pumpDashboard(tester, s);

    expect(find.text(Strings.t('provider.dashboard.sectionError')), findsOneWidget);
    expect(find.text('4,7'), findsOneWidget); // profile block unaffected
    expect(find.text('Nouvelle commande reçue (#1024)'), findsOneWidget);
  });
}

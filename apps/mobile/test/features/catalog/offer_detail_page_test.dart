import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:servnova_mobile/core/api/api_exception.dart';
import 'package:servnova_mobile/core/format/money.dart';
import 'package:servnova_mobile/core/l10n/strings.dart';
import 'package:servnova_mobile/core/theme/app_theme.dart';
import 'package:servnova_mobile/features/catalog/domain/enums.dart';
import 'package:servnova_mobile/features/catalog/domain/offer_models.dart';
import 'package:servnova_mobile/features/catalog/presentation/offer_detail_page.dart';

import '../../support/stub_catalog_repository.dart';

Future<void> pumpDetail(
  WidgetTester tester,
  StubCatalogRepository repo, {
  void Function(ProviderSummary)? onOpenProvider,
  void Function(OfferDetail)? onOrder,
}) async {
  // Tall surface so the whole (lazily built) list is on screen.
  tester.view.physicalSize = const Size(800, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(MaterialApp(
    theme: AppTheme.light(),
    home: OfferDetailPage(
      repository: repo,
      offerId: 'o1',
      onOpenProvider: onOpenProvider,
      onOrder: onOrder,
    ),
  ));
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await Strings.load();
  });

  testWidgets('shows title, price, chips, description and provider block', (tester) async {
    final repo = StubCatalogRepository(onFetchOffer: (_) async => makeDetail());
    await pumpDetail(tester, repo);

    expect(find.text('Développement web professionnel'), findsOneWidget);
    // Caption and amount share one rich text: "Prix 50 000 FCFA".
    expect(find.textContaining('50\u202F000\u00A0FCFA'), findsOneWidget);
    expect(find.text('Dakar'), findsOneWidget); // location chip
    expect(find.text('À distance'), findsOneWidget); // modality chip
    expect(find.text('Création de sites web modernes, rapides et sécurisés.'), findsOneWidget);
    expect(find.text('Mamadou Diop'), findsOneWidget);
    expect(find.text('98% de prestations achevées'), findsOneWidget);
    expect(find.text('(256 avis)'), findsNWidgets(2)); // offer header + provider
    expect(find.text('Vérifié'), findsOneWidget); // chip (badge icons carry no text)
  });

  testWidgets('hides the verified chip below level N2 and the completion line when unknown',
      (tester) async {
    final repo = StubCatalogRepository(
      onFetchOffer: (_) async =>
          makeDetail(level: VerificationLevel.n1, completionRate: null),
    );
    await pumpDetail(tester, repo);
    expect(find.text('Vérifié'), findsNothing);
    expect(find.textContaining('prestations achevées'), findsNothing);
  });

  testWidgets('order and profile buttons only appear when handlers are given', (tester) async {
    final repo = StubCatalogRepository(onFetchOffer: (_) async => makeDetail());
    await pumpDetail(tester, repo);
    expect(find.text(Strings.t('detail.order')), findsNothing);
    expect(find.text(Strings.t('detail.viewProfile')), findsNothing);

    OfferDetail? ordered;
    ProviderSummary? opened;
    await pumpDetail(tester, repo, onOrder: (d) => ordered = d, onOpenProvider: (p) => opened = p);
    await tester.tap(find.text(Strings.t('detail.viewProfile')));
    await tester.tap(find.text(Strings.t('detail.order')));
    expect(opened?.id, 'p1');
    expect(ordered?.offer.id, 'o1');
  });

  testWidgets('long description collapses and expands', (tester) async {
    final long = List.filled(60, 'Intervention rapide et soignée.').join(' ');
    final repo = StubCatalogRepository(onFetchOffer: (_) async => makeDetail(description: long));
    await pumpDetail(tester, repo);

    expect(find.text(Strings.t('detail.readMore')), findsOneWidget);
    await tester.tap(find.text(Strings.t('detail.readMore')));
    await tester.pumpAndSettle();
    expect(find.text(Strings.t('detail.readLess')), findsOneWidget);
  });

  testWidgets('photo counter appears with several photos', (tester) async {
    final repo = StubCatalogRepository(
      onFetchOffer: (_) async => makeDetail(photoUrls: const ['https://x.test/a.jpg', 'https://x.test/b.jpg', 'https://x.test/c.jpg']),
    );
    await pumpDetail(tester, repo);
    expect(find.text('1 / 3'), findsOneWidget);
  });

  testWidgets('sale items list shows availability', (tester) async {
    final repo = StubCatalogRepository(
      onFetchOffer: (_) async => makeDetail(items: const [
        OfferItem(
            id: 'i1',
            designation: 'Robe wax',
            available: true,
            price: Money(amount: 8000, currency: 'XAF')),
        OfferItem(id: 'i2', designation: 'Pagne', available: false),
      ]),
    );
    await pumpDetail(tester, repo);
    expect(find.text('Robe wax'), findsOneWidget);
    expect(find.text('8\u202F000\u00A0FCFA'), findsOneWidget);
    expect(find.text(Strings.t('detail.itemUnavailable')), findsOneWidget);
  });

  testWidgets('404 shows the not-found message without a retry button', (tester) async {
    final repo = StubCatalogRepository(
      onFetchOffer: (_) async => throw const ApiException(status: 404, code: 'NOT_FOUND'),
    );
    await pumpDetail(tester, repo);
    expect(find.text(Strings.t('detail.notFound.title')), findsOneWidget);
    expect(find.text(Strings.t('common.retry')), findsNothing);
  });

  testWidgets('network error offers a retry that reloads', (tester) async {
    var fail = true;
    final repo = StubCatalogRepository(onFetchOffer: (_) async {
      if (fail) throw const NetworkException();
      return makeDetail();
    });
    await pumpDetail(tester, repo);
    expect(find.text(Strings.error('NETWORK')), findsOneWidget);

    fail = false;
    await tester.tap(find.text(Strings.t('common.retry')));
    await tester.pumpAndSettle();
    expect(find.text('Développement web professionnel'), findsOneWidget);
  });
}

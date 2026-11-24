import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:servnova_mobile/core/api/api_exception.dart';
import 'package:servnova_mobile/core/l10n/strings.dart';
import 'package:servnova_mobile/core/theme/app_theme.dart';
import 'package:servnova_mobile/features/catalog/domain/enums.dart';
import 'package:servnova_mobile/features/catalog/domain/offer_models.dart';
import 'package:servnova_mobile/features/catalog/presentation/search_results_page.dart';
import 'package:servnova_mobile/shared/widgets/help_tooltip.dart';

import '../../support/stub_catalog_repository.dart';

Future<void> pumpPage(
  WidgetTester tester,
  StubCatalogRepository repo, {
  VoidCallback? onPublishNeed,
  VoidCallback? onOpenMap,
  void Function(OfferSearchItem)? onOpenOffer,
}) async {
  await tester.pumpWidget(MaterialApp(
    theme: AppTheme.light(),
    home: SearchResultsPage(
      repository: repo,
      debounce: const Duration(milliseconds: 10),
      onPublishNeed: onPublishNeed,
      onOpenMap: onOpenMap,
      onOpenOffer: onOpenOffer,
    ),
  ));
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await Strings.load();
  });

  testWidgets('shows result cards with rating, location, price and verified badge',
      (tester) async {
    final repo = StubCatalogRepository(
      onSearch: (q) async => OfferSearchPage(items: [
        makeItem('1', title: 'Réparation fuite d\'eau'),
        makeItem('2', title: 'Installation sanitaire', price: 20000, level: VerificationLevel.n0),
      ]),
    );
    await pumpPage(tester, repo);

    expect(find.text('Réparation fuite d\'eau'), findsOneWidget);
    expect(find.text('4,8'), findsNWidgets(2));
    expect(find.text('(124 avis)'), findsNWidgets(2));
    expect(find.text('Dakar, Plateau'), findsNWidgets(2));
    expect(find.text('15\u202F000\u00A0FCFA'), findsOneWidget);
    expect(find.text('20\u202F000\u00A0FCFA'), findsOneWidget);
    expect(find.byIcon(Icons.verified), findsOneWidget); // only the N2 provider
  });

  testWidgets('every input has a help tooltip with its French text', (tester) async {
    await pumpPage(tester, StubCatalogRepository());
    expect(find.byType(HelpTooltip), findsOneWidget); // search field
    expect(find.byTooltip(Strings.t('search.fields.query.help')), findsOneWidget);
    // Filter chips carry their help on long press.
    expect(find.byTooltip(Strings.t('search.fields.category.help')), findsOneWidget);
    expect(find.byTooltip(Strings.t('search.fields.location.help')), findsOneWidget);
    expect(find.byTooltip(Strings.t('search.fields.sort.help')), findsOneWidget);
  });

  testWidgets('typing searches after the debounce', (tester) async {
    final repo = StubCatalogRepository();
    await pumpPage(tester, repo);
    expect(repo.queries, hasLength(1)); // initial load

    await tester.enterText(find.byType(TextField), 'plombier');
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pumpAndSettle();
    expect(repo.queries.last.q, 'plombier');
  });

  testWidgets('empty state offers to publish a need', (tester) async {
    var published = false;
    await pumpPage(tester, StubCatalogRepository(), onPublishNeed: () => published = true);
    expect(find.text(Strings.t('search.empty.title')), findsOneWidget);
    await tester.tap(find.text(Strings.t('search.empty.publishNeed')));
    expect(published, isTrue);
  });

  testWidgets('error state shows the mapped message and retries', (tester) async {
    var fail = true;
    final repo = StubCatalogRepository(onSearch: (q) async {
      if (fail) throw const NetworkException();
      return OfferSearchPage(items: [makeItem('1')]);
    });
    await pumpPage(tester, repo);
    expect(find.text(Strings.error('NETWORK')), findsOneWidget);

    fail = false;
    await tester.tap(find.text(Strings.t('common.retry')));
    await tester.pumpAndSettle();
    expect(find.text('Réparation fuite d\'eau'), findsOneWidget);
  });

  testWidgets('picking a category filters the search', (tester) async {
    final repo = StubCatalogRepository(
      categories: const [
        CategoryNode(id: 'dom', name: 'Services à domicile', children: [
          CategoryNode(id: 'plomb', name: 'Plomberie'),
        ]),
      ],
    );
    await pumpPage(tester, repo);

    await tester.tap(find.text(Strings.t('search.fields.category.label')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Plomberie'));
    await tester.pumpAndSettle();

    expect(repo.queries.last.categoryId, 'plomb');
    expect(find.text('Plomberie'), findsOneWidget); // chip label
  });

  testWidgets('map button only appears when a handler is given; tap opens detail',
      (tester) async {
    OfferSearchItem? opened;
    final repo = StubCatalogRepository(
      onSearch: (q) async => OfferSearchPage(items: [makeItem('1')]),
    );
    await pumpPage(tester, repo, onOpenMap: () {}, onOpenOffer: (i) => opened = i);
    expect(find.text(Strings.t('search.map')), findsOneWidget);

    await tester.tap(find.text('Réparation fuite d\'eau'));
    expect(opened?.offer.id, '1');
  });

  testWidgets('no map button without handler', (tester) async {
    await pumpPage(tester, StubCatalogRepository());
    expect(find.text(Strings.t('search.map')), findsNothing);
  });
}

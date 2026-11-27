import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:servnova_mobile/core/api/api_exception.dart';
import 'package:servnova_mobile/core/l10n/strings.dart';
import 'package:servnova_mobile/core/theme/app_theme.dart';
import 'package:servnova_mobile/features/catalog/domain/offer_models.dart';
import 'package:servnova_mobile/features/provider/domain/provider_activation.dart';
import 'package:servnova_mobile/features/provider/presentation/become_provider_page.dart';

import '../../support/stub_catalog_repository.dart';
import '../../support/stub_space.dart';

const _plumbing = CategoryNode(id: 'c1', name: 'Plomberie');
const _web = CategoryNode(id: 'c2', name: 'Informatique', children: [
  CategoryNode(id: 'c3', name: 'Sites web'),
]);

StubCatalogRepository catalog() => StubCatalogRepository(
      categories: [_plumbing, _web, for (var i = 4; i <= 9; i++) CategoryNode(id: 'c$i', name: 'Cat $i')],
      locations: const [LocationSuggestion(id: 'l1', city: 'Brazzaville', district: 'Poto-Poto')],
    );

Future<void> pumpPage(
  WidgetTester tester,
  StubSpace s, {
  VoidCallback? onActivated,
  List<bool>? popped,
}) async {
  tester.view.physicalSize = const Size(800, 3000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(MaterialApp(
    theme: AppTheme.light(),
    home: Builder(
      builder: (context) => Scaffold(
        body: TextButton(
          key: const Key('open'),
          onPressed: () async {
            final r = await Navigator.of(context).push<bool>(MaterialPageRoute<bool>(
              builder: (_) => BecomeProviderPage(
                provider: s,
                catalog: catalog(),
                onActivated: onActivated,
              ),
            ));
            if (r != null) popped?.add(r);
          },
          child: const Text('open'),
        ),
      ),
    ),
  ));
  await tester.tap(find.byKey(const Key('open')));
  await tester.pumpAndSettle();
}

Future<void> chooseLocation(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('become-location')));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Brazzaville, Poto-Poto'));
  await tester.pumpAndSettle();
}

Future<void> chooseCategories(WidgetTester tester, List<String> ids) async {
  await tester.tap(find.byKey(const Key('become-categories')));
  await tester.pumpAndSettle();
  for (final id in ids) {
    await tester.tap(find.byKey(Key('category-$id')));
    await tester.pumpAndSettle();
  }
  await tester.tap(find.byKey(const Key('categories-done')));
  await tester.pumpAndSettle();
}

Future<void> fillValid(WidgetTester tester) async {
  await tester.enterText(find.byKey(const Key('become-name')), '  Jean M. – Plomberie ');
  await chooseLocation(tester);
  await chooseCategories(tester, ['c1', 'c3']);
}

Future<void> submit(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('become-submit')));
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await Strings.load();
  });

  testWidgets('every field has its help tooltip', (tester) async {
    await pumpPage(tester, StubSpace());
    for (final f in ['businessName', 'location', 'coverage', 'categories']) {
      expect(find.byTooltip(Strings.t('provider.become.fields.$f.help')), findsOneWidget, reason: f);
    }
    await tester.tap(find.byKey(const Key('coverage-Rayon')));
    await tester.pumpAndSettle();
    expect(find.byTooltip(Strings.t('provider.become.fields.radius.help')), findsOneWidget);
  });

  testWidgets('an empty form is refused locally and nothing is sent', (tester) async {
    final s = StubSpace();
    await pumpPage(tester, s);
    await submit(tester);
    expect(find.text(Strings.t('provider.become.validation.nameRequired')), findsOneWidget);
    expect(find.text(Strings.t('provider.become.validation.locationRequired')), findsOneWidget);
    expect(find.text(Strings.t('provider.become.validation.categoriesRequired')), findsOneWidget);
    expect(s.activations, isEmpty);
  });

  testWidgets('a valid form is sent (default coverage Ville) and the page closes', (tester) async {
    final s = StubSpace();
    var activated = 0;
    final popped = <bool>[];
    await pumpPage(tester, s, onActivated: () => activated++, popped: popped);
    await fillValid(tester);
    await submit(tester);

    final a = s.activations.single;
    expect(a.businessName.trim(), 'Jean M. – Plomberie');
    expect(a.workLocationId, 'l1');
    expect(a.coverageMode, CoverageMode.city);
    expect(a.radiusKm, isNull);
    expect(a.categoryIds, unorderedEquals(['c1', 'c3']));
    expect(activated, 1);
    expect(popped, [true]);
    expect(find.byType(BecomeProviderPage), findsNothing);
  });

  testWidgets('the Rayon mode asks for a radius between 1 and 500', (tester) async {
    final s = StubSpace();
    await pumpPage(tester, s);
    expect(find.byKey(const Key('become-radius')), findsNothing);
    await fillValid(tester);
    await tester.tap(find.byKey(const Key('coverage-Rayon')));
    await tester.pumpAndSettle();

    await submit(tester);
    expect(find.text(Strings.t('provider.become.validation.radiusRange')), findsOneWidget);
    await tester.enterText(find.byKey(const Key('become-radius')), '501');
    await submit(tester);
    expect(find.text(Strings.t('provider.become.validation.radiusRange')), findsOneWidget);
    expect(s.activations, isEmpty);

    await tester.enterText(find.byKey(const Key('become-radius')), '25');
    await submit(tester);
    expect(s.activations.single.coverageMode, CoverageMode.radius);
    expect(s.activations.single.radiusKm, 25);
  });

  testWidgets('at most 5 domains can be chosen', (tester) async {
    await pumpPage(tester, StubSpace());
    await tester.tap(find.byKey(const Key('become-categories')));
    await tester.pumpAndSettle();
    for (final id in ['c1', 'c2', 'c3', 'c4', 'c5']) {
      await tester.tap(find.byKey(Key('category-$id')));
      await tester.pumpAndSettle();
    }
    final sixth = tester.widget<CheckboxListTile>(find.byKey(const Key('category-c6')));
    expect(sixth.onChanged, isNull); // disabled once 5 are chosen
    final first = tester.widget<CheckboxListTile>(find.byKey(const Key('category-c1')));
    expect(first.onChanged, isNotNull); // a chosen one can still be removed
  });

  testWidgets('a server refusal is shown and the page stays open', (tester) async {
    final s = StubSpace()..activateError = const ApiException(status: 409, code: 'PROVIDER_ALREADY_ACTIVE');
    var activated = 0;
    await pumpPage(tester, s, onActivated: () => activated++);
    await fillValid(tester);
    await submit(tester);
    expect(find.text(Strings.error('PROVIDER_ALREADY_ACTIVE')), findsOneWidget);
    expect(activated, 0);
    expect(find.byType(BecomeProviderPage), findsOneWidget);
  });

  testWidgets('a field rejected by the server is marked on the form', (tester) async {
    final s = StubSpace()
      ..activateError = const ApiException(
        status: 422,
        code: 'VALIDATION_FAILED',
        fieldErrors: [FieldError(field: 'businessName', code: 'INVALID')],
      );
    await pumpPage(tester, s);
    await fillValid(tester);
    await submit(tester);
    expect(find.text(Strings.t('provider.become.validation.fieldRejected')), findsOneWidget);
  });
}

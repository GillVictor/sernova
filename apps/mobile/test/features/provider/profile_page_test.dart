import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:servnova_mobile/core/l10n/strings.dart';
import 'package:servnova_mobile/core/theme/app_theme.dart';
import 'package:servnova_mobile/features/catalog/domain/offer_models.dart';
import 'package:servnova_mobile/features/provider/domain/provider_models.dart';
import 'package:servnova_mobile/features/provider/presentation/profile_page.dart';

import '../../support/stub_catalog_repository.dart';
import '../../support/stub_space.dart';

Future<void> pumpProfile(
  WidgetTester tester,
  StubSpace s, {
  StubCatalogRepository? catalog,
  void Function(VerificationType)? onRequestVerification,
}) async {
  tester.view.physicalSize = const Size(800, 3000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(MaterialApp(
    theme: AppTheme.light(),
    home: ProviderProfilePage(
      provider: s,
      account: s,
      catalog: catalog ?? StubCatalogRepository(),
      onRequestVerification: onRequestVerification,
    ),
  ));
  await tester.pumpAndSettle();
}

TextEditingController field(WidgetTester tester, int index) =>
    tester.widget<TextField>(find.byType(TextField).at(index)).controller!;

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await Strings.load();
  });

  testWidgets('prefills the form from the profile', (tester) async {
    await pumpProfile(tester, StubSpace());
    expect(find.text('Mon profil professionnel'), findsOneWidget);
    expect(find.text('Jean M. · Prestataire'), findsOneWidget);
    expect(field(tester, 0).text, 'Jean M. – Plomberie');
    expect(field(tester, 1).text, 'Plombier.');
    expect(find.text('Brazzaville, Poto-Poto'), findsOneWidget);
  });

  testWidgets('every input has its help tooltip', (tester) async {
    await pumpProfile(tester, StubSpace());
    for (final k in ['businessName', 'description', 'location', 'portfolioUrl', 'videoUrl']) {
      expect(find.byTooltip(Strings.t('provider.profile.fields.$k.help')), findsOneWidget, reason: k);
    }
  });

  testWidgets('verification card: level chip and row states', (tester) async {
    await pumpProfile(tester, StubSpace()); // level N1 => phone validated
    expect(find.text('Niveau : Basique'), findsOneWidget);
    expect(find.text('Téléphone vérifié'), findsOneWidget);
    expect(find.text('Validé'), findsOneWidget);
    expect(find.text("Pièce d'identité"), findsOneWidget);
    expect(find.text('Non fournie'), findsNWidgets(2)); // identity + activity
  });

  testWidgets('a rejected verification shows its reason', (tester) async {
    final s = StubSpace()
      ..verifications = [
        const VerificationRecord(
            id: 'v', type: VerificationType.identity, state: ValidationState.rejected, rejectionReason: 'Photo floue'),
      ];
    await pumpProfile(tester, s);
    expect(find.text('Rejetée'), findsOneWidget);
    expect(find.text('Photo floue'), findsOneWidget);
  });

  testWidgets('verification request buttons only with a handler (never for the phone)', (tester) async {
    VerificationType? asked;
    await pumpProfile(tester, StubSpace(), onRequestVerification: (t) => asked = t);
    // Identity row's "Non fournie" becomes tappable.
    await tester.tap(find.widgetWithText(TextButton, 'Non fournie').first);
    expect(asked, VerificationType.identity);
  });

  testWidgets('saving sends only the edited field and confirms', (tester) async {
    final s = StubSpace();
    await pumpProfile(tester, s);

    await tester.enterText(find.byType(TextField).at(1), 'Plombier, 8 ans.');
    await tester.tap(find.text('Enregistrer le profil'));
    await tester.pumpAndSettle();

    expect(s.updates.single.values, {'description': 'Plombier, 8 ans.'});
    expect(find.text('Profil enregistré.'), findsOneWidget);
  });

  testWidgets('empty name and bad link show messages and send nothing', (tester) async {
    final s = StubSpace();
    await pumpProfile(tester, s);

    await tester.enterText(find.byType(TextField).at(0), '');
    await tester.enterText(find.byType(TextField).at(2), 'javascript:alert(1)');
    await tester.tap(find.text('Enregistrer le profil'));
    await tester.pumpAndSettle();

    expect(find.text('Ce champ est obligatoire.'), findsOneWidget);
    expect(find.text(Strings.t('provider.profile.validation.url')), findsOneWidget);
    expect(s.updates, isEmpty);
  });

  testWidgets('picking another location then saving sends workLocationId', (tester) async {
    final s = StubSpace();
    final catalog = StubCatalogRepository(
      locations: const [LocationSuggestion(id: 'l2', city: 'Pointe-Noire')],
    );
    await pumpProfile(tester, s, catalog: catalog);

    await tester.tap(find.text('Brazzaville, Poto-Poto'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Pointe-Noire'));
    await tester.pumpAndSettle();
    expect(find.text('Pointe-Noire'), findsOneWidget);

    await tester.tap(find.text('Enregistrer le profil'));
    await tester.pumpAndSettle();
    expect(s.updates.single.values, {'workLocationId': 'l2'});
  });

  testWidgets('profile not found shows the mapped error with retry', (tester) async {
    final s = StubSpace()..profileError = Exception('x');
    await pumpProfile(tester, s);
    expect(find.text(Strings.t('common.retry')), findsOneWidget);
  });
}

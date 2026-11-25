import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:servnova_mobile/app_dependencies.dart';
import 'package:servnova_mobile/core/l10n/strings.dart';
import 'package:servnova_mobile/core/theme/app_theme.dart';
import 'package:servnova_mobile/shell/app_shell.dart';

import '../support/stub_catalog_repository.dart';
import '../support/stub_space.dart';

Future<void> pumpShell(WidgetTester tester, {VoidCallback? onLogout}) async {
  tester.view.physicalSize = const Size(800, 1500);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final s = StubSpace();
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
      onLogout: onLogout,
    ),
  ));
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await Strings.load();
  });

  testWidgets('with onLogout, the menu offers "Se déconnecter" and calls it', (tester) async {
    var calls = 0;
    await pumpShell(tester, onLogout: () => calls++);
    await tester.tap(find.byTooltip(Strings.t('shell.logout')));
    await tester.pump();
    expect(calls, 1);
  });

  testWidgets('without onLogout (fake or development mode) there is no such button', (tester) async {
    await pumpShell(tester);
    expect(find.byTooltip(Strings.t('shell.logout')), findsNothing);
  });
}

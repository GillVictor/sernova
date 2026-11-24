import 'package:flutter_test/flutter_test.dart';
import 'package:servnova_mobile/core/api/api_exception.dart';
import 'package:servnova_mobile/features/account/domain/account_summary.dart';
import 'package:servnova_mobile/features/provider/domain/provider_models.dart';
import 'package:servnova_mobile/shell/app_role.dart';
import 'package:servnova_mobile/shell/shell_controller.dart';

import '../support/stub_space.dart';

StubSpace spaceWith(ProviderStatus status) => StubSpace()
  ..account = AccountSummary(displayName: 'Jean M.', providerStatus: status);

void main() {
  test('before the account is known the app is a simple client', () {
    final c = ShellController(account: StubSpace());
    expect(c.role, AppRole.client);
    expect(c.canSwitchRole, isFalse);
    c.dispose();
  });

  test('an active provider profile enables the role switch', () async {
    final c = ShellController(account: spaceWith(ProviderStatus.active));
    await c.load();
    expect(c.canSwitchRole, isTrue);
    expect(c.role, AppRole.client); // opens as client by default
    c.selectRole(AppRole.provider);
    expect(c.role, AppRole.provider);
    c.selectRole(AppRole.client);
    expect(c.role, AppRole.client);
    c.dispose();
  });

  test('draft, suspended or unknown profiles never get the provider role', () async {
    for (final status in [ProviderStatus.draft, ProviderStatus.suspended, ProviderStatus.unknown]) {
      final c = ShellController(
        account: spaceWith(status),
        preferredRole: AppRole.provider,
      );
      await c.load();
      expect(c.canSwitchRole, isFalse, reason: status.name);
      c.selectRole(AppRole.provider);
      expect(c.role, AppRole.client, reason: status.name);
      c.dispose();
    }
  });

  test('a failed account load leaves a simple client (no switch)', () async {
    final s = StubSpace()..accountError = const NetworkException();
    final c = ShellController(account: s);
    await c.load();
    expect(c.account.hasFailed, isTrue);
    expect(c.canSwitchRole, isFalse);
    expect(c.role, AppRole.client);
    c.dispose();
  });

  test('the preferred role is applied once, after the first successful load', () async {
    final c = ShellController(
      account: spaceWith(ProviderStatus.active),
      preferredRole: AppRole.provider,
    );
    await c.load();
    expect(c.role, AppRole.provider);

    c.selectRole(AppRole.client);
    await c.load(); // a reload must not push the user back to provider
    expect(c.role, AppRole.client);
    c.dispose();
  });

  test('a reload that finds the profile inactive sends the user back to client', () async {
    final s = spaceWith(ProviderStatus.active);
    final c = ShellController(account: s);
    await c.load();
    c.selectRole(AppRole.provider);

    s.account = const AccountSummary(displayName: 'Jean M.', providerStatus: ProviderStatus.suspended);
    await c.load();
    expect(c.role, AppRole.client);
    expect(c.canSwitchRole, isFalse);
    c.dispose();
  });

  test('each role remembers its own selected tab', () async {
    final c = ShellController(account: spaceWith(ProviderStatus.active));
    await c.load();
    c.selectTab(2); // client tab 2
    c.selectRole(AppRole.provider);
    expect(c.currentTab, 0);
    c.selectTab(4);
    c.selectRole(AppRole.client);
    expect(c.currentTab, 2);
    expect(c.tabIndex(AppRole.provider), 4);
    c.dispose();
  });
}

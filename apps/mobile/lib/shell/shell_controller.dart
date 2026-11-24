import 'package:flutter/foundation.dart';

import '../core/api/api_failure.dart';
import '../core/api/load_state.dart';
import '../features/account/data/account_repository.dart';
import '../features/account/domain/account_summary.dart';
import '../features/provider/domain/provider_models.dart';
import 'app_role.dart';

/// State of the navigation shell: current role, selected tab per role, and
/// whether the role switch is available.
///
/// The provider role is offered only when the account's provider profile is
/// active (D19). Until the account is known, or if it cannot be loaded, the
/// app behaves as a simple client.
class ShellController extends ChangeNotifier {
  ShellController({
    required AccountRepository account,
    this.preferredRole = AppRole.client,
  }) : _account = account;

  final AccountRepository _account;

  /// Role opened first when allowed (development: `--dart-define=START=provider`).
  final AppRole preferredRole;

  AppRole _role = AppRole.client;
  LoadState<AccountSummary> account = const LoadState.loading();
  final Map<AppRole, int> _tab = {AppRole.client: 0, AppRole.provider: 0};
  bool _preferredApplied = false;
  bool _disposed = false;

  AppRole get role => _role;

  bool get canSwitchRole => account.data?.providerStatus == ProviderStatus.active;

  /// Selected tab index of [r] (each role remembers its own tab).
  int tabIndex(AppRole r) => _tab[r] ?? 0;
  int get currentTab => tabIndex(_role);

  Future<void> load() async {
    try {
      account = LoadState.data(await _account.fetchMe());
    } catch (e) {
      account = LoadState.failed(ApiFailure.from(e));
    }
    if (!canSwitchRole) {
      _role = AppRole.client; // profile no longer active, or unknown
    } else if (!_preferredApplied) {
      _role = preferredRole;
    }
    if (account.hasData) _preferredApplied = true;
    _notify();
  }

  void selectRole(AppRole r) {
    if (r == _role) return;
    if (r == AppRole.provider && !canSwitchRole) return;
    _role = r;
    _notify();
  }

  void selectTab(int index) {
    if (_tab[_role] == index) return;
    _tab[_role] = index;
    _notify();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}

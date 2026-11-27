import 'package:flutter/material.dart';

import '../app_dependencies.dart';
import '../features/account/presentation/client_account_page.dart';
import '../features/catalog/presentation/offer_detail_page.dart';
import '../features/catalog/presentation/search_results_page.dart';
import '../features/provider/presentation/dashboard_page.dart';
import '../features/provider/presentation/profile_page.dart';
import 'app_role.dart';

/// What a page needs from the shell.
class ShellContext {
  const ShellContext({
    required this.deps,
    required this.countryCode,
    required this.goToTab,
    this.reloadAccount,
  });

  final AppDependencies deps;
  final String countryCode;

  /// Selects another tab of the current role by its [NavDestination.id].
  final void Function(String id) goToTab;

  /// Reloads the account (EP-009) after something changed it, e.g. the
  /// provider capacity was turned on. Null in tests that do not need it.
  final VoidCallback? reloadAccount;
}

typedef PageBuilder = Widget Function(BuildContext context, ShellContext shell);

/// One entry of a role's menu.
///
/// HOW TO ADD A PAGE: add (or complete) an entry in [_client] or [_provider]
/// below and give it a [builder]. An entry without builder shows the
/// "Bientôt disponible" placeholder, so the menu can be laid out ahead of the
/// screens. Labels live in `assets/i18n/fr.json` (`nav.*`).
class NavDestination {
  const NavDestination({
    required this.id,
    required this.icon,
    required this.selectedIcon,
    required this.labelKey,
    this.builder,
  });

  final String id;
  final IconData icon;
  final IconData selectedIcon;
  final String labelKey;
  final PageBuilder? builder;
}

List<NavDestination> destinationsFor(AppRole role) =>
    role == AppRole.client ? _client : _provider;

// ---------------------------------------------------------------- client
// Menu of the client mockups: Accueil, Demandes, Commandes, Compte.
final List<NavDestination> _client = [
  NavDestination(
    id: 'home',
    icon: Icons.home_outlined,
    selectedIcon: Icons.home,
    labelKey: 'nav.home',
    // Temporary: the search screen stands in until the client home is built.
    builder: (context, shell) => SearchResultsPage(
      repository: shell.deps.catalog,
      countryCode: shell.countryCode,
      onOpenOffer: (item) => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => OfferDetailPage(
            repository: shell.deps.catalog,
            offerId: item.offer.id,
          ),
        ),
      ),
    ),
  ),
  const NavDestination(
    id: 'requests',
    icon: Icons.assignment_outlined,
    selectedIcon: Icons.assignment,
    labelKey: 'nav.requests',
  ),
  const NavDestination(
    id: 'orders',
    icon: Icons.shopping_cart_outlined,
    selectedIcon: Icons.shopping_cart,
    labelKey: 'nav.orders',
  ),
  NavDestination(
    id: 'account',
    icon: Icons.person_outline,
    selectedIcon: Icons.person,
    labelKey: 'nav.account',
    builder: (context, shell) => ClientAccountPage(
      account: shell.deps.account,
      provider: shell.deps.provider,
      catalog: shell.deps.catalog,
      countryCode: shell.countryCode,
      onProviderActivated: shell.reloadAccount,
    ),
  ),
];

// -------------------------------------------------------------- provider
// Menu of the provider mockups: Accueil, Mes offres, Demandes, Commandes, Compte.
final List<NavDestination> _provider = [
  NavDestination(
    id: 'home',
    icon: Icons.home_outlined,
    selectedIcon: Icons.home,
    labelKey: 'nav.home',
    builder: (context, shell) => ProviderDashboardPage(
      provider: shell.deps.provider,
      account: shell.deps.account,
      orders: shell.deps.orders,
      requests: shell.deps.requests,
      notifications: shell.deps.notifications,
      onOpenOrders: () => shell.goToTab('orders'),
      onOpenProfile: () => shell.goToTab('account'),
    ),
  ),
  const NavDestination(
    id: 'offers',
    icon: Icons.inventory_2_outlined,
    selectedIcon: Icons.inventory_2,
    labelKey: 'nav.offers',
  ),
  const NavDestination(
    id: 'requests',
    icon: Icons.search,
    selectedIcon: Icons.search,
    labelKey: 'nav.requests',
  ),
  const NavDestination(
    id: 'orders',
    icon: Icons.assignment_outlined,
    selectedIcon: Icons.assignment,
    labelKey: 'nav.orders',
  ),
  NavDestination(
    id: 'account',
    icon: Icons.person_outline,
    selectedIcon: Icons.person,
    labelKey: 'nav.account',
    // The "Compte" tab of the provider mockup shows the professional profile.
    builder: (context, shell) => ProviderProfilePage(
      provider: shell.deps.provider,
      account: shell.deps.account,
      catalog: shell.deps.catalog,
      countryCode: shell.countryCode,
    ),
  ),
];

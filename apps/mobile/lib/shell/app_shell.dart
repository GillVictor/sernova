import 'package:flutter/material.dart';

import '../app_dependencies.dart';
import '../core/l10n/strings.dart';
import '../core/theme/app_colors.dart';
import 'app_role.dart';
import 'destinations.dart';
import 'shell_controller.dart';
import 'widgets/coming_soon_page.dart';
import 'widgets/role_switcher.dart';

/// Where the menu is drawn. The right rail is the current choice; the bottom
/// bar is ready for when the layout changes.
enum NavPlacement { rightRail, bottomBar }

/// Navigation shell: role switch on top of the menu (only for an account whose
/// provider profile is active), then the pages of the current role.
/// Pages are built when first visited and then kept alive.
class AppShell extends StatefulWidget {
  const AppShell({
    super.key,
    required this.deps,
    this.countryCode = 'CG',
    this.preferredRole = AppRole.client,
    this.placement = NavPlacement.rightRail,
  });

  final AppDependencies deps;
  final String countryCode;
  final AppRole preferredRole;
  final NavPlacement placement;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  late final ShellController _c = ShellController(
    account: widget.deps.account,
    preferredRole: widget.preferredRole,
  );
  final Set<String> _visited = {};

  @override
  void initState() {
    super.initState();
    _c.load();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  void _goToTab(String id) {
    final index = destinationsFor(_c.role).indexWhere((d) => d.id == id);
    if (index >= 0) _c.selectTab(index);
  }

  String _key(AppRole role, NavDestination d) => '${role.name}:${d.id}';

  Widget _stack(AppRole role) {
    final dests = destinationsFor(role);
    final index = _c.tabIndex(role).clamp(0, dests.length - 1);
    if (role == _c.role) _visited.add(_key(role, dests[index]));
    final shell = ShellContext(
      deps: widget.deps,
      countryCode: widget.countryCode,
      goToTab: _goToTab,
    );
    return IndexedStack(
      index: index,
      children: [
        for (final d in dests)
          _visited.contains(_key(role, d))
              ? Builder(
                  builder: (ctx) =>
                      d.builder?.call(ctx, shell) ??
                      ComingSoonPage(title: Strings.t(d.labelKey)),
                )
              : const SizedBox.shrink(),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _c,
      builder: (context, _) {
        final role = _c.role;
        final dests = destinationsFor(role);
        final index = _c.currentTab.clamp(0, dests.length - 1);
        // Without an active provider profile, drop every provider page (and its
        // data) rather than keeping it offstage.
        if (!_c.canSwitchRole) {
          _visited.removeWhere((k) => k.startsWith('${AppRole.provider.name}:'));
        }
        final providerBuilt = _visited.any((k) => k.startsWith('${AppRole.provider.name}:')) ||
            (role == AppRole.provider && _c.canSwitchRole);

        final pages = IndexedStack(
          index: role.index,
          children: [
            _stack(AppRole.client),
            providerBuilt ? _stack(AppRole.provider) : const SizedBox.shrink(),
          ],
        );

        final switcher = _c.canSwitchRole
            ? RoleSwitcher(
                role: role,
                onChanged: _c.selectRole,
                axis: widget.placement == NavPlacement.rightRail ? Axis.vertical : Axis.horizontal,
              )
            : null;

        if (widget.placement == NavPlacement.bottomBar) {
          return Scaffold(
            body: Column(children: [
              if (switcher != null)
                SafeArea(
                  bottom: false,
                  child: Padding(padding: const EdgeInsets.all(8), child: switcher),
                ),
              Expanded(child: pages),
            ]),
            bottomNavigationBar: NavigationBar(
              selectedIndex: index,
              onDestinationSelected: _c.selectTab,
              destinations: [
                for (final d in dests)
                  NavigationDestination(
                    icon: Icon(d.icon),
                    selectedIcon: Icon(d.selectedIcon),
                    label: Strings.t(d.labelKey),
                  ),
              ],
            ),
          );
        }

        return Scaffold(
          body: Row(children: [
            Expanded(child: pages),
            const VerticalDivider(width: 1, color: AppColors.border),
            Semantics(
              label: Strings.t('shell.menu'),
              child: SafeArea(
                left: false,
                // Scrolls on short screens instead of overflowing.
                child: LayoutBuilder(
                  builder: (context, constraints) => SingleChildScrollView(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minHeight: constraints.maxHeight),
                      child: IntrinsicHeight(
                        child: NavigationRail(
                          backgroundColor: AppColors.surface,
                          minWidth: 76,
                          labelType: NavigationRailLabelType.all,
                          selectedIndex: index,
                          onDestinationSelected: _c.selectTab,
                          leading: switcher == null
                              ? null
                              : Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: switcher,
                                ),
                          destinations: [
                            for (final d in dests)
                              NavigationRailDestination(
                                icon: Icon(d.icon),
                                selectedIcon: Icon(d.selectedIcon),
                                label: Text(Strings.t(d.labelKey)),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ]),
        );
      },
    );
  }
}

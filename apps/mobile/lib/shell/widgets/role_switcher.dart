import 'package:flutter/material.dart';

import '../../core/l10n/strings.dart';
import '../../core/theme/app_colors.dart';
import '../app_role.dart';

/// The two role buttons (Client / Prestataire). The caller shows this widget
/// only when the account may switch.
class RoleSwitcher extends StatelessWidget {
  const RoleSwitcher({
    super.key,
    required this.role,
    required this.onChanged,
    this.axis = Axis.vertical,
  });

  final AppRole role;
  final ValueChanged<AppRole> onChanged;
  final Axis axis;

  @override
  Widget build(BuildContext context) {
    final buttons = [
      _RoleButton(
        label: Strings.t('shell.role.client'),
        icon: Icons.person_outline,
        selected: role == AppRole.client,
        onTap: () => onChanged(AppRole.client),
      ),
      _RoleButton(
        label: Strings.t('shell.role.provider'),
        icon: Icons.storefront_outlined,
        selected: role == AppRole.provider,
        onTap: () => onChanged(AppRole.provider),
      ),
    ];
    return Flex(
      direction: axis,
      mainAxisSize: MainAxisSize.min,
      children: [
        buttons[0],
        SizedBox(width: axis == Axis.horizontal ? 8 : 0, height: axis == Axis.vertical ? 8 : 0),
        buttons[1],
      ],
    );
  }
}

class _RoleButton extends StatelessWidget {
  const _RoleButton({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fg = selected ? Colors.white : AppColors.primary;
    return Tooltip(
      message: Strings.t('shell.role.switchTo', params: {'role': label}),
      child: Semantics(
        button: true,
        selected: selected,
        label: label,
        child: Material(
          color: selected ? AppColors.primary : AppColors.tint,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: selected ? null : onTap,
            child: SizedBox(
              width: 68,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Icon(icon, size: 24, color: fg),
                  const SizedBox(height: 4),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(label,
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: fg, fontWeight: FontWeight.w700)),
                  ),
                ]),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

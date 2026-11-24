import 'package:flutter/material.dart';

import '../../../../core/l10n/strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/brand_logo.dart';

/// App bar of the provider space: logo, name, "Espace Prestataire", optional
/// bell with unread dot and initials avatar. A control is hidden when its
/// action is null (no dead buttons).
class ProviderHeader extends StatelessWidget {
  const ProviderHeader({
    super.key,
    required this.initials,
    this.unread = 0,
    this.onBell,
    this.onAvatar,
  });

  final String initials;
  final int unread;
  final VoidCallback? onBell;
  final VoidCallback? onAvatar;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Row(children: [
        const BrandLogo(size: 44, color: AppColors.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(Strings.t('app.name'),
                style: t.titleLarge?.copyWith(fontWeight: FontWeight.w800, color: AppColors.navy)),
            Text(Strings.t('provider.space'),
                style: t.bodyMedium?.copyWith(color: AppColors.primary)),
          ]),
        ),
        if (onBell != null)
          IconButton(
            tooltip: Strings.t('provider.bell', params: {'n': unread}),
            onPressed: onBell,
            icon: Badge(
              isLabelVisible: unread > 0,
              smallSize: 10,
              backgroundColor: AppColors.danger,
              child: const Icon(Icons.notifications_none, size: 28, color: AppColors.primary),
            ),
          ),
        const SizedBox(width: 4),
        Tooltip(
          message: Strings.t('provider.avatar'),
          child: InkResponse(
            onTap: onAvatar,
            child: CircleAvatar(
              radius: 24,
              backgroundColor: AppColors.tint,
              child: Text(initials,
                  style: t.titleMedium
                      ?.copyWith(color: AppColors.primary, fontWeight: FontWeight.w800)),
            ),
          ),
        ),
      ]),
    );
  }
}

/// "Jean M. · Prestataire" pill.
class RoleChip extends StatelessWidget {
  const RoleChip({super.key, this.displayName});
  final String? displayName;

  @override
  Widget build(BuildContext context) {
    final label = (displayName == null || displayName!.isEmpty)
        ? Strings.t('provider.roleChipNoName')
        : Strings.t('provider.roleChip', params: {'name': displayName!});
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.iconBubble,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.circle, size: 10, color: AppColors.success),
        const SizedBox(width: 8),
        Flexible(
          child: Text(label,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(fontWeight: FontWeight.w600, color: AppColors.navy)),
        ),
      ]),
    );
  }
}

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// Pill with a chevron (mockup filters). Long press shows [help]; the picker
/// opened by [onTap] repeats it next to its title.
class FilterChipButton extends StatelessWidget {
  const FilterChipButton({
    super.key,
    required this.label,
    required this.help,
    required this.onTap,
    this.active = false,
  });

  final String label;
  final String help;
  final VoidCallback onTap;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Tooltip(
      message: help,
      child: Material(
        color: active ? AppColors.tint : AppColors.surface,
        shape: StadiumBorder(
          side: BorderSide(color: active ? AppColors.primary : AppColors.border),
        ),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 170),
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: t.titleSmall?.copyWith(
                    color: active ? AppColors.primary : AppColors.ink,
                    fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.keyboard_arrow_down,
                  size: 20, color: active ? AppColors.primary : AppColors.muted),
            ]),
          ),
        ),
      ),
    );
  }
}

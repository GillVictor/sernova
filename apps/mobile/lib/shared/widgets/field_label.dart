import 'package:flutter/material.dart';

import '../../core/l10n/strings.dart';
import '../../core/theme/app_colors.dart';
import 'help_tooltip.dart';

/// Label above an input, with "(facultatif)" and the mandatory help tooltip.
class FieldLabel extends StatelessWidget {
  const FieldLabel({super.key, required this.label, required this.help, this.optional = false});
  final String label;
  final String help;
  final bool optional;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Row(children: [
      Flexible(
        child: Text.rich(TextSpan(children: [
          TextSpan(text: label, style: t.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
          if (optional)
            TextSpan(
              text: ' ${Strings.t('provider.profile.optional')}',
              style: t.titleSmall?.copyWith(color: AppColors.muted),
            ),
        ])),
      ),
      HelpTooltip(help),
    ]);
  }
}

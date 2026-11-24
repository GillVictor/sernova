import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

/// "i" icon showing a help message on tap. Mandatory next to every input.
class HelpTooltip extends StatelessWidget {
  const HelpTooltip(this.message, {super.key});
  final String message;

  @override
  Widget build(BuildContext context) => Tooltip(
        message: message,
        triggerMode: TooltipTriggerMode.tap,
        showDuration: const Duration(seconds: 6),
        child: const Padding(
          padding: EdgeInsets.all(8),
          child: Icon(Icons.info_outline, size: 20, color: AppColors.muted),
        ),
      );
}

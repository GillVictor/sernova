import 'package:flutter/material.dart';
import 'help_tooltip.dart';

/// Title row (with help tooltip) + scrollable content for bottom sheets.
class SheetFrame extends StatelessWidget {
  const SheetFrame({super.key, required this.title, required this.help, required this.child});
  final String title;
  final String help;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.sizeOf(context).height * 0.75;
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 8, 8),
            child: Row(children: [
              Expanded(
                child: Text(title,
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontWeight: FontWeight.w800)),
              ),
              HelpTooltip(help),
            ]),
          ),
          Flexible(child: child),
        ]),
      ),
    );
  }
}

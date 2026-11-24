import 'package:flutter/material.dart';

import '../../../../core/l10n/strings.dart';

/// Text clamped to [maxLines] with "Voir plus" / "Voir moins" when it overflows.
class ExpandableText extends StatefulWidget {
  const ExpandableText(this.text, {super.key, this.maxLines = 4, this.style});
  final String text;
  final int maxLines;
  final TextStyle? style;

  @override
  State<ExpandableText> createState() => _ExpandableTextState();
}

class _ExpandableTextState extends State<ExpandableText> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final style = widget.style ?? DefaultTextStyle.of(context).style;
    return LayoutBuilder(builder: (context, constraints) {
      final painter = TextPainter(
        text: TextSpan(text: widget.text, style: style),
        maxLines: widget.maxLines,
        textDirection: Directionality.of(context),
      )..layout(maxWidth: constraints.maxWidth);
      final overflows = painter.didExceedMaxLines;

      return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(
          widget.text,
          style: style,
          maxLines: _expanded ? null : widget.maxLines,
          overflow: _expanded ? TextOverflow.visible : TextOverflow.ellipsis,
        ),
        if (overflows)
          TextButton(
            style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(0, 36)),
            onPressed: () => setState(() => _expanded = !_expanded),
            child: Text(Strings.t(_expanded ? 'detail.readLess' : 'detail.readMore')),
          ),
      ]);
    });
  }
}

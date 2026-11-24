import 'package:flutter/material.dart';

import '../../../../core/l10n/strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/help_tooltip.dart';

/// Search bar: icon, text, clear button, help tooltip (mandatory on inputs).
class SearchField extends StatefulWidget {
  const SearchField({
    super.key,
    required this.initialText,
    required this.onChanged,
    required this.onSubmitted,
  });

  final String initialText;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onSubmitted;

  @override
  State<SearchField> createState() => _SearchFieldState();
}

class _SearchFieldState extends State<SearchField> {
  late final TextEditingController _c = TextEditingController(text: widget.initialText);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(color: Color(0x120A2A66), blurRadius: 12, offset: Offset(0, 3)),
        ],
      ),
      padding: const EdgeInsets.only(left: 16),
      child: Row(children: [
        const Icon(Icons.search, color: AppColors.muted, size: 28),
        const SizedBox(width: 12),
        Expanded(
          child: TextField(
            controller: _c,
            textInputAction: TextInputAction.search,
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w700),
            decoration: InputDecoration(
              hintText: Strings.t('search.fields.query.placeholder'),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              filled: false,
              contentPadding: const EdgeInsets.symmetric(vertical: 20),
            ),
            onChanged: (v) {
              setState(() {});
              widget.onChanged(v);
            },
            onSubmitted: widget.onSubmitted,
          ),
        ),
        if (_c.text.isNotEmpty)
          IconButton(
            tooltip: Strings.t('search.fields.query.clear'),
            icon: const Icon(Icons.close, color: AppColors.muted),
            onPressed: () {
              _c.clear();
              setState(() {});
              widget.onSubmitted('');
            },
          ),
        HelpTooltip(Strings.t('search.fields.query.help')),
        const SizedBox(width: 4),
      ]),
    );
  }
}

import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/l10n/strings.dart';
import '../../core/theme/app_colors.dart';
import '../../features/catalog/domain/offer_models.dart';
import 'help_tooltip.dart';
import 'sheet_frame.dart';
import 'sheet_result.dart';

/// Location picker with assisted entry (EP-023). Pops a
/// `SheetResult<LocationSuggestion>`. When [allLabel] is set, a first row
/// clears the choice (`SheetResult(null)`).
class LocationPickerSheet extends StatefulWidget {
  const LocationPickerSheet({
    super.key,
    required this.title,
    required this.help,
    required this.searchHelp,
    required this.placeholder,
    required this.emptyLabel,
    required this.search,
    this.selectedId,
    this.allLabel,
  });

  final String title;
  final String help;
  final String searchHelp;
  final String placeholder;
  final String emptyLabel;
  final String? allLabel;
  final String? selectedId;
  final Future<List<LocationSuggestion>> Function(String? q) search;

  @override
  State<LocationPickerSheet> createState() => _LocationPickerSheetState();
}

class _LocationPickerSheetState extends State<LocationPickerSheet> {
  final _text = TextEditingController();
  Timer? _timer;
  late Future<List<LocationSuggestion>> _future = widget.search(null);

  void _onChanged(String v) {
    _timer?.cancel();
    _timer = Timer(const Duration(milliseconds: 300), () {
      if (mounted) setState(() => _future = widget.search(v));
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _text.dispose();
    super.dispose();
  }

  Widget get _spinner => const Padding(
        padding: EdgeInsets.all(32),
        child: Center(child: CircularProgressIndicator()),
      );

  @override
  Widget build(BuildContext context) {
    final selectedId = widget.selectedId;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SheetFrame(
        title: widget.title,
        help: widget.help,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 8, 8),
            child: TextField(
              controller: _text,
              onChanged: _onChanged,
              decoration: InputDecoration(
                hintText: widget.placeholder,
                prefixIcon: const Icon(Icons.search),
                suffixIcon: HelpTooltip(widget.searchHelp),
              ),
            ),
          ),
          Flexible(
            child: FutureBuilder<List<LocationSuggestion>>(
              future: _future,
              builder: (context, snap) {
                if (snap.hasError) {
                  return Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      Text(Strings.error('NETWORK'), textAlign: TextAlign.center),
                      const SizedBox(height: 12),
                      OutlinedButton(
                        onPressed: () => setState(() => _future = widget.search(_text.text)),
                        child: Text(Strings.t('common.retry')),
                      ),
                    ]),
                  );
                }
                if (!snap.hasData) return _spinner;
                final list = snap.data!;
                return ListView(shrinkWrap: true, children: [
                  if (widget.allLabel != null)
                    ListTile(
                      title: Text(widget.allLabel!),
                      trailing: selectedId == null
                          ? const Icon(Icons.check, color: AppColors.primary)
                          : null,
                      onTap: () =>
                          Navigator.pop(context, const SheetResult<LocationSuggestion>(null)),
                    ),
                  if (list.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(widget.emptyLabel,
                          style: const TextStyle(color: AppColors.muted)),
                    ),
                  for (final l in list)
                    ListTile(
                      leading: const Icon(Icons.place_outlined),
                      title: Text(l.label),
                      trailing: l.id == selectedId
                          ? const Icon(Icons.check, color: AppColors.primary)
                          : null,
                      onTap: () => Navigator.pop(context, SheetResult<LocationSuggestion>(l)),
                    ),
                ]);
              },
            ),
          ),
        ]),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../../../../core/l10n/strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/sheet_frame.dart';
import '../../../../shared/widgets/sheet_result.dart';
import '../../domain/enums.dart';
import '../../domain/offer_models.dart';
import '../offer_search_controller.dart';

Widget _error(BuildContext context, VoidCallback retry) => Padding(
      padding: const EdgeInsets.all(24),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Text(Strings.error('NETWORK'), textAlign: TextAlign.center),
        const SizedBox(height: 12),
        OutlinedButton(onPressed: retry, child: Text(Strings.t('common.retry'))),
      ]),
    );

/// Category picker (EP-021 tree, indented).
class CategorySheet extends StatefulWidget {
  const CategorySheet({super.key, required this.controller});
  final OfferSearchController controller;

  @override
  State<CategorySheet> createState() => _CategorySheetState();
}

class _CategorySheetState extends State<CategorySheet> {
  late Future<List<CategoryNode>> _future = widget.controller.loadCategories();

  @override
  Widget build(BuildContext context) {
    final selectedId = widget.controller.category?.id;
    return SheetFrame(
      title: Strings.t('search.fields.category.sheetTitle'),
      help: Strings.t('search.fields.category.help'),
      child: FutureBuilder<List<CategoryNode>>(
        future: _future,
        builder: (context, snap) {
          if (snap.hasError) {
            return _error(context, () => setState(() {
                  _future = widget.controller.loadCategories();
                }));
          }
          if (!snap.hasData) {
            return const Padding(
              padding: EdgeInsets.all(32),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          final rows = CategoryNode.flatten(snap.data!);
          return ListView(shrinkWrap: true, children: [
            ListTile(
              title: Text(Strings.t('search.fields.category.all')),
              trailing: selectedId == null
                  ? const Icon(Icons.check, color: AppColors.primary)
                  : null,
              onTap: () => Navigator.pop(context, const SheetResult<CategoryNode>(null)),
            ),
            for (final (node, depth) in rows)
              ListTile(
                contentPadding: EdgeInsets.only(left: 16.0 + depth * 20, right: 16),
                title: Text(node.name,
                    style: TextStyle(
                        fontWeight: depth == 0 ? FontWeight.w700 : FontWeight.w400)),
                trailing: node.id == selectedId
                    ? const Icon(Icons.check, color: AppColors.primary)
                    : null,
                onTap: () => Navigator.pop(context, SheetResult<CategoryNode>(node)),
              ),
          ]);
        },
      ),
    );
  }
}

String sortLabel(OfferSort? s) => switch (s) {
      null => Strings.t('search.fields.sort.relevance'),
      OfferSort.rating => Strings.t('search.fields.sort.rating'),
      OfferSort.price => Strings.t('search.fields.sort.price'),
      OfferSort.distance => Strings.t('search.fields.sort.distance'),
    };

/// Sort picker (EP-035 `sort`: distance, rating, price). Distance needs a
/// location, so it is disabled until one is chosen.
class SortSheet extends StatelessWidget {
  const SortSheet({super.key, required this.current, required this.hasLocation});
  final OfferSort? current;
  final bool hasLocation;

  @override
  Widget build(BuildContext context) {
    Widget tile(OfferSort? s, {bool enabled = true, String? subtitle}) => ListTile(
          enabled: enabled,
          title: Text(sortLabel(s)),
          subtitle: subtitle == null ? null : Text(subtitle),
          trailing: s == current ? const Icon(Icons.check, color: AppColors.primary) : null,
          onTap: enabled ? () => Navigator.pop(context, SheetResult<OfferSort>(s)) : null,
        );

    return SheetFrame(
      title: Strings.t('search.fields.sort.sheetTitle'),
      help: Strings.t('search.fields.sort.help'),
      child: ListView(shrinkWrap: true, children: [
        tile(null),
        tile(OfferSort.rating),
        tile(OfferSort.price),
        tile(
          OfferSort.distance,
          enabled: hasLocation,
          subtitle: hasLocation ? null : Strings.t('search.fields.sort.distanceNeedsLocation'),
        ),
      ]),
    );
  }
}

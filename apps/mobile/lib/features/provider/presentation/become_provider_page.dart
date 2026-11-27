import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/l10n/strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/field_label.dart';
import '../../../shared/widgets/location_picker_sheet.dart';
import '../../../shared/widgets/sheet_frame.dart';
import '../../../shared/widgets/sheet_result.dart';
import '../../catalog/data/catalog_repository.dart';
import '../../catalog/domain/offer_models.dart';
import '../data/provider_repository.dart';
import '../domain/provider_activation.dart';
import 'become_provider_controller.dart';

/// "Devenir prestataire" (UC01, EP-011): business name, main location,
/// coverage and 1 to 5 domains. Calls [onActivated] once the server accepted.
class BecomeProviderPage extends StatefulWidget {
  const BecomeProviderPage({
    super.key,
    required this.provider,
    required this.catalog,
    this.countryCode = 'CG',
    this.onActivated,
  });

  final ProviderRepository provider;
  final CatalogRepository catalog;
  final String countryCode;
  final VoidCallback? onActivated;

  @override
  State<BecomeProviderPage> createState() => _BecomeProviderPageState();
}

class _BecomeProviderPageState extends State<BecomeProviderPage> {
  static const maxCategories = 5;

  late final BecomeProviderController _c = BecomeProviderController(widget.provider);
  final _name = TextEditingController();
  final _radius = TextEditingController();
  LocationSuggestion? _location;
  CoverageMode _coverage = CoverageMode.city; // dictionary default
  List<CategoryNode> _picked = const [];
  bool _submitted = false;

  @override
  void dispose() {
    _c.dispose();
    _name.dispose();
    _radius.dispose();
    super.dispose();
  }

  String _v(String key) => Strings.t('provider.become.validation.$key');

  String? get _nameIssue => _name.text.trim().isEmpty ? _v('nameRequired') : null;
  String? get _locationIssue => _location == null ? _v('locationRequired') : null;
  String? get _categoriesIssue => _picked.isEmpty ? _v('categoriesRequired') : null;

  int? get _radiusValue => int.tryParse(_radius.text.trim());
  String? get _radiusIssue {
    if (_coverage != CoverageMode.radius) return null;
    final r = _radiusValue;
    return (r == null || r < 1 || r > 500) ? _v('radiusRange') : null;
  }

  bool get _hasLocalIssue =>
      _nameIssue != null || _locationIssue != null || _categoriesIssue != null || _radiusIssue != null;

  String? _serverIssue(String field) {
    final rejected = _c.failure?.fieldErrors.any((e) => e.field.toLowerCase() == field.toLowerCase()) ?? false;
    return rejected ? _v('fieldRejected') : null;
  }

  String? _issue(String? local, String field) => _submitted ? (local ?? _serverIssue(field)) : null;

  Future<void> _pickLocation() async {
    final r = await showModalBottomSheet<SheetResult<LocationSuggestion>>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => LocationPickerSheet(
        title: Strings.t('provider.profile.fields.location.sheetTitle'),
        help: Strings.t('provider.profile.fields.location.help'),
        searchHelp: Strings.t('provider.profile.fields.location.searchHelp'),
        placeholder: Strings.t('provider.profile.fields.location.placeholder'),
        emptyLabel: Strings.t('provider.profile.fields.location.empty'),
        selectedId: _location?.id,
        search: (q) => widget.catalog.searchLocations(countryCode: widget.countryCode, q: q),
      ),
    );
    final picked = r?.value;
    if (picked != null) setState(() => _location = picked);
  }

  Future<void> _pickCategories() async {
    final r = await showModalBottomSheet<List<CategoryNode>>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _CategoriesSheet(
        catalog: widget.catalog,
        initial: _picked,
        max: maxCategories,
      ),
    );
    if (r != null) setState(() => _picked = r);
  }

  Future<void> _submit() async {
    setState(() => _submitted = true);
    if (_hasLocalIssue) return;
    final ok = await _c.activate(ProviderActivation(
      businessName: _name.text,
      workLocationId: _location!.id,
      coverageMode: _coverage,
      radiusKm: _coverage == CoverageMode.radius ? _radiusValue : null,
      categoryIds: [for (final n in _picked) n.id],
    ));
    if (!ok || !mounted) return;
    widget.onActivated?.call();
    Navigator.of(context).pop(true);
  }

  Widget _tile({
    required Key key,
    required String text,
    required bool empty,
    required VoidCallback? onTap,
    String? error,
  }) =>
      InkWell(
        key: key,
        onTap: onTap,
        child: InputDecorator(
          decoration: InputDecoration(
            errorText: error,
            suffixIcon: const Icon(Icons.arrow_drop_down),
          ),
          child: Text(
            text,
            style: empty ? const TextStyle(color: AppColors.muted) : null,
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: Text(Strings.t('provider.become.title'))),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: ListenableBuilder(
                listenable: _c,
                builder: (context, _) {
                  final failure = _c.failure;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        Strings.t('provider.become.subtitle'),
                        style: t.bodyMedium?.copyWith(color: AppColors.muted),
                      ),
                      const SizedBox(height: 24),
                      FieldLabel(
                        label: Strings.t('provider.become.fields.businessName.label'),
                        help: Strings.t('provider.become.fields.businessName.help'),
                      ),
                      const SizedBox(height: 4),
                      TextField(
                        key: const Key('become-name'),
                        controller: _name,
                        enabled: !_c.busy,
                        textInputAction: TextInputAction.next,
                        textCapitalization: TextCapitalization.sentences,
                        inputFormatters: [LengthLimitingTextInputFormatter(80)],
                        decoration: InputDecoration(
                          hintText: Strings.t('provider.become.fields.businessName.placeholder'),
                          errorText: _issue(_nameIssue, 'businessName'),
                        ),
                      ),
                      const SizedBox(height: 16),
                      FieldLabel(
                        label: Strings.t('provider.become.fields.location.label'),
                        help: Strings.t('provider.become.fields.location.help'),
                      ),
                      const SizedBox(height: 4),
                      _tile(
                        key: const Key('become-location'),
                        text: _location?.label ?? Strings.t('provider.become.fields.location.placeholder'),
                        empty: _location == null,
                        onTap: _c.busy ? null : _pickLocation,
                        error: _issue(_locationIssue, 'workLocationId'),
                      ),
                      const SizedBox(height: 16),
                      FieldLabel(
                        label: Strings.t('provider.become.fields.coverage.label'),
                        help: Strings.t('provider.become.fields.coverage.help'),
                      ),
                      const SizedBox(height: 8),
                      Wrap(spacing: 8, runSpacing: 8, children: [
                        for (final m in CoverageMode.selectable)
                          ChoiceChip(
                            key: Key('coverage-${m.wire}'),
                            label: Text(Strings.t('provider.become.fields.coverage.options.${m.name}')),
                            selected: _coverage == m,
                            onSelected: _c.busy ? null : (_) => setState(() => _coverage = m),
                          ),
                      ]),
                      if (_coverage == CoverageMode.radius) ...[
                        const SizedBox(height: 16),
                        FieldLabel(
                          label: Strings.t('provider.become.fields.radius.label'),
                          help: Strings.t('provider.become.fields.radius.help'),
                        ),
                        const SizedBox(height: 4),
                        TextField(
                          key: const Key('become-radius'),
                          controller: _radius,
                          enabled: !_c.busy,
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          decoration: InputDecoration(
                            hintText: Strings.t('provider.become.fields.radius.placeholder'),
                            errorText: _submitted ? (_radiusIssue ?? _serverIssue('radiusKm')) : null,
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),
                      FieldLabel(
                        label: Strings.t('provider.become.fields.categories.label'),
                        help: Strings.t('provider.become.fields.categories.help'),
                      ),
                      const SizedBox(height: 4),
                      _tile(
                        key: const Key('become-categories'),
                        text: _picked.isEmpty
                            ? Strings.t('provider.become.fields.categories.placeholder')
                            : _picked.map((n) => n.name).join(', '),
                        empty: _picked.isEmpty,
                        onTap: _c.busy ? null : _pickCategories,
                        error: _issue(_categoriesIssue, 'categoryIds'),
                      ),
                      if (failure != null) ...[
                        const SizedBox(height: 16),
                        Semantics(
                          liveRegion: true,
                          child: Text(
                            Strings.error(failure.code, retryAfterSeconds: failure.retryAfterSeconds),
                            style: t.bodyMedium?.copyWith(color: AppColors.danger),
                          ),
                        ),
                      ],
                      const SizedBox(height: 24),
                      FilledButton(
                        key: const Key('become-submit'),
                        onPressed: _c.busy ? null : _submit,
                        child: _c.busy
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : Text(Strings.t('provider.become.submit')),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Multi-choice list of the category tree (EP-021), at most [max] choices.
class _CategoriesSheet extends StatefulWidget {
  const _CategoriesSheet({required this.catalog, required this.initial, required this.max});

  final CatalogRepository catalog;
  final List<CategoryNode> initial;
  final int max;

  @override
  State<_CategoriesSheet> createState() => _CategoriesSheetState();
}

class _CategoriesSheetState extends State<_CategoriesSheet> {
  late Future<List<CategoryNode>> _future = widget.catalog.fetchCategories();
  late final Map<String, CategoryNode> _chosen = {for (final n in widget.initial) n.id: n};

  @override
  Widget build(BuildContext context) => SheetFrame(
        title: Strings.t('provider.become.fields.categories.sheetTitle'),
        help: Strings.t('provider.become.fields.categories.help'),
        child: FutureBuilder<List<CategoryNode>>(
          future: _future,
          builder: (context, snap) {
            if (snap.hasError) {
              return Padding(
                padding: const EdgeInsets.all(24),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Text(Strings.error('NETWORK'), textAlign: TextAlign.center),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: () => setState(() => _future = widget.catalog.fetchCategories()),
                    child: Text(Strings.t('common.retry')),
                  ),
                ]),
              );
            }
            if (!snap.hasData) {
              return const Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: CircularProgressIndicator()),
              );
            }
            final rows = CategoryNode.flatten(snap.data!);
            final full = _chosen.length >= widget.max;
            return Column(mainAxisSize: MainAxisSize.min, children: [
              Flexible(
                child: ListView(shrinkWrap: true, children: [
                  for (final (node, depth) in rows)
                    CheckboxListTile(
                      key: Key('category-${node.id}'),
                      contentPadding: EdgeInsets.only(left: 16.0 + 20 * depth, right: 16),
                      title: Text(node.name),
                      value: _chosen.containsKey(node.id),
                      onChanged: (!_chosen.containsKey(node.id) && full)
                          ? null
                          : (v) => setState(() {
                                if (v == true) {
                                  _chosen[node.id] = node;
                                } else {
                                  _chosen.remove(node.id);
                                }
                              }),
                    ),
                ]),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: FilledButton(
                  key: const Key('categories-done'),
                  onPressed: () => Navigator.pop(context, _chosen.values.toList()),
                  child: Text(Strings.t('provider.become.fields.categories.done')),
                ),
              ),
            ]);
          },
        ),
      );
}

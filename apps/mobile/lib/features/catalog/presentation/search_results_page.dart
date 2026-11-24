import 'package:flutter/material.dart';

import '../../../core/l10n/strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/brand_logo.dart';
import '../../../shared/widgets/location_picker_sheet.dart';
import '../../../shared/widgets/sheet_result.dart';
import '../data/catalog_repository.dart';
import '../domain/enums.dart';
import '../domain/offer_models.dart';
import 'offer_search_controller.dart';
import 'widgets/filter_chip_button.dart';
import 'widgets/filter_sheets.dart';
import 'widgets/offer_card.dart';
import 'widgets/search_field.dart';

/// Search results (use case UC04, EP-035). Public: no sign-in needed.
class SearchResultsPage extends StatefulWidget {
  const SearchResultsPage({
    super.key,
    required this.repository,
    this.initialQuery = '',
    this.countryCode = 'CG',
    this.debounce = const Duration(milliseconds: 400),
    this.onOpenOffer,
    this.onPublishNeed,
    this.onOpenMap,
  });

  final CatalogRepository repository;
  final String initialQuery;
  final String countryCode;
  final Duration debounce;

  /// Detail screen (EP-037), next task.
  final void Function(OfferSearchItem item)? onOpenOffer;

  /// "Publier un besoin" (voie B) shown on the empty state.
  final VoidCallback? onPublishNeed;

  /// Map (EP-036). The "Voir la carte" button is hidden while this is null.
  final VoidCallback? onOpenMap;

  @override
  State<SearchResultsPage> createState() => _SearchResultsPageState();
}

class _SearchResultsPageState extends State<SearchResultsPage> {
  late final OfferSearchController _controller = OfferSearchController(
    repository: widget.repository,
    debounce: widget.debounce,
    initialQuery: widget.initialQuery,
  );
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_maybeLoadMore);
    _controller.refresh();
  }

  @override
  void dispose() {
    _scroll.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _maybeLoadMore() {
    if (_scroll.hasClients && _scroll.position.extentAfter < 600) {
      _controller.loadMore();
    }
  }

  Future<void> _pickCategory() async {
    final r = await showModalBottomSheet<SheetResult<CategoryNode>>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => CategorySheet(controller: _controller),
    );
    if (r != null) _controller.setCategory(r.value);
  }

  Future<void> _pickLocation() async {
    final r = await showModalBottomSheet<SheetResult<LocationSuggestion>>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => LocationPickerSheet(
        title: Strings.t('search.fields.location.sheetTitle'),
        help: Strings.t('search.fields.location.help'),
        searchHelp: Strings.t('search.fields.location.searchHelp'),
        placeholder: Strings.t('search.fields.location.placeholder'),
        emptyLabel: Strings.t('search.fields.location.empty'),
        allLabel: Strings.t('search.fields.location.all'),
        selectedId: _controller.location?.id,
        search: (q) => _controller.searchLocations(widget.countryCode, q),
      ),
    );
    if (r != null) _controller.setLocation(r.value);
  }

  Future<void> _pickSort() async {
    final r = await showModalBottomSheet<SheetResult<OfferSort>>(
      context: context,
      showDragHandle: true,
      builder: (_) => SortSheet(
        current: _controller.sort,
        hasLocation: _controller.location != null,
      ),
    );
    if (r != null) _controller.setSort(r.value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.headerNavy,
        foregroundColor: Colors.white,
        title: Row(mainAxisSize: MainAxisSize.min, children: [
          const BrandLogo(size: 32),
          const SizedBox(width: 12),
          Text(Strings.t('app.name'),
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 24)),
        ]),
      ),
      floatingActionButton: widget.onOpenMap == null
          ? null
          : FloatingActionButton.extended(
              onPressed: widget.onOpenMap,
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.public),
              label: Text(Strings.t('search.map')),
            ),
      body: ListenableBuilder(
        listenable: _controller,
        builder: (context, _) => Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: SearchField(
              initialText: widget.initialQuery,
              onChanged: _controller.onQueryChanged,
              onSubmitted: _controller.submitQuery,
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(children: [
              FilterChipButton(
                label: _controller.category?.name ?? Strings.t('search.fields.category.label'),
                help: Strings.t('search.fields.category.help'),
                active: _controller.category != null,
                onTap: _pickCategory,
              ),
              const SizedBox(width: 10),
              FilterChipButton(
                label: _controller.location?.label ?? Strings.t('search.fields.location.label'),
                help: Strings.t('search.fields.location.help'),
                active: _controller.location != null,
                onTap: _pickLocation,
              ),
              const SizedBox(width: 10),
              FilterChipButton(
                label: _controller.sort == null
                    ? Strings.t('search.fields.sort.label')
                    : sortLabel(_controller.sort),
                help: Strings.t('search.fields.sort.help'),
                active: _controller.sort != null,
                onTap: _pickSort,
              ),
            ]),
          ),
          const SizedBox(height: 12),
          Expanded(child: _Results(page: widget, controller: _controller, scroll: _scroll)),
        ]),
      ),
    );
  }
}

class _Results extends StatelessWidget {
  const _Results({required this.page, required this.controller, required this.scroll});
  final SearchResultsPage page;
  final OfferSearchController controller;
  final ScrollController scroll;

  @override
  Widget build(BuildContext context) {
    final c = controller;

    if (c.items.isEmpty) {
      switch (c.status) {
        case SearchStatus.idle:
        case SearchStatus.loading:
          return const Center(child: CircularProgressIndicator());
        case SearchStatus.error:
          return _Message(
            icon: Icons.cloud_off,
            title: Strings.t('search.error.title'),
            subtitle: Strings.error(c.failure?.code ?? 'UNKNOWN',
                retryAfterSeconds: c.failure?.retryAfterSeconds),
            actions: [
              FilledButton(onPressed: c.refresh, child: Text(Strings.t('common.retry'))),
            ],
          );
        case SearchStatus.empty:
        case SearchStatus.ready:
          return _Message(
            icon: Icons.search_off,
            title: Strings.t('search.empty.title'),
            subtitle: Strings.t('search.empty.subtitle'),
            actions: [
              if (page.onPublishNeed != null)
                FilledButton(
                  onPressed: page.onPublishNeed,
                  child: Text(Strings.t('search.empty.publishNeed')),
                ),
              if (c.hasActiveFilters)
                TextButton(
                  onPressed: c.clearFilters,
                  child: Text(Strings.t('search.empty.clearFilters')),
                ),
            ],
          );
      }
    }

    final showFooter = c.loadingMore || c.loadMoreFailed;
    return Stack(children: [
      RefreshIndicator(
        onRefresh: c.refresh,
        child: ListView.separated(
          controller: scroll,
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
          itemCount: c.items.length + (showFooter ? 1 : 0),
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, i) {
            if (i >= c.items.length) {
              return c.loadMoreFailed
                  ? Center(
                      child: TextButton(
                        onPressed: c.loadMore,
                        child: Text(
                            '${Strings.t('search.error.loadMore')} ${Strings.t('common.retry')}'),
                      ),
                    )
                  : const Padding(
                      padding: EdgeInsets.all(16),
                      child: Center(child: CircularProgressIndicator()),
                    );
            }
            final item = c.items[i];
            return OfferCard(
              item: item,
              onTap: page.onOpenOffer == null ? null : () => page.onOpenOffer!(item),
            );
          },
        ),
      ),
      if (c.status == SearchStatus.loading)
        const Positioned(top: 0, left: 0, right: 0, child: LinearProgressIndicator()),
    ]);
  }
}

class _Message extends StatelessWidget {
  const _Message({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.actions = const [],
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 56, color: AppColors.muted),
          const SizedBox(height: 16),
          Text(title,
              textAlign: TextAlign.center,
              style: t.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Text(subtitle,
              textAlign: TextAlign.center,
              style: t.bodyMedium?.copyWith(color: AppColors.muted)),
          const SizedBox(height: 20),
          for (final a in actions) ...[a, const SizedBox(height: 8)],
        ]),
      ),
    );
  }
}

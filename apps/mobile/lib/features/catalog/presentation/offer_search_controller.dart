import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../core/api/api_failure.dart';
import '../data/catalog_repository.dart';
import '../domain/enums.dart';
import '../domain/offer_models.dart';
import '../domain/offer_search_query.dart';

enum SearchStatus { idle, loading, ready, empty, error }

typedef SearchFailure = ApiFailure;

/// State of the search screen: text, filters, results and cursor pagination.
/// Out-of-date responses (older generation) are ignored.
class OfferSearchController extends ChangeNotifier {
  OfferSearchController({
    required CatalogRepository repository,
    this.debounce = const Duration(milliseconds: 400),
    this.pageSize = 20,
    String initialQuery = '',
  })  : _repo = repository,
        _queryText = initialQuery.trim();

  final CatalogRepository _repo;
  final Duration debounce;
  final int pageSize;

  String _queryText;
  CategoryNode? _category;
  LocationSuggestion? _location;
  OfferSort? _sort;

  SearchStatus _status = SearchStatus.idle;
  List<OfferSearchItem> _items = const [];
  String? _nextCursor;
  bool _loadingMore = false;
  bool _loadMoreFailed = false;
  SearchFailure? _failure;

  Timer? _timer;
  int _generation = 0;
  bool _disposed = false;
  Future<List<CategoryNode>>? _categories;

  String get queryText => _queryText;
  CategoryNode? get category => _category;
  LocationSuggestion? get location => _location;
  OfferSort? get sort => _sort;
  SearchStatus get status => _status;
  List<OfferSearchItem> get items => _items;
  bool get hasMore => _nextCursor != null;
  bool get loadingMore => _loadingMore;
  bool get loadMoreFailed => _loadMoreFailed;
  SearchFailure? get failure => _failure;
  bool get hasActiveFilters => _category != null || _location != null || _sort != null;

  OfferSearchQuery _query({String? cursor}) => OfferSearchQuery(
        q: _queryText,
        categoryId: _category?.id,
        locationId: _location?.id,
        sort: _sort,
        limit: pageSize,
        cursor: cursor,
      );

  /// Typing: waits [debounce] after the last key before searching.
  void onQueryChanged(String text) {
    final t = text.trim();
    if (t == _queryText) return;
    _queryText = t;
    _timer?.cancel();
    _timer = Timer(debounce, refresh);
  }

  /// Keyboard "search" key or clear button: search now.
  void submitQuery(String text) {
    _timer?.cancel();
    _queryText = text.trim();
    refresh();
  }

  void setCategory(CategoryNode? c) {
    if (_category?.id == c?.id) return;
    _category = c;
    refresh();
  }

  void setLocation(LocationSuggestion? l) {
    if (_location?.id == l?.id) return;
    _location = l;
    // Distance sort needs a location (EP-035: locationId or lat+lng).
    if (l == null && _sort == OfferSort.distance) _sort = null;
    refresh();
  }

  void setSort(OfferSort? s) {
    if (_sort == s) return;
    if (s == OfferSort.distance && _location == null) return;
    _sort = s;
    refresh();
  }

  void clearFilters() {
    _category = null;
    _location = null;
    _sort = null;
    refresh();
  }

  /// First page for the current text and filters.
  Future<void> refresh() async {
    _timer?.cancel();
    final gen = ++_generation;
    _status = SearchStatus.loading;
    _failure = null;
    _loadMoreFailed = false;
    _loadingMore = false;
    _notify();
    try {
      final page = await _repo.searchOffers(_query());
      if (gen != _generation) return;
      _items = page.items;
      _nextCursor = page.nextCursor;
      _status = page.items.isEmpty ? SearchStatus.empty : SearchStatus.ready;
    } catch (e) {
      if (gen != _generation) return;
      _items = const [];
      _nextCursor = null;
      _failure = SearchFailure.from(e);
      _status = SearchStatus.error;
    }
    _notify();
  }

  /// Next page, appended. No-op while loading or when there is no cursor.
  Future<void> loadMore() async {
    final cursor = _nextCursor;
    if (cursor == null || _loadingMore || _status != SearchStatus.ready) return;
    final gen = _generation;
    _loadingMore = true;
    _loadMoreFailed = false;
    _notify();
    try {
      final page = await _repo.searchOffers(_query(cursor: cursor));
      if (gen != _generation) return;
      _items = [..._items, ...page.items];
      _nextCursor = page.nextCursor;
    } catch (_) {
      if (gen != _generation) return;
      _loadMoreFailed = true;
    }
    _loadingMore = false;
    _notify();
  }

  /// Category tree, fetched once and reused by the picker (EP-021 is cached
  /// server-side). A failure is not kept, so the next open retries.
  Future<List<CategoryNode>> loadCategories() {
    final cached = _categories;
    if (cached != null) return cached;
    final f = _repo.fetchCategories();
    _categories = f;
    // Forget a failed request so that the next open retries; the caller still
    // receives the error through [f].
    unawaited(f.then<void>((_) {}, onError: (Object _) {
      if (identical(_categories, f)) _categories = null;
    }));
    return f;
  }

  Future<List<LocationSuggestion>> searchLocations(String countryCode, String? q) =>
      _repo.searchLocations(countryCode: countryCode, q: q);

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _timer?.cancel();
    super.dispose();
  }
}

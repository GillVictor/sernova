import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:servnova_mobile/core/api/api_exception.dart';
import 'package:servnova_mobile/features/catalog/domain/enums.dart';
import 'package:servnova_mobile/features/catalog/domain/offer_models.dart';
import 'package:servnova_mobile/features/catalog/presentation/offer_search_controller.dart';

import '../../support/stub_catalog_repository.dart';

const _tick = Duration(milliseconds: 80);

OfferSearchController make(StubCatalogRepository repo, {Duration? debounce}) =>
    OfferSearchController(
      repository: repo,
      debounce: debounce ?? const Duration(milliseconds: 20),
      pageSize: 2,
    );

void main() {
  test('refresh loads the first page and sets ready / empty', () async {
    final repo = StubCatalogRepository(
      onSearch: (q) async => OfferSearchPage(items: [makeItem('1')], nextCursor: 'c1'),
    );
    final c = make(repo);
    await c.refresh();
    expect(c.status, SearchStatus.ready);
    expect(c.items, hasLength(1));
    expect(c.hasMore, isTrue);
    expect(repo.queries.single.limit, 2);

    repo.onSearch = (q) async => const OfferSearchPage(items: []);
    await c.refresh();
    expect(c.status, SearchStatus.empty);
    c.dispose();
  });

  test('typing is debounced: only the last text is searched', () async {
    final repo = StubCatalogRepository();
    final c = make(repo);
    c.onQueryChanged('p');
    c.onQueryChanged('pl');
    c.onQueryChanged('plomb');
    await Future<void>.delayed(_tick);
    expect(repo.queries, hasLength(1));
    expect(repo.queries.single.q, 'plomb');
    c.dispose();
  });

  test('submitQuery searches immediately and cancels the pending debounce', () async {
    final repo = StubCatalogRepository();
    final c = make(repo, debounce: const Duration(seconds: 5));
    c.onQueryChanged('abc');
    c.submitQuery('abcd');
    await Future<void>.delayed(Duration.zero);
    expect(repo.queries.single.q, 'abcd');
    c.dispose();
  });

  test('loadMore appends the next page using the cursor, then stops', () async {
    final repo = StubCatalogRepository(onSearch: (q) async {
      return q.cursor == null
          ? OfferSearchPage(items: [makeItem('1'), makeItem('2')], nextCursor: 'c1')
          : OfferSearchPage(items: [makeItem('3')]);
    });
    final c = make(repo);
    await c.refresh();
    await c.loadMore();
    expect(c.items.map((i) => i.offer.id), ['1', '2', '3']);
    expect(repo.queries.last.cursor, 'c1');
    expect(c.hasMore, isFalse);

    final calls = repo.queries.length;
    await c.loadMore(); // no cursor: no-op
    expect(repo.queries, hasLength(calls));
    c.dispose();
  });

  test('a failed loadMore keeps items and can be retried', () async {
    var fail = true;
    final repo = StubCatalogRepository(onSearch: (q) async {
      if (q.cursor == null) {
        return OfferSearchPage(items: [makeItem('1')], nextCursor: 'c1');
      }
      if (fail) throw const NetworkException();
      return OfferSearchPage(items: [makeItem('2')]);
    });
    final c = make(repo);
    await c.refresh();
    await c.loadMore();
    expect(c.loadMoreFailed, isTrue);
    expect(c.items, hasLength(1));
    fail = false;
    await c.loadMore();
    expect(c.loadMoreFailed, isFalse);
    expect(c.items, hasLength(2));
    c.dispose();
  });

  test('a stale response never overwrites a newer search', () async {
    final slow = Completer<OfferSearchPage>();
    final repo = StubCatalogRepository(onSearch: (q) {
      if (q.q == 'old') return slow.future;
      return Future.value(OfferSearchPage(items: [makeItem('new')]));
    });
    final c = make(repo);
    c.submitQuery('old');
    c.submitQuery('new');
    await Future<void>.delayed(Duration.zero);
    slow.complete(OfferSearchPage(items: [makeItem('old')]));
    await Future<void>.delayed(Duration.zero);
    expect(c.items.single.offer.id, 'new');
    c.dispose();
  });

  test('errors become a SearchFailure with the contract code', () async {
    final repo = StubCatalogRepository(
      onSearch: (q) async =>
          throw const ApiException(status: 429, code: 'RATE_LIMITED', retryAfterSeconds: 7),
    );
    final c = make(repo);
    await c.refresh();
    expect(c.status, SearchStatus.error);
    expect(c.failure!.code, 'RATE_LIMITED');
    expect(c.failure!.retryAfterSeconds, 7);

    repo.onSearch = (q) async => throw const NetworkException();
    await c.refresh();
    expect(c.failure!.code, 'NETWORK');
    c.dispose();
  });

  test('filters are sent to the API and restart from the first page', () async {
    final repo = StubCatalogRepository();
    final c = make(repo);
    c.setCategory(const CategoryNode(id: 'cat1', name: 'Plomberie'));
    c.setLocation(const LocationSuggestion(id: 'loc1', city: 'Dakar'));
    c.setSort(OfferSort.rating);
    await Future<void>.delayed(Duration.zero);
    final q = repo.queries.last;
    expect(q.categoryId, 'cat1');
    expect(q.locationId, 'loc1');
    expect(q.sort, OfferSort.rating);
    expect(q.cursor, isNull);
    expect(c.hasActiveFilters, isTrue);

    c.clearFilters();
    await Future<void>.delayed(Duration.zero);
    expect(repo.queries.last.categoryId, isNull);
    expect(c.hasActiveFilters, isFalse);
    c.dispose();
  });

  test('distance sort needs a location and is dropped when it is cleared', () async {
    final repo = StubCatalogRepository();
    final c = make(repo);
    c.setSort(OfferSort.distance); // refused: no location
    expect(c.sort, isNull);

    c.setLocation(const LocationSuggestion(id: 'l', city: 'Dakar'));
    c.setSort(OfferSort.distance);
    expect(c.sort, OfferSort.distance);

    c.setLocation(null);
    expect(c.sort, isNull);
    c.dispose();
  });

  test('categories are fetched once and a failure is retried next time', () async {
    final repo = StubCatalogRepository(
      categories: const [CategoryNode(id: 'a', name: 'A')],
      categoriesError: const NetworkException(),
    );
    final c = make(repo);
    await expectLater(c.loadCategories(), throwsA(isA<NetworkException>()));
    await Future<void>.delayed(Duration.zero);

    repo.categoriesError = null;
    expect((await c.loadCategories()).single.id, 'a');
    await c.loadCategories();
    expect(repo.categoriesCalls, 2); // 1 failed + 1 cached success
    c.dispose();
  });
}

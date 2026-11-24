import 'package:flutter_test/flutter_test.dart';
import 'package:servnova_mobile/core/api/api_exception.dart';
import 'package:servnova_mobile/features/catalog/presentation/offer_detail_controller.dart';

import '../../support/stub_catalog_repository.dart';

void main() {
  test('load fetches the offer by id and becomes ready', () async {
    final repo = StubCatalogRepository(onFetchOffer: (id) async => makeDetail(id: id));
    final c = OfferDetailController(repository: repo, offerId: 'o42');
    expect(c.status, DetailStatus.loading);
    await c.load();
    expect(c.status, DetailStatus.ready);
    expect(c.detail!.offer.id, 'o42');
    expect(repo.fetchedOffers, ['o42']);
    c.dispose();
  });

  test('404 means notFound (offer withdrawn or not valable)', () async {
    final repo = StubCatalogRepository(
      onFetchOffer: (id) async => throw const ApiException(status: 404, code: 'NOT_FOUND'),
    );
    final c = OfferDetailController(repository: repo, offerId: 'x');
    await c.load();
    expect(c.status, DetailStatus.notFound);
    c.dispose();
  });

  test('other failures are errors and can be retried', () async {
    var fail = true;
    final repo = StubCatalogRepository(onFetchOffer: (id) async {
      if (fail) throw const NetworkException();
      return makeDetail();
    });
    final c = OfferDetailController(repository: repo, offerId: 'o1');
    await c.load();
    expect(c.status, DetailStatus.error);
    expect(c.failure!.code, 'NETWORK');

    fail = false;
    await c.load();
    expect(c.status, DetailStatus.ready);
    expect(c.failure, isNull);
    c.dispose();
  });
}

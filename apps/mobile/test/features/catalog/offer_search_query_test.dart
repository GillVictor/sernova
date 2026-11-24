import 'package:flutter_test/flutter_test.dart';
import 'package:servnova_mobile/features/catalog/domain/enums.dart';
import 'package:servnova_mobile/features/catalog/domain/offer_search_query.dart';

void main() {
  test('sends only the limit when nothing else is set', () {
    expect(const OfferSearchQuery().toQueryParameters(), {'limit': '20'});
  });

  test('serializes EP-035 parameters with contract names', () {
    const q = OfferSearchQuery(
      q: '  plombier ',
      categoryId: 'c1',
      locationId: 'l1',
      coverageOnly: true,
      priceMin: 1000,
      priceMax: 20000,
      sort: OfferSort.rating,
      limit: 50,
      cursor: 'abc',
    );
    expect(q.toQueryParameters(), {
      'q': 'plombier',
      'categoryId': 'c1',
      'locationId': 'l1',
      'coverageOnly': 'true',
      'priceMin': '1000',
      'priceMax': '20000',
      'sort': 'rating',
      'limit': '50',
      'cursor': 'abc',
    });
  });

  test('blank text is not sent; lat/lng only together; limit capped at 100', () {
    expect(const OfferSearchQuery(q: '   ', latitude: 1.0).toQueryParameters(), {'limit': '20'});
    final p = const OfferSearchQuery(latitude: -4.26, longitude: 15.28, limit: 500)
        .toQueryParameters();
    expect(p['lat'], '-4.26');
    expect(p['lng'], '15.28');
    expect(p['limit'], '100');
  });

  test('withCursor keeps filters', () {
    final q = const OfferSearchQuery(q: 'x', sort: OfferSort.price).withCursor('n');
    expect(q.q, 'x');
    expect(q.sort, OfferSort.price);
    expect(q.cursor, 'n');
  });
}

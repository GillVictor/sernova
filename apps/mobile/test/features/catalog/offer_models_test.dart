import 'package:flutter_test/flutter_test.dart';
import 'package:servnova_mobile/core/format/money.dart';
import 'package:servnova_mobile/features/catalog/domain/enums.dart';
import 'package:servnova_mobile/features/catalog/domain/offer_models.dart';

void main() {
  test('parses an EP-035 page and tolerates unknown enum values and nulls', () {
    final page = OfferSearchPage.fromJson({
      'items': [
        {
          'offer': {
            'id': 'o1',
            'title': 'Réparation fuite',
            'categoryName': 'Plomberie',
            'price': {'amount': 15000, 'currency': 'XAF'},
            'pricingMode': 'Fixe',
            'modality': 'ADomicile',
          },
          'provider': {
            'id': 'p1',
            'businessName': 'Plomberie Express',
            'level': 'N2',
            'rating': 4.8,
            'reviewCount': 124,
            'city': 'Dakar',
            'quartier': 'Plateau',
          },
          'distanceKm': 2.3,
        },
        {
          'offer': {'id': 'o2', 'title': 'X', 'pricingMode': 'Nouveau', 'modality': '???'},
          'provider': {'id': 'p2', 'businessName': 'Y', 'level': 'N9'},
        },
      ],
      'nextCursor': 'next',
    });

    expect(page.nextCursor, 'next');
    final a = page.items[0];
    expect(a.offer.price, const Money(amount: 15000, currency: 'XAF'));
    expect(a.offer.pricingMode, PricingMode.fixed);
    expect(a.provider.locationLabel, 'Dakar, Plateau');
    expect(a.provider.level.showsVerifiedBadge, isTrue);
    expect(a.distanceKm, 2.3);

    final b = page.items[1];
    expect(b.offer.pricingMode, PricingMode.unknown);
    expect(b.offer.modality, Modality.unknown);
    expect(b.offer.price, isNull);
    expect(b.provider.rating, isNull);
    expect(b.provider.reviewCount, 0);
    expect(b.provider.level, VerificationLevel.unknown);
    expect(b.provider.level.showsVerifiedBadge, isFalse);
    expect(b.provider.locationLabel, isNull);
  });

  test('category tree flattens depth-first with depth', () {
    const tree = [
      CategoryNode(id: 'a', name: 'A', children: [
        CategoryNode(id: 'a1', name: 'A1'),
        CategoryNode(id: 'a2', name: 'A2', children: [CategoryNode(id: 'a21', name: 'A21')]),
      ]),
      CategoryNode(id: 'b', name: 'B'),
    ];
    final flat = CategoryNode.flatten(tree).map((r) => '${r.$1.id}:${r.$2}').toList();
    expect(flat, ['a:0', 'a1:1', 'a2:1', 'a21:2', 'b:0']);
  });

  test('location label joins city and district', () {
    expect(const LocationSuggestion(id: '1', city: 'Dakar', district: 'Plateau').label,
        'Dakar, Plateau');
    expect(const LocationSuggestion(id: '2', city: 'Brazzaville').label, 'Brazzaville');
  });

  test('parses an EP-037 detail with gallery, items and completion rate', () {
    final d = OfferDetail.fromJson({
      'offer': {
        'id': 'o1',
        'title': 'Dev web',
        'description': 'Sites modernes',
        'price': {'amount': 50000, 'currency': 'XAF'},
        'pricingMode': 'Fixe',
        'modality': 'ADistance',
        'photoUrls': ['a', 'b', 3],
      },
      'provider': {'id': 'p1', 'businessName': 'M. Diop', 'level': 'N3', 'completionRate': 98},
      'items': [
        {'id': 'i1', 'designation': 'Article', 'price': {'amount': 1000, 'currency': 'XAF'}, 'available': true},
        {'id': 'i2', 'designation': 'Autre'},
      ],
      'freeSlots': [],
    });
    expect(d.description, 'Sites modernes');
    expect(d.gallery, ['a', 'b']); // non-string entries ignored
    expect(d.provider.completionRate, 98);
    expect(d.items[0].available, isTrue);
    expect(d.items[1].available, isFalse); // missing => not available
    expect(d.items[1].price, isNull);
  });

  test('gallery falls back to the cover photo', () {
    final d = OfferDetail.fromJson({
      'offer': {'id': 'o', 'title': 't', 'photoUrl': 'cover'},
      'provider': {'id': 'p', 'businessName': 'b'},
    });
    expect(d.gallery, ['cover']);
    expect(d.items, isEmpty);
  });
}

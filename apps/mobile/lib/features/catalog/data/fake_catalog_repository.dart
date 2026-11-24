import '../../../core/api/api_exception.dart';
import '../../../core/format/money.dart';
import '../domain/enums.dart';
import '../domain/offer_models.dart';
import '../domain/offer_search_query.dart';
import 'catalog_repository.dart';

/// Development data (`--dart-define=USE_FAKE_API=true`): no network.
/// To be replaced by the mock server generated at P-07.
class FakeCatalogRepository implements CatalogRepository {
  static const _xaf = 'XAF';

  static final _all = <OfferSearchItem>[
    _item('1', 'Réparation fuite d\'eau', 'Plomberie', 15000, 4.8, 124, 'Plateau'),
    _item('2', 'Installation sanitaire', 'Plomberie', 20000, 4.6, 98, 'Almadies'),
    _item('3', 'Débouchage canalisation', 'Plomberie', 12000, 4.7, 76, 'Ngor'),
    _item('4', 'Entretien chauffe-eau', 'Plomberie', 18000, 4.5, 53, 'Sacré-Cœur'),
  ];

  static OfferSearchItem _item(String id, String title, String cat, int price,
          double rating, int reviews, String quartier) =>
      OfferSearchItem(
        offer: OfferSummary(
          id: id,
          title: title,
          categoryName: cat,
          price: Money(amount: price, currency: _xaf),
          pricingMode: PricingMode.fixed,
          modality: Modality.atHome,
        ),
        provider: ProviderSummary(
          id: 'p$id',
          businessName: 'Prestataire $id',
          level: VerificationLevel.n2,
          rating: rating,
          reviewCount: reviews,
          city: 'Dakar',
          quartier: quartier,
        ),
      );

  @override
  Future<OfferSearchPage> searchOffers(OfferSearchQuery query) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    final q = (query.q ?? '').toLowerCase().trim();
    final items = _all.where((i) {
      if (q.isEmpty) return true;
      return i.offer.title.toLowerCase().contains(q) ||
          (i.offer.categoryName ?? '').toLowerCase().contains(q) ||
          'plombier'.startsWith(q);
    }).toList();
    return OfferSearchPage(items: items);
  }

  @override
  Future<OfferDetail> fetchOffer(String id) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    final hit = _all.where((i) => i.offer.id == id);
    if (hit.isEmpty) throw const ApiException(status: 404, code: 'NOT_FOUND');
    final i = hit.first;
    return OfferDetail(
      offer: i.offer,
      description: 'Intervention rapide et soignée par un professionnel expérimenté. '
          'Diagnostic sur place, devis annoncé avant le début des travaux et '
          'matériel de qualité. Déplacement possible dans toute la ville.',
      provider: ProviderSummary(
        id: i.provider.id,
        businessName: 'Mamadou Diop',
        level: i.provider.level,
        rating: i.provider.rating,
        reviewCount: i.provider.reviewCount,
        city: i.provider.city,
        quartier: i.provider.quartier,
        completionRate: 98,
      ),
    );
  }

  @override
  Future<List<CategoryNode>> fetchCategories() async => const [
        CategoryNode(id: 'c-dom', name: 'Services à domicile', children: [
          CategoryNode(id: 'c-plomb', name: 'Plomberie'),
          CategoryNode(id: 'c-menage', name: 'Ménage'),
        ]),
        CategoryNode(id: 'c-num', name: 'Services numériques'),
      ];

  @override
  Future<List<LocationSuggestion>> searchLocations({
    required String countryCode,
    String? q,
    int limit = 10,
  }) async {
    const all = [
      LocationSuggestion(id: 'l1', city: 'Brazzaville'),
      LocationSuggestion(id: 'l2', city: 'Pointe-Noire'),
      LocationSuggestion(id: 'l3', city: 'Dakar', district: 'Plateau'),
    ];
    final s = (q ?? '').toLowerCase().trim();
    return all.where((l) => s.isEmpty || l.label.toLowerCase().contains(s)).take(limit).toList();
  }
}

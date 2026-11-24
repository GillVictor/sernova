import 'dart:async';

import 'package:servnova_mobile/core/format/money.dart';
import 'package:servnova_mobile/features/catalog/data/catalog_repository.dart';
import 'package:servnova_mobile/features/catalog/domain/enums.dart';
import 'package:servnova_mobile/features/catalog/domain/offer_models.dart';
import 'package:servnova_mobile/features/catalog/domain/offer_search_query.dart';

OfferSearchItem makeItem(
  String id, {
  String title = 'Réparation fuite d\'eau',
  VerificationLevel level = VerificationLevel.n2,
  double? rating = 4.8,
  int reviews = 124,
  int price = 15000,
  PricingMode mode = PricingMode.fixed,
  double? distanceKm,
}) =>
    OfferSearchItem(
      offer: OfferSummary(
        id: id,
        title: title,
        categoryName: 'Plomberie',
        price: Money(amount: price, currency: 'XAF'),
        pricingMode: mode,
        modality: Modality.atHome,
      ),
      provider: ProviderSummary(
        id: 'p$id',
        businessName: 'P$id',
        level: level,
        rating: rating,
        reviewCount: reviews,
        city: 'Dakar',
        quartier: 'Plateau',
      ),
      distanceKm: distanceKm,
    );

/// Scriptable repository: records queries, answers with [onSearch].
class StubCatalogRepository implements CatalogRepository {
  StubCatalogRepository({
    this.onSearch,
    this.categories = const [],
    this.locations = const [],
    this.categoriesError,
    this.onFetchOffer,
  });

  Future<OfferSearchPage> Function(OfferSearchQuery q)? onSearch;
  List<CategoryNode> categories;
  List<LocationSuggestion> locations;
  Object? categoriesError;
  Future<OfferDetail> Function(String id)? onFetchOffer;
  final List<String> fetchedOffers = [];

  final List<OfferSearchQuery> queries = [];
  int categoriesCalls = 0;

  @override
  Future<OfferSearchPage> searchOffers(OfferSearchQuery query) {
    queries.add(query);
    return onSearch?.call(query) ?? Future.value(const OfferSearchPage(items: []));
  }

  @override
  Future<OfferDetail> fetchOffer(String id) {
    fetchedOffers.add(id);
    return onFetchOffer!(id);
  }

  @override
  Future<List<CategoryNode>> fetchCategories() async {
    categoriesCalls++;
    if (categoriesError != null) throw categoriesError!;
    return categories;
  }

  @override
  Future<List<LocationSuggestion>> searchLocations({
    required String countryCode,
    String? q,
    int limit = 10,
  }) async =>
      locations;
}

OfferDetail makeDetail({
  String id = 'o1',
  String description = 'Création de sites web modernes, rapides et sécurisés.',
  List<String> photoUrls = const [],
  List<OfferItem> items = const [],
  double? completionRate = 98,
  VerificationLevel level = VerificationLevel.n2,
  PricingMode mode = PricingMode.fixed,
}) =>
    OfferDetail(
      offer: OfferSummary(
        id: id,
        title: 'Développement web professionnel',
        categoryName: 'Informatique',
        price: const Money(amount: 50000, currency: 'XAF'),
        pricingMode: mode,
        modality: Modality.remote,
      ),
      description: description,
      photoUrls: photoUrls,
      items: items,
      provider: ProviderSummary(
        id: 'p1',
        businessName: 'Mamadou Diop',
        level: level,
        rating: 4.8,
        reviewCount: 256,
        city: 'Dakar',
        completionRate: completionRate,
      ),
    );

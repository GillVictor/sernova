import '../domain/offer_models.dart';
import '../domain/offer_search_query.dart';

/// Read access to the public catalog. Only contract routes are behind it.
abstract class CatalogRepository {
  /// EP-035 `GET /offers`.
  Future<OfferSearchPage> searchOffers(OfferSearchQuery query);

  /// EP-037 `GET /offers/{id}` (public). Throws ApiException NOT_FOUND (404)
  /// when the offer does not exist or is not visible.
  Future<OfferDetail> fetchOffer(String id);

  /// EP-021 `GET /categories` (tree of active categories).
  Future<List<CategoryNode>> fetchCategories();

  /// EP-023 `GET /locations` (assisted entry).
  Future<List<LocationSuggestion>> searchLocations({
    required String countryCode,
    String? q,
    int limit = 10,
  });
}

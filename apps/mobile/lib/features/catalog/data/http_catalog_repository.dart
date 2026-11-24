import '../../../core/api/api_client.dart';
import '../../../core/api/api_exception.dart';
import '../../../core/api/routes.dart';
import '../domain/offer_models.dart';
import '../domain/offer_search_query.dart';
import 'catalog_repository.dart';

class HttpCatalogRepository implements CatalogRepository {
  HttpCatalogRepository(this._api);
  final ApiClient _api;

  @override
  Future<OfferSearchPage> searchOffers(OfferSearchQuery query) async {
    final body = await _api.getJson(ApiRoutes.offers, query: query.toQueryParameters());
    return _parse(() => OfferSearchPage.fromJson(body as Map<String, dynamic>));
  }

  @override
  Future<OfferDetail> fetchOffer(String id) async {
    final body = await _api.getJson(ApiRoutes.offer(id));
    return _parse(() => OfferDetail.fromJson(body as Map<String, dynamic>));
  }

  @override
  Future<List<CategoryNode>> fetchCategories() async {
    final body = await _api.getJson(ApiRoutes.categories);
    return _parse(() => [
          for (final e in body as List) CategoryNode.fromJson(e as Map<String, dynamic>),
        ]);
  }

  @override
  Future<List<LocationSuggestion>> searchLocations({
    required String countryCode,
    String? q,
    int limit = 10,
  }) async {
    final body = await _api.getJson(ApiRoutes.locations, query: {
      'countryCode': countryCode,
      if (q != null && q.trim().isNotEmpty) 'q': q.trim(),
      'limit': '$limit',
    });
    return _parse(() => [
          for (final e in body as List) LocationSuggestion.fromJson(e as Map<String, dynamic>),
        ]);
  }

  /// A body that does not match the expected shape is a server/contract
  /// problem: surface it as UNKNOWN instead of crashing the screen.
  T _parse<T>(T Function() parse) {
    try {
      return parse();
    } on TypeError {
      throw const ApiException(status: 200, code: 'UNKNOWN');
    }
  }
}

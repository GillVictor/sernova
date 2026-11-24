import '../../../core/api/api_client.dart';
import '../../../core/api/parse.dart';
import '../../../core/api/routes.dart';
import '../../../core/domain/count.dart';

abstract class RequestFeedRepository {
  /// Number of open requests for me (EP-043 `GET /requests/feed`). The
  /// contract has no count route: the count comes from one page of 100 (OP-25).
  Future<Count> countOpenRequests();
}

class HttpRequestFeedRepository implements RequestFeedRepository {
  HttpRequestFeedRepository(this._api);
  final ApiClient _api;

  @override
  Future<Count> countOpenRequests() async {
    final body = await _api.getJson(ApiRoutes.requestFeed, query: {
      'status': 'Ouverte', // StatutDemande
      'limit': '100',
    });
    final items = parseItems<Object>(body, (m) => m);
    return Count(items.length, atLeast: parseNextCursor(body) != null);
  }
}

import '../../../core/api/api_client.dart';
import '../../../core/api/parse.dart';
import '../../../core/api/routes.dart';
import '../domain/account_summary.dart';

abstract class AccountRepository {
  /// EP-009 `GET /users/me`.
  Future<AccountSummary> fetchMe();
}

class HttpAccountRepository implements AccountRepository {
  HttpAccountRepository(this._api);
  final ApiClient _api;

  @override
  Future<AccountSummary> fetchMe() async {
    final body = await _api.getJson(ApiRoutes.me);
    return parseBody(() => AccountSummary.fromJson(body as Map<String, dynamic>));
  }
}

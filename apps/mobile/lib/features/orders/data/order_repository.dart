import '../../../core/api/api_client.dart';
import '../../../core/api/parse.dart';
import '../../../core/api/routes.dart';
import '../domain/order_models.dart';

abstract class OrderRepository {
  /// EP-065 `GET /transactions` (role: `client` or `provider`).
  Future<OrderPage> listMine({
    required String role,
    TransactionStatus? status,
    int limit = 20,
  });
}

class HttpOrderRepository implements OrderRepository {
  HttpOrderRepository(this._api);
  final ApiClient _api;

  @override
  Future<OrderPage> listMine({
    required String role,
    TransactionStatus? status,
    int limit = 20,
  }) async {
    final body = await _api.getJson(ApiRoutes.myTransactions, query: {
      'role': role,
      if (status != null && status.wire.isNotEmpty) 'status': status.wire,
      'limit': '${limit.clamp(1, 100)}',
    });
    return OrderPage(
      items: parseItems(body, OrderSummary.fromJson),
      nextCursor: parseNextCursor(body),
    );
  }
}

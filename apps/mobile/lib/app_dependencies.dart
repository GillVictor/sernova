import 'core/api/api_client.dart';
import 'features/account/data/account_repository.dart';
import 'features/catalog/data/catalog_repository.dart';
import 'features/catalog/data/fake_catalog_repository.dart';
import 'features/catalog/data/http_catalog_repository.dart';
import 'features/notifications/data/notification_repository.dart';
import 'features/orders/data/order_repository.dart';
import 'features/provider/data/fake_provider_space.dart';
import 'features/provider/data/provider_repository.dart';
import 'features/requests/data/request_feed_repository.dart';

/// Repositories shared by the screens (plain constructor injection).
class AppDependencies {
  const AppDependencies({
    required this.catalog,
    required this.provider,
    required this.account,
    required this.orders,
    required this.requests,
    required this.notifications,
  });

  factory AppDependencies.http(ApiClient api) => AppDependencies(
        catalog: HttpCatalogRepository(api),
        provider: HttpProviderRepository(api),
        account: HttpAccountRepository(api),
        orders: HttpOrderRepository(api),
        requests: HttpRequestFeedRepository(api),
        notifications: HttpNotificationRepository(api),
      );

  factory AppDependencies.fake({bool providerActive = true}) {
    final space = FakeProviderSpace(providerActive: providerActive);
    return AppDependencies(
      catalog: FakeCatalogRepository(),
      provider: space,
      account: space,
      orders: space,
      requests: space,
      notifications: space,
    );
  }

  final CatalogRepository catalog;
  final ProviderRepository provider;
  final AccountRepository account;
  final OrderRepository orders;
  final RequestFeedRepository requests;
  final NotificationRepository notifications;
}

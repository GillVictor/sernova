import '../../../core/api/api_client.dart';
import '../../../core/api/parse.dart';
import '../../../core/api/routes.dart';
import '../domain/notification_models.dart';

abstract class NotificationRepository {
  /// EP-109 `GET /notifications`.
  Future<List<AppNotification>> list({bool? unreadOnly, int limit = 20});

  /// EP-110 `GET /notifications/unread-count`.
  Future<int> unreadCount();

  /// EP-111 `POST /notifications/{id}/read`.
  Future<void> markRead(String id);

  /// EP-112 `POST /notifications/read-all`.
  Future<void> markAllRead();
}

class HttpNotificationRepository implements NotificationRepository {
  HttpNotificationRepository(this._api);
  final ApiClient _api;

  @override
  Future<List<AppNotification>> list({bool? unreadOnly, int limit = 20}) async {
    final body = await _api.getJson(ApiRoutes.notifications, query: {
      if (unreadOnly != null) 'unread': '$unreadOnly',
      'limit': '${limit.clamp(1, 100)}',
    });
    return parseItems(body, AppNotification.fromJson);
  }

  @override
  Future<int> unreadCount() async {
    final body = await _api.getJson(ApiRoutes.notificationsUnreadCount);
    return parseBody(() => ((body as Map<String, dynamic>)['count'] as num).toInt());
  }

  @override
  Future<void> markRead(String id) async {
    await _api.postJson(ApiRoutes.notificationRead(id));
  }

  @override
  Future<void> markAllRead() async {
    await _api.postJson(ApiRoutes.notificationsReadAll);
  }
}

import 'package:flutter/foundation.dart';

import '../../../core/api/api_failure.dart';
import '../../../core/api/load_state.dart';
import '../../../core/domain/count.dart';
import '../../account/data/account_repository.dart';
import '../../account/domain/account_summary.dart';
import '../../notifications/data/notification_repository.dart';
import '../../notifications/domain/notification_models.dart';
import '../../orders/data/order_repository.dart';
import '../../orders/domain/order_models.dart';
import '../../requests/data/request_feed_repository.dart';
import '../data/provider_repository.dart';
import '../domain/provider_models.dart';

class NotificationsBlock {
  const NotificationsBlock({required this.items, required this.unread});
  final List<AppNotification> items;
  final int unread;
}

/// State of the provider dashboard. Each block loads and fails on its own.
class DashboardController extends ChangeNotifier {
  DashboardController({
    required ProviderRepository provider,
    required AccountRepository account,
    required OrderRepository orders,
    required RequestFeedRepository requests,
    required NotificationRepository notifications,
    this.recentOrders = 4,
    this.recentNotifications = 3,
  })  : _provider = provider,
        _account = account,
        _orders = orders,
        _requests = requests,
        _notifications = notifications;

  final ProviderRepository _provider;
  final AccountRepository _account;
  final OrderRepository _orders;
  final RequestFeedRepository _requests;
  final NotificationRepository _notifications;
  final int recentOrders;
  final int recentNotifications;

  LoadState<ProviderProfile> profile = const LoadState.loading();
  LoadState<AccountSummary> account = const LoadState.loading();
  LoadState<Count> inProgress = const LoadState.loading();
  LoadState<Count> available = const LoadState.loading();
  LoadState<List<OrderSummary>> recent = const LoadState.loading();
  LoadState<NotificationsBlock> notifications = const LoadState.loading();

  /// Failure of the last "mark as read" action (the list is left unchanged).
  ApiFailure? actionFailure;

  int _generation = 0;
  bool _disposed = false;

  int get unread => notifications.data?.unread ?? 0;

  Future<void> load() async {
    final gen = ++_generation;
    await Future.wait([
      _run(_provider.fetchProfile, (s) => profile = s, gen),
      _run(_account.fetchMe, (s) => account = s, gen),
      _run(() async {
        final page = await _orders.listMine(
            role: 'provider', status: TransactionStatus.inProgress, limit: 100);
        return Count(page.items.length, atLeast: page.nextCursor != null);
      }, (s) => inProgress = s, gen),
      _run(_requests.countOpenRequests, (s) => available = s, gen),
      _run(() async => (await _orders.listMine(role: 'provider', limit: recentOrders)).items,
          (s) => recent = s, gen),
      _run(() async {
        final items = await _notifications.list(limit: recentNotifications);
        final unread = await _notifications.unreadCount();
        return NotificationsBlock(items: items, unread: unread);
      }, (s) => notifications = s, gen),
    ]);
  }

  Future<void> _run<T>(
    Future<T> Function() fetch,
    void Function(LoadState<T>) assign,
    int gen,
  ) async {
    try {
      final v = await fetch();
      if (gen != _generation) return;
      assign(LoadState.data(v));
    } catch (e) {
      if (gen != _generation) return;
      assign(LoadState.failed(ApiFailure.from(e)));
    }
    _notify();
  }

  Future<void> markAllRead() async {
    final block = notifications.data;
    if (block == null || block.unread == 0) return;
    actionFailure = null;
    try {
      await _notifications.markAllRead();
      notifications = LoadState.data(NotificationsBlock(
        items: [for (final n in block.items) n.asRead()],
        unread: 0,
      ));
    } catch (e) {
      actionFailure = ApiFailure.from(e);
    }
    _notify();
  }

  Future<void> markRead(String id) async {
    final block = notifications.data;
    if (block == null) return;
    final target = block.items.where((n) => n.id == id && !n.read);
    if (target.isEmpty) return;
    actionFailure = null;
    try {
      await _notifications.markRead(id);
      notifications = LoadState.data(NotificationsBlock(
        items: [for (final n in block.items) n.id == id ? n.asRead() : n],
        unread: block.unread > 0 ? block.unread - 1 : 0,
      ));
    } catch (e) {
      actionFailure = ApiFailure.from(e);
    }
    _notify();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}

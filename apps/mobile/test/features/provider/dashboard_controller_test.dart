import 'package:flutter_test/flutter_test.dart';
import 'package:servnova_mobile/core/api/api_exception.dart';
import 'package:servnova_mobile/features/notifications/domain/notification_models.dart';
import 'package:servnova_mobile/features/orders/domain/order_models.dart';
import 'package:servnova_mobile/features/provider/presentation/dashboard_controller.dart';

import '../../support/stub_space.dart';

DashboardController make(StubSpace s) => DashboardController(
      provider: s,
      account: s,
      orders: s,
      requests: s,
      notifications: s,
    );

List<AppNotification> two() => [
      const AppNotification(id: 'n1', content: 'Nouvelle commande reçue (#1024)', read: false),
      const AppNotification(id: 'n2', content: 'Autre', read: false),
    ];

void main() {
  test('load fills every block', () async {
    final s = StubSpace()..notifications = two();
    final c = make(s);
    await c.load();

    expect(c.profile.data!.rating, 4.7);
    expect(c.account.data!.initials, 'JM');
    expect(c.inProgress.data!.label, '3');
    expect(c.available.data!.label, '12');
    expect(c.recent.data!.length, 4);
    expect(c.notifications.data!.unread, 2);
    expect(c.unread, 2);
    c.dispose();
  });

  test('asks for the provider role: in-progress count (100) and the 4 latest orders', () async {
    final s = StubSpace();
    final c = make(s);
    await c.load();
    expect(s.orderCalls.any((o) => o.role == 'provider' && o.status == TransactionStatus.inProgress && o.limit == 100), isTrue);
    expect(s.orderCalls.any((o) => o.status == null && o.limit == 4), isTrue);
    c.dispose();
  });

  test('in-progress count is "at least" when another page exists', () async {
    final s = StubSpace()
      ..inProgressCount = 100
      ..ordersNextCursor = 'more';
    final c = make(s);
    await c.load();
    expect(c.inProgress.data!.label, '100+');
    c.dispose();
  });

  test('one failing block does not blank the others', () async {
    final s = StubSpace()..ordersError = const NetworkException();
    final c = make(s);
    await c.load();

    expect(c.inProgress.hasFailed, isTrue);
    expect(c.recent.hasFailed, isTrue);
    expect(c.recent.failure!.code, 'NETWORK');
    expect(c.profile.hasData, isTrue);
    expect(c.available.hasData, isTrue);
    expect(c.notifications.hasData, isTrue);
    c.dispose();
  });

  test('a failed block can be reloaded', () async {
    final s = StubSpace()..requestsError = const ApiException(status: 500, code: 'UNKNOWN');
    final c = make(s);
    await c.load();
    expect(c.available.hasFailed, isTrue);

    s.requestsError = null;
    await c.load();
    expect(c.available.hasData, isTrue);
    c.dispose();
  });

  test('markAllRead calls the API and clears the unread count', () async {
    final s = StubSpace()..notifications = two();
    final c = make(s);
    await c.load();
    await c.markAllRead();

    expect(s.markAllReadCalls, 1);
    expect(c.unread, 0);
    expect(c.notifications.data!.items.every((n) => n.read), isTrue);
    c.dispose();
  });

  test('markAllRead failure leaves the list unchanged and reports it', () async {
    final s = StubSpace()
      ..notifications = two()
      ..markError = const NetworkException();
    final c = make(s);
    await c.load();
    await c.markAllRead();

    expect(c.unread, 2);
    expect(c.actionFailure!.code, 'NETWORK');
    c.dispose();
  });

  test('markRead marks one notification and ignores already-read ones', () async {
    final s = StubSpace()..notifications = [...two(), const AppNotification(id: 'n3', content: 'Lue', read: true)];
    final c = make(s);
    await c.load();

    await c.markRead('n1');
    expect(s.markedRead, ['n1']);
    expect(c.unread, 1);

    await c.markRead('n3'); // already read: no call
    await c.markRead('missing');
    expect(s.markedRead, ['n1']);
    c.dispose();
  });
}

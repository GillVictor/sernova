import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:servnova_mobile/core/api/api_client.dart';
import 'package:servnova_mobile/core/api/api_exception.dart';
import 'package:servnova_mobile/features/notifications/data/notification_repository.dart';
import 'package:servnova_mobile/features/orders/data/order_repository.dart';
import 'package:servnova_mobile/features/orders/domain/order_models.dart';
import 'package:servnova_mobile/features/provider/data/provider_repository.dart';
import 'package:servnova_mobile/features/provider/domain/provider_models.dart';
import 'package:servnova_mobile/features/requests/data/request_feed_repository.dart';

http.Response json(Object body, [int status = 200]) => http.Response.bytes(
      utf8.encode(jsonEncode(body)),
      status,
      headers: {'content-type': 'application/json; charset=utf-8'},
    );

ApiClient apiWith(Future<http.Response> Function(http.Request) handler, List<http.Request> log) =>
    ApiClient(
      baseUrl: Uri.parse('https://api.test/api/v1'),
      httpClient: MockClient((r) async {
        log.add(r);
        return handler(r);
      }),
    );

void main() {
  test('provider repository: GET /providers/me and PATCH with only the changes', () async {
    final log = <http.Request>[];
    final repo = HttpProviderRepository(apiWith((r) async => json({
          'businessName': 'Nouveau',
          'level': 'N1',
          'status': 'Actif',
        }), log));

    final p = await repo.fetchProfile();
    expect(log.last.method, 'GET');
    expect(log.last.url.path, '/api/v1/providers/me');
    expect(p.businessName, 'Nouveau');

    await repo.updateProfile(const ProfileChanges({'businessName': 'Nouveau', 'videoUrl': null}));
    expect(log.last.method, 'PATCH');
    expect(jsonDecode(log.last.body), {'businessName': 'Nouveau', 'videoUrl': null});
  });

  test('provider repository: verifications list and malformed body -> UNKNOWN', () async {
    final log = <http.Request>[];
    final ok = HttpProviderRepository(apiWith((r) async => json([
          {'id': 'v1', 'type': 'Identite', 'status': 'EnAttente'}
        ]), log));
    final list = await ok.fetchVerifications();
    expect(log.last.url.path, '/api/v1/providers/me/verifications');
    expect(list.single.state, ValidationState.pending);

    final bad = HttpProviderRepository(apiWith((r) async => json({'unexpected': true}), []));
    await expectLater(bad.fetchVerifications(),
        throwsA(isA<ApiException>().having((e) => e.code, 'code', 'UNKNOWN')));
  });

  test('order repository sends role, status wire value and limit', () async {
    final log = <http.Request>[];
    final repo = HttpOrderRepository(apiWith((r) async => json({
          'items': [
            {'id': 't1', 'reference': '#1024', 'title': 'Site', 'status': 'EnAttente', 'counterpartName': 'Marie L.'}
          ],
          'nextCursor': 'c2',
        }), log));
    final page = await repo.listMine(role: 'provider', status: TransactionStatus.inProgress, limit: 100);
    expect(log.last.url.path, '/api/v1/transactions');
    expect(log.last.url.queryParameters, {'role': 'provider', 'status': 'EnCours', 'limit': '100'});
    expect(page.items.single.counterpartName, 'Marie L.');
    expect(page.nextCursor, 'c2');
  });

  test('request feed count: number of items, atLeast when a next page exists', () async {
    final log = <http.Request>[];
    final one = HttpRequestFeedRepository(apiWith((r) async => json({
          'items': [{'request': {}}, {'request': {}}],
        }), log));
    final c1 = await one.countOpenRequests();
    expect(log.last.url.path, '/api/v1/requests/feed');
    expect(log.last.url.queryParameters, {'status': 'Ouverte', 'limit': '100'});
    expect(c1.value, 2);
    expect(c1.atLeast, isFalse);

    final more = HttpRequestFeedRepository(apiWith((r) async => json({'items': [], 'nextCursor': 'x'}), []));
    expect((await more.countOpenRequests()).atLeast, isTrue);
  });

  test('notification repository: list, unread count, mark read, read all', () async {
    final log = <http.Request>[];
    final repo = HttpNotificationRepository(apiWith((r) async {
      if (r.url.path.endsWith('/unread-count')) return json({'count': 4});
      if (r.method == 'POST') return http.Response('', 204);
      return json({
        'items': [
          {'id': 'n1', 'content': 'Nouvelle commande', 'read': false, 'createdAt': '2026-11-21T10:00:00Z'}
        ],
      });
    }, log));

    final items = await repo.list(limit: 3);
    expect(log.last.url.queryParameters, {'limit': '3'});
    expect(items.single.read, isFalse);
    expect(items.single.createdAt, DateTime.utc(2026, 11, 21, 10));

    expect(await repo.unreadCount(), 4);
    expect(log.last.url.path, '/api/v1/notifications/unread-count');

    await repo.markRead('n 1');
    expect(log.last.method, 'POST');
    expect(log.last.url.toString(), 'https://api.test/api/v1/notifications/n%201/read');

    await repo.markAllRead();
    expect(log.last.url.path, '/api/v1/notifications/read-all');
  });
}

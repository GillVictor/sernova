import 'package:servnova_mobile/core/domain/count.dart';
import 'package:servnova_mobile/features/account/data/account_repository.dart';
import 'package:servnova_mobile/features/account/domain/account_summary.dart';
import 'package:servnova_mobile/features/catalog/domain/enums.dart';
import 'package:servnova_mobile/features/catalog/domain/offer_models.dart';
import 'package:servnova_mobile/features/notifications/data/notification_repository.dart';
import 'package:servnova_mobile/features/notifications/domain/notification_models.dart';
import 'package:servnova_mobile/features/orders/data/order_repository.dart';
import 'package:servnova_mobile/features/orders/domain/order_models.dart';
import 'package:servnova_mobile/features/provider/data/provider_repository.dart';
import 'package:servnova_mobile/features/provider/domain/provider_activation.dart';
import 'package:servnova_mobile/features/provider/domain/provider_models.dart';
import 'package:servnova_mobile/features/requests/data/request_feed_repository.dart';

ProviderProfile sampleProfile({
  String name = 'Jean M. – Plomberie',
  String description = 'Plombier.',
  VerificationLevel level = VerificationLevel.n1,
  String? portfolio,
  String? video,
}) =>
    ProviderProfile(
      businessName: name,
      description: description,
      level: level,
      status: ProviderStatus.active,
      portfolioUrl: portfolio,
      videoUrl: video,
      workLocation: const LocationSuggestion(id: 'l1', city: 'Brazzaville', district: 'Poto-Poto'),
      completionRate: 96,
      rating: 4.7,
      reviewCount: 52,
    );

const sampleOrders = [
  OrderSummary(id: 't1', reference: '#1024', title: 'Création de site vitrine',
      status: TransactionStatus.pending, counterpartName: 'Marie L.'),
  OrderSummary(id: 't2', reference: '#1021', title: "Réparation de fuite d'eau",
      status: TransactionStatus.inProgress, counterpartName: 'Paul T.'),
  OrderSummary(id: 't3', reference: '#1018', title: 'Cours de soutien en maths',
      status: TransactionStatus.accepted, counterpartName: 'Awa N.'),
  OrderSummary(id: 't4', reference: '#1015', title: 'Dépannage informatique',
      status: TransactionStatus.completed, counterpartName: 'Luc B.'),
];

/// Scriptable implementation of every provider-space repository.
/// Set a `*Error` field to make that call fail.
class StubSpace
    implements
        ProviderRepository,
        AccountRepository,
        OrderRepository,
        RequestFeedRepository,
        NotificationRepository {
  ProviderProfile profile = sampleProfile();
  List<VerificationRecord> verifications = [];
  AccountSummary account =
      const AccountSummary(displayName: 'Jean M.', providerStatus: ProviderStatus.active);
  List<AppNotification> notifications = [];
  Count available = const Count(12);
  int inProgressCount = 3;
  String? ordersNextCursor;

  Object? accountError;
  Object? profileError;
  Object? updateError;
  Object? activateError;
  Object? verificationsError;
  Object? ordersError;
  Object? requestsError;
  Object? notificationsError;
  Object? markError;

  final List<ProfileChanges> updates = [];
  final List<ProviderActivation> activations = [];
  final List<({String role, TransactionStatus? status, int limit})> orderCalls = [];
  int markAllReadCalls = 0;
  final List<String> markedRead = [];

  // ProviderRepository
  @override
  Future<void> activate(ProviderActivation activation) async {
    activations.add(activation);
    if (activateError != null) throw activateError!;
  }

  @override
  Future<ProviderProfile> fetchProfile() async {
    if (profileError != null) throw profileError!;
    return profile;
  }

  @override
  Future<ProviderProfile> updateProfile(ProfileChanges changes) async {
    updates.add(changes);
    if (updateError != null) throw updateError!;
    return profile;
  }

  @override
  Future<List<VerificationRecord>> fetchVerifications() async {
    if (verificationsError != null) throw verificationsError!;
    return verifications;
  }

  // AccountRepository
  @override
  Future<AccountSummary> fetchMe() async {
    if (accountError != null) throw accountError!;
    return account;
  }

  // OrderRepository
  @override
  Future<OrderPage> listMine({
    required String role,
    TransactionStatus? status,
    int limit = 20,
  }) async {
    orderCalls.add((role: role, status: status, limit: limit));
    if (ordersError != null) throw ordersError!;
    if (status == TransactionStatus.inProgress) {
      return OrderPage(
        items: [
          for (var i = 0; i < inProgressCount; i++)
            OrderSummary(
                id: 'ip$i', reference: '#$i', title: 't', status: TransactionStatus.inProgress),
        ],
        nextCursor: ordersNextCursor,
      );
    }
    return OrderPage(items: sampleOrders.take(limit).toList());
  }

  // RequestFeedRepository
  @override
  Future<Count> countOpenRequests() async {
    if (requestsError != null) throw requestsError!;
    return available;
  }

  // NotificationRepository
  @override
  Future<List<AppNotification>> list({bool? unreadOnly, int limit = 20}) async {
    if (notificationsError != null) throw notificationsError!;
    return notifications.take(limit).toList();
  }

  @override
  Future<int> unreadCount() async => notifications.where((n) => !n.read).length;

  @override
  Future<void> markRead(String id) async {
    if (markError != null) throw markError!;
    markedRead.add(id);
  }

  @override
  Future<void> markAllRead() async {
    if (markError != null) throw markError!;
    markAllReadCalls++;
  }
}

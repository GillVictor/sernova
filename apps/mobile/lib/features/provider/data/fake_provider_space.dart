import '../../../core/domain/count.dart';
import '../../account/data/account_repository.dart';
import '../../account/domain/account_summary.dart';
import '../../catalog/domain/enums.dart';
import '../../catalog/domain/offer_models.dart';
import '../../notifications/data/notification_repository.dart';
import '../../notifications/domain/notification_models.dart';
import '../../orders/data/order_repository.dart';
import '../../orders/domain/order_models.dart';
import '../../requests/data/request_feed_repository.dart';
import '../domain/provider_activation.dart';
import '../domain/provider_models.dart';
import 'provider_repository.dart';

/// Development data for the provider space (`--dart-define=USE_FAKE_API=true`).
/// To be replaced by the mock server generated at P-07.
class FakeProviderSpace
    implements
        ProviderRepository,
        AccountRepository,
        OrderRepository,
        RequestFeedRepository,
        NotificationRepository {
  FakeProviderSpace({this.providerActive = true});

  /// false simulates a simple client (no active provider profile).
  final bool providerActive;

  ProviderProfile _profile = const ProviderProfile(
    businessName: 'Jean M. – Plomberie et dépannage',
    description: "Plombier avec 8 ans d'expérience. Interventions à domicile à Brazzaville, devis gratuit.",
    level: VerificationLevel.n1,
    status: ProviderStatus.active,
    workLocation: LocationSuggestion(id: 'l-poto', city: 'Brazzaville', district: 'Poto-Poto'),
    completionRate: 96,
    rating: 4.7,
    reviewCount: 52,
  );

  late List<AppNotification> _notifications = [
    AppNotification(
      id: 'n1',
      content: 'Nouvelle commande reçue (#1024)',
      read: false,
      createdAt: DateTime.now().subtract(const Duration(hours: 1)),
    ),
    AppNotification(
      id: 'n2',
      content: 'Votre profil a été vu 14 fois cette semaine',
      read: true,
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
    ),
  ];

  bool _activated = false;

  Future<void> _latency() => Future<void>.delayed(const Duration(milliseconds: 250));

  // ProviderRepository
  @override
  Future<void> activate(ProviderActivation activation) async {
    await _latency();
    _activated = true;
  }

  @override
  Future<ProviderProfile> fetchProfile() async {
    await _latency();
    return _profile;
  }

  @override
  Future<ProviderProfile> updateProfile(ProfileChanges changes) async {
    await _latency();
    final v = changes.values;
    final p = _profile;
    _profile = ProviderProfile(
      businessName: (v['businessName'] as String?) ?? p.businessName,
      description: v.containsKey('description') ? (v['description'] as String?) ?? '' : p.description,
      level: p.level,
      status: p.status,
      portfolioUrl: v.containsKey('portfolioUrl') ? v['portfolioUrl'] as String? : p.portfolioUrl,
      videoUrl: v.containsKey('videoUrl') ? v['videoUrl'] as String? : p.videoUrl,
      workLocation: v.containsKey('workLocationId')
          ? LocationSuggestion(id: v['workLocationId'] as String, city: 'Brazzaville')
          : p.workLocation,
      completionRate: p.completionRate,
      rating: p.rating,
      reviewCount: p.reviewCount,
    );
    return _profile;
  }

  @override
  Future<List<VerificationRecord>> fetchVerifications() async {
    await _latency();
    return const [
      VerificationRecord(id: 'v1', type: VerificationType.phone, state: ValidationState.validated),
    ];
  }

  // AccountRepository
  @override
  Future<AccountSummary> fetchMe() async {
    await _latency();
    return AccountSummary(
      displayName: 'Jean M.',
      providerStatus: (providerActive || _activated) ? ProviderStatus.active : ProviderStatus.unknown,
    );
  }

  // OrderRepository
  @override
  Future<OrderPage> listMine({
    required String role,
    TransactionStatus? status,
    int limit = 20,
  }) async {
    await _latency();
    const all = [
      OrderSummary(id: 't1', reference: '#1024', title: 'Création de site vitrine',
          status: TransactionStatus.pending, counterpartName: 'Marie L.'),
      OrderSummary(id: 't2', reference: '#1021', title: "Réparation de fuite d'eau",
          status: TransactionStatus.inProgress, counterpartName: 'Paul T.'),
      OrderSummary(id: 't3', reference: '#1018', title: 'Cours de soutien en maths',
          status: TransactionStatus.accepted, counterpartName: 'Awa N.'),
      OrderSummary(id: 't4', reference: '#1015', title: 'Dépannage informatique',
          status: TransactionStatus.completed, counterpartName: 'Luc B.'),
    ];
    final filtered = status == null ? all : all.where((o) => o.status == status).toList();
    return OrderPage(items: filtered.take(limit).toList());
  }

  // RequestFeedRepository
  @override
  Future<Count> countOpenRequests() async {
    await _latency();
    return const Count(12);
  }

  // NotificationRepository
  @override
  Future<List<AppNotification>> list({bool? unreadOnly, int limit = 20}) async {
    await _latency();
    return _notifications.where((n) => unreadOnly != true || !n.read).take(limit).toList();
  }

  @override
  Future<int> unreadCount() async => _notifications.where((n) => !n.read).length;

  @override
  Future<void> markRead(String id) async {
    _notifications = [for (final n in _notifications) n.id == id ? n.asRead() : n];
  }

  @override
  Future<void> markAllRead() async {
    _notifications = [for (final n in _notifications) n.asRead()];
  }
}

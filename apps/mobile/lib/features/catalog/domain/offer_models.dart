import '../../../core/format/money.dart';
import 'enums.dart';

/// Provider part of an EP-035 item. Field names are assumptions listed in
/// docs/open-points.md (OP-19) until the schema is fixed at S2 coding.
class ProviderSummary {
  const ProviderSummary({
    required this.id,
    required this.businessName,
    required this.level,
    this.rating,
    this.reviewCount = 0,
    this.city,
    this.quartier,
    this.completionRate,
    this.avatarUrl,
  });

  final String id;
  final String businessName;
  final VerificationLevel level;
  final double? rating;
  final int reviewCount;
  final String? city;
  final String? quartier;

  /// Derived attribute "tauxAchevement", a percentage from 0 to 100 (data
  /// dictionary). Its meaning (completed services vs profile completeness) is
  /// ambiguous: OP-24.
  final double? completionRate;
  final String? avatarUrl;

  /// "Dakar, Plateau" / "Plateau" / "Dakar" / null. Quartier level only:
  /// the precise home is never exposed (contract, "Visibilité").
  String? get locationLabel {
    final parts = [city, quartier].whereType<String>().where((s) => s.isNotEmpty);
    return parts.isEmpty ? null : parts.join(', ');
  }

  factory ProviderSummary.fromJson(Map<String, dynamic> j) => ProviderSummary(
        id: j['id'] as String,
        businessName: (j['businessName'] as String?) ?? '',
        level: VerificationLevel.parse(j['level']),
        rating: (j['rating'] as num?)?.toDouble(),
        reviewCount: (j['reviewCount'] as num?)?.toInt() ?? 0,
        city: j['city'] as String?,
        quartier: j['quartier'] as String?,
        completionRate: (j['completionRate'] as num?)?.toDouble(),
        avatarUrl: j['avatarUrl'] as String?,
      );
}

/// Offer part of an EP-035 item.
class OfferSummary {
  const OfferSummary({
    required this.id,
    required this.title,
    required this.pricingMode,
    required this.modality,
    this.categoryName,
    this.price,
    this.photoUrl,
  });

  final String id;
  final String title;
  final String? categoryName;
  final Money? price;
  final PricingMode pricingMode;
  final Modality modality;

  /// Short-lived signed link (files are private by default, EP-114).
  final String? photoUrl;

  factory OfferSummary.fromJson(Map<String, dynamic> j) => OfferSummary(
        id: j['id'] as String,
        title: (j['title'] as String?) ?? '',
        categoryName: j['categoryName'] as String?,
        price: Money.tryParse(j['price']),
        pricingMode: PricingMode.parse(j['pricingMode']),
        modality: Modality.parse(j['modality']),
        photoUrl: j['photoUrl'] as String?,
      );
}

class OfferSearchItem {
  const OfferSearchItem({required this.offer, required this.provider, this.distanceKm});

  final OfferSummary offer;
  final ProviderSummary provider;
  final double? distanceKm;

  factory OfferSearchItem.fromJson(Map<String, dynamic> j) => OfferSearchItem(
        offer: OfferSummary.fromJson(j['offer'] as Map<String, dynamic>),
        provider: ProviderSummary.fromJson(j['provider'] as Map<String, dynamic>),
        distanceKm: (j['distanceKm'] as num?)?.toDouble(),
      );
}

/// `{items, nextCursor}` (cursor pagination, contract "Pagination").
class OfferSearchPage {
  const OfferSearchPage({required this.items, this.nextCursor});

  final List<OfferSearchItem> items;
  final String? nextCursor;

  factory OfferSearchPage.fromJson(Map<String, dynamic> j) => OfferSearchPage(
        items: [
          for (final e in (j['items'] as List? ?? const []))
            OfferSearchItem.fromJson(e as Map<String, dynamic>),
        ],
        nextCursor: j['nextCursor'] as String?,
      );
}

/// Node of the EP-021 category tree (assumption OP-17: `{id, name, children[]}`).
class CategoryNode {
  const CategoryNode({required this.id, required this.name, this.children = const []});

  final String id;
  final String name;
  final List<CategoryNode> children;

  factory CategoryNode.fromJson(Map<String, dynamic> j) => CategoryNode(
        id: j['id'] as String,
        name: (j['name'] as String?) ?? '',
        children: [
          for (final c in (j['children'] as List? ?? const []))
            CategoryNode.fromJson(c as Map<String, dynamic>),
        ],
      );

  /// Depth-first list with depth, for an indented picker.
  static List<(CategoryNode, int)> flatten(List<CategoryNode> roots, [int depth = 0]) => [
        for (final n in roots) ...[
          (n, depth),
          ...flatten(n.children, depth + 1),
        ],
      ];
}

/// Suggestion of EP-023 (assumption OP-19: `{id, city, district?}`).
class LocationSuggestion {
  const LocationSuggestion({required this.id, required this.city, this.district});

  final String id;
  final String city;
  final String? district;

  String get label => (district == null || district!.isEmpty) ? city : '$city, $district';

  factory LocationSuggestion.fromJson(Map<String, dynamic> j) => LocationSuggestion(
        id: j['id'] as String,
        city: (j['city'] as String?) ?? '',
        district: j['district'] as String?,
      );
}

/// Article of a sale offer (EP-031/EP-037). Stock is not managed (D13):
/// an article is available or not.
class OfferItem {
  const OfferItem({
    required this.id,
    required this.designation,
    required this.available,
    this.price,
  });

  final String id;
  final String designation;
  final Money? price;
  final bool available;

  factory OfferItem.fromJson(Map<String, dynamic> j) => OfferItem(
        id: j['id'] as String,
        designation: (j['designation'] as String?) ?? '',
        price: Money.tryParse(j['price']),
        available: (j['available'] as bool?) ?? false,
      );
}

/// Answer of EP-037 `GET /offers/{id}`. Shape assumed in OP-23:
/// `{offer{..., description, photoUrls[]}, provider{...}, items[]}`.
/// `freeSlots` is read by the order task (S3), not here.
class OfferDetail {
  const OfferDetail({
    required this.offer,
    required this.description,
    required this.provider,
    this.photoUrls = const [],
    this.items = const [],
  });

  final OfferSummary offer;
  final String description;
  final ProviderSummary provider;
  final List<String> photoUrls;
  final List<OfferItem> items;

  /// Photos to show: the list, or the single cover photo when only that exists.
  List<String> get gallery =>
      photoUrls.isNotEmpty ? photoUrls : [if (offer.photoUrl != null) offer.photoUrl!];

  factory OfferDetail.fromJson(Map<String, dynamic> j) {
    final o = j['offer'] as Map<String, dynamic>;
    return OfferDetail(
      offer: OfferSummary.fromJson(o),
      description: (o['description'] as String?) ?? '',
      provider: ProviderSummary.fromJson(j['provider'] as Map<String, dynamic>),
      photoUrls: [
        for (final u in (o['photoUrls'] as List? ?? const []))
          if (u is String) u,
      ],
      items: [
        for (final e in (j['items'] as List? ?? const []))
          OfferItem.fromJson(e as Map<String, dynamic>),
      ],
    );
  }
}

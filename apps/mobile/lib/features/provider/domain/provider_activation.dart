/// `ModeCouverture` of a provider profile (data dictionary: Quartier, Ville,
/// Rayon, Pays; default Ville). The wire values are the dictionary's (OP-41).
enum CoverageMode {
  neighborhood('Quartier'),
  city('Ville'),
  radius('Rayon'),
  country('Pays'),
  unknown('');

  const CoverageMode(this.wire);
  final String wire;

  static CoverageMode parse(Object? v) => switch (v) {
        'Quartier' => CoverageMode.neighborhood,
        'Ville' => CoverageMode.city,
        'Rayon' => CoverageMode.radius,
        'Pays' => CoverageMode.country,
        _ => CoverageMode.unknown,
      };

  /// The modes a user can pick (never [unknown]).
  static const selectable = [neighborhood, city, radius, country];
}

/// Body of EP-011 `POST /users/me/provider`.
class ProviderActivation {
  const ProviderActivation({
    required this.businessName,
    required this.workLocationId,
    required this.coverageMode,
    required this.categoryIds,
    this.radiusKm,
  });

  final String businessName;
  final String workLocationId;
  final CoverageMode coverageMode;

  /// Only sent in the [CoverageMode.radius] mode (1 to 500).
  final int? radiusKm;

  /// 1 to 5 domains.
  final List<String> categoryIds;

  Map<String, Object?> toJson() => {
        'businessName': businessName.trim(),
        'workLocationId': workLocationId,
        'coverageMode': coverageMode.wire,
        if (coverageMode == CoverageMode.radius && radiusKm != null) 'radiusKm': radiusKm,
        'categoryIds': categoryIds,
      };
}

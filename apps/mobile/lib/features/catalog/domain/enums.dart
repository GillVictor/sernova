/// Enumerations from docs/reference/data-dictionary.xlsx. The contract says
/// clients must tolerate unknown values, so each parser falls back to `unknown`.

enum PricingMode {
  fixed,
  hourly,
  onQuote,
  unknown;

  static PricingMode parse(Object? v) => switch (v) {
        'Fixe' => PricingMode.fixed,
        'Horaire' => PricingMode.hourly,
        'SurDevis' => PricingMode.onQuote,
        _ => PricingMode.unknown,
      };
}

enum Modality {
  remote,
  atHome,
  onSite,
  unknown;

  static Modality parse(Object? v) => switch (v) {
        'ADistance' => Modality.remote,
        'ADomicile' => Modality.atHome,
        'EnLocal' => Modality.onSite,
        _ => Modality.unknown,
      };
}

/// Verification level N0..N3 (D20).
enum VerificationLevel {
  n0,
  n1,
  n2,
  n3,
  unknown;

  static VerificationLevel parse(Object? v) => switch (v) {
        'N0' => VerificationLevel.n0,
        'N1' => VerificationLevel.n1,
        'N2' => VerificationLevel.n2,
        'N3' => VerificationLevel.n3,
        _ => VerificationLevel.unknown,
      };

  /// Assumption OP-21: the "Vérifié" badge starts at N2 (identity verified).
  bool get showsVerifiedBadge => this == n2 || this == n3;
}

/// `sort` values of EP-035.
enum OfferSort {
  distance,
  rating,
  price;
}

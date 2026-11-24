import '../../catalog/domain/enums.dart';
import '../../catalog/domain/offer_models.dart';

enum ProviderStatus {
  draft,
  active,
  suspended,
  unknown;

  static ProviderStatus parse(Object? v) => switch (v) {
        'Brouillon' => ProviderStatus.draft,
        'Actif' => ProviderStatus.active,
        'Suspendu' => ProviderStatus.suspended,
        _ => ProviderStatus.unknown,
      };
}

enum VerificationType {
  phone,
  identity,
  activity,
  other,
  unknown;

  static VerificationType parse(Object? v) => switch (v) {
        'Telephone' => VerificationType.phone,
        'Identite' => VerificationType.identity,
        'Activite' => VerificationType.activity,
        'Autre' => VerificationType.other,
        _ => VerificationType.unknown,
      };
}

/// `EtatValidation` of a verification request.
enum ValidationState {
  pending,
  validated,
  rejected,
  unknown;

  static ValidationState parse(Object? v) => switch (v) {
        'EnAttente' => ValidationState.pending,
        'Validee' => ValidationState.validated,
        'Rejetee' => ValidationState.rejected,
        _ => ValidationState.unknown,
      };
}

/// EP-014 `providerProfile` (complete, own profile). Field names are
/// assumptions (OP-25) until the schema is fixed at S1-T8.
class ProviderProfile {
  const ProviderProfile({
    required this.businessName,
    required this.level,
    required this.status,
    this.description = '',
    this.portfolioUrl,
    this.videoUrl,
    this.workLocation,
    this.completionRate,
    this.rating,
    this.reviewCount = 0,
  });

  final String businessName;
  final String description;
  final VerificationLevel level;
  final ProviderStatus status;
  final String? portfolioUrl;
  final String? videoUrl;
  final LocationSuggestion? workLocation;

  /// Percentage 0..100 (OP-24 on its meaning).
  final double? completionRate;
  final double? rating;
  final int reviewCount;

  factory ProviderProfile.fromJson(Map<String, dynamic> j) {
    final wl = j['workLocation'];
    return ProviderProfile(
      businessName: (j['businessName'] as String?) ?? '',
      description: (j['description'] as String?) ?? '',
      level: VerificationLevel.parse(j['level']),
      status: ProviderStatus.parse(j['status']),
      portfolioUrl: j['portfolioUrl'] as String?,
      videoUrl: j['videoUrl'] as String?,
      workLocation: wl is Map<String, dynamic> ? LocationSuggestion.fromJson(wl) : null,
      completionRate: (j['completionRate'] as num?)?.toDouble(),
      rating: (j['rating'] as num?)?.toDouble(),
      reviewCount: (j['reviewCount'] as num?)?.toInt() ?? 0,
    );
  }
}

/// EP-018 `verification` (assumed `{id, type, status, rejectionReason?}`).
class VerificationRecord {
  const VerificationRecord({
    required this.id,
    required this.type,
    required this.state,
    this.rejectionReason,
  });

  final String id;
  final VerificationType type;
  final ValidationState state;
  final String? rejectionReason;

  factory VerificationRecord.fromJson(Map<String, dynamic> j) => VerificationRecord(
        id: j['id'] as String,
        type: VerificationType.parse(j['type']),
        state: ValidationState.parse(j['status']),
        rejectionReason: j['rejectionReason'] as String?,
      );
}

/// Fields of EP-015 that changed. Keys are contract names; a cleared optional
/// field is sent as `null` (assumption OP-25).
class ProfileChanges {
  const ProfileChanges(this.values);
  final Map<String, Object?> values;
  bool get isEmpty => values.isEmpty;
}

/// What the form currently holds.
class ProfileDraft {
  const ProfileDraft({
    required this.businessName,
    required this.description,
    required this.portfolioUrl,
    required this.videoUrl,
    required this.workLocation,
  });

  final String businessName;
  final String description;
  final String portfolioUrl;
  final String videoUrl;
  final LocationSuggestion? workLocation;
}

/// Limits from the data dictionary (ProfilPrestataire).
class ProfileLimits {
  ProfileLimits._();
  static const businessName = 80;
  static const description = 1000;
  static const url = 300;
}

/// Only http(s) links with a host are accepted (no javascript:, file:, etc.).
bool isHttpUrl(String v) {
  final u = Uri.tryParse(v);
  return u != null && (u.scheme == 'https' || u.scheme == 'http') && u.host.isNotEmpty;
}

/// Local validation mirroring the server rules. Returns field -> key under
/// `provider.profile.validation`. The server stays the authority.
Map<String, String> validateProfileDraft(ProfileDraft d) {
  final errors = <String, String>{};
  final name = d.businessName.trim();
  if (name.isEmpty) {
    errors['businessName'] = 'required';
  } else if (name.length > ProfileLimits.businessName) {
    errors['businessName'] = 'tooLong';
  }
  if (d.description.trim().length > ProfileLimits.description) {
    errors['description'] = 'tooLong';
  }
  for (final (field, value) in [('portfolioUrl', d.portfolioUrl), ('videoUrl', d.videoUrl)]) {
    final v = value.trim();
    if (v.isEmpty) continue;
    if (v.length > ProfileLimits.url) {
      errors[field] = 'tooLong';
    } else if (!isHttpUrl(v)) {
      errors[field] = 'url';
    }
  }
  return errors;
}

/// Fields that differ from the saved profile. Empty optional text is sent as
/// null; the location is sent by id.
ProfileChanges diffProfile(ProviderProfile saved, ProfileDraft d) {
  String? orNull(String s) => s.trim().isEmpty ? null : s.trim();
  final m = <String, Object?>{};
  if (d.businessName.trim() != saved.businessName) m['businessName'] = d.businessName.trim();
  if (d.description.trim() != saved.description.trim()) m['description'] = orNull(d.description);
  if (orNull(d.portfolioUrl) != saved.portfolioUrl) m['portfolioUrl'] = orNull(d.portfolioUrl);
  if (orNull(d.videoUrl) != saved.videoUrl) m['videoUrl'] = orNull(d.videoUrl);
  final newLoc = d.workLocation?.id;
  if (newLoc != null && newLoc != saved.workLocation?.id) m['workLocationId'] = newLoc;
  return ProfileChanges(m);
}

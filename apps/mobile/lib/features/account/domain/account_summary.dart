import '../../provider/domain/provider_models.dart';

/// EP-009 `{user, capacities, providerStatus}` (assumed `user.displayName`).
class AccountSummary {
  const AccountSummary({required this.displayName, required this.providerStatus});

  final String displayName;
  final ProviderStatus providerStatus;

  /// "JM" for "Jean M." (avatar fallback; there is no avatar route).
  String get initials {
    final parts = displayName.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    String first(String s) => String.fromCharCode(s.runes.first).toUpperCase();
    return parts.length == 1 ? first(parts[0]) : first(parts[0]) + first(parts[1]);
  }

  factory AccountSummary.fromJson(Map<String, dynamic> j) {
    final user = j['user'];
    return AccountSummary(
      displayName: (user is Map<String, dynamic> ? user['displayName'] as String? : null) ?? '',
      providerStatus: ProviderStatus.parse(j['providerStatus']),
    );
  }
}

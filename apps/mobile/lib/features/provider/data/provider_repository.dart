import '../../../core/api/api_client.dart';
import '../../../core/api/parse.dart';
import '../../../core/api/routes.dart';
import '../domain/provider_models.dart';

/// Own professional profile (UC02). Authenticated, role Prestataire.
abstract class ProviderRepository {
  /// EP-014 `GET /providers/me`.
  Future<ProviderProfile> fetchProfile();

  /// EP-015 `PATCH /providers/me`: only the changed fields.
  Future<ProviderProfile> updateProfile(ProfileChanges changes);

  /// EP-018 `GET /providers/me/verifications`.
  Future<List<VerificationRecord>> fetchVerifications();
}

class HttpProviderRepository implements ProviderRepository {
  HttpProviderRepository(this._api);
  final ApiClient _api;

  @override
  Future<ProviderProfile> fetchProfile() async {
    final body = await _api.getJson(ApiRoutes.myProvider);
    return parseBody(() => ProviderProfile.fromJson(body as Map<String, dynamic>));
  }

  @override
  Future<ProviderProfile> updateProfile(ProfileChanges changes) async {
    final body = await _api.patchJson(ApiRoutes.myProvider, body: changes.values);
    return parseBody(() => ProviderProfile.fromJson(body as Map<String, dynamic>));
  }

  @override
  Future<List<VerificationRecord>> fetchVerifications() async {
    final body = await _api.getJson(ApiRoutes.myVerifications);
    return parseBody(() => [
          for (final e in body as List) VerificationRecord.fromJson(e as Map<String, dynamic>),
        ]);
  }
}

/// Where the refresh token lives between app launches.
///
/// Only the refresh token is stored; the access token stays in memory.
/// The production implementation must keep the token in the platform's secure
/// storage (Keychain / Keystore), never in clear text: the package is proposed
/// in decisions.md (D31) and is NOT added yet (D30: every dependency is
/// justified first). Until then the app uses [InMemoryTokenStore].
abstract class TokenStore {
  Future<String?> readRefreshToken();
  Future<void> writeRefreshToken(String token);
  Future<void> clear();
}

/// Keeps the token for the lifetime of the process only: the user signs in
/// again after each launch. Used until D31 is validated, and in tests.
class InMemoryTokenStore implements TokenStore {
  String? _token;

  @override
  Future<String?> readRefreshToken() async => _token;

  @override
  Future<void> writeRefreshToken(String token) async => _token = token;

  @override
  Future<void> clear() async => _token = null;
}

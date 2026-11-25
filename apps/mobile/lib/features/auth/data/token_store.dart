/// Where the refresh token lives between app launches.
///
/// Only the refresh token is stored; the access token stays in memory.
/// Production uses `SecureTokenStore` (platform Keychain / Keystore, D31); the
/// token is never kept in clear text.
abstract class TokenStore {
  Future<String?> readRefreshToken();
  Future<void> writeRefreshToken(String token);
  Future<void> clear();
}

/// Keeps the token for the lifetime of the process only. For tests.
class InMemoryTokenStore implements TokenStore {
  String? _token;

  @override
  Future<String?> readRefreshToken() async => _token;

  @override
  Future<void> writeRefreshToken(String token) async => _token = token;

  @override
  Future<void> clear() async => _token = null;
}

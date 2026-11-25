import '../../../core/api/api_client.dart';
import '../../../core/api/routes.dart';
import '../domain/auth_tokens.dart';

abstract class AuthRepository {
  /// EP-004 `POST /auth/login` (public).
  Future<AuthTokens> login({required String phone, required String password});

  /// EP-005 `POST /auth/refresh` (public, rotation: the old refresh token is
  /// replaced; using it a second time revokes the whole family).
  Future<AuthTokens> refresh(String refreshToken);

  /// EP-006 `POST /auth/logout` (authenticated), 204.
  Future<void> logout(String refreshToken);
}

class HttpAuthRepository implements AuthRepository {
  HttpAuthRepository(this._api);
  final ApiClient _api;

  @override
  Future<AuthTokens> login({required String phone, required String password}) async =>
      AuthTokens.fromJson(
        await _api.postJson(ApiRoutes.login, body: {'phone': phone, 'password': password}),
      );

  @override
  Future<AuthTokens> refresh(String refreshToken) async =>
      AuthTokens.fromJson(await _api.postJson(ApiRoutes.refresh, body: {'refreshToken': refreshToken}));

  @override
  Future<void> logout(String refreshToken) async {
    await _api.postJson(ApiRoutes.logout, body: {'refreshToken': refreshToken});
  }
}

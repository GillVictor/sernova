import '../../../core/api/api_client.dart';
import '../../../core/api/routes.dart';
import '../domain/auth_tokens.dart';

abstract class AuthRepository {
  /// EP-001 `POST /auth/register` (public): creates the account, 201, and the
  /// server sends an SMS code. The account stays unverified (level N0).
  Future<void> register({
    required String phone,
    required String password,
    required String displayName,
    required String language,
    required String countryCode,
    String? email,
  });

  /// EP-002 `POST /auth/verify-phone` (public): confirms the number with the
  /// SMS code and returns the tokens (level N0 to N1).
  Future<AuthTokens> verifyPhone({required String phone, required String code});

  /// EP-003 `POST /auth/resend-code` (public), 204. Strictly rate-limited per
  /// number.
  Future<void> resendCode(String phone);

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
  Future<void> register({
    required String phone,
    required String password,
    required String displayName,
    required String language,
    required String countryCode,
    String? email,
  }) async {
    await _api.postJson(ApiRoutes.register, body: {
      'phone': phone,
      'password': password,
      'displayName': displayName,
      'language': language,
      'countryCode': countryCode,
      if (email != null && email.isNotEmpty) 'email': email,
    });
  }

  @override
  Future<AuthTokens> verifyPhone({required String phone, required String code}) async =>
      AuthTokens.fromJson(await _api.postJson(ApiRoutes.verifyPhone, body: {'phone': phone, 'code': code}));

  @override
  Future<void> resendCode(String phone) async {
    await _api.postJson(ApiRoutes.resendCode, body: {'phone': phone});
  }

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

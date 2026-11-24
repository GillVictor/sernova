import '../../../core/api/api_exception.dart';
import '../../../core/api/parse.dart';

/// Body of EP-004 (login), EP-005 (refresh) and EP-002: `{accessToken,
/// refreshToken}`. The mobile reads `refreshToken` from the body (D32).
class AuthTokens {
  const AuthTokens({required this.accessToken, required this.refreshToken});

  final String accessToken;
  final String refreshToken;

  factory AuthTokens.fromJson(Object? body) {
    final tokens = parseBody(() {
      final j = body as Map<String, dynamic>;
      return AuthTokens(
        accessToken: j['accessToken'] as String,
        refreshToken: j['refreshToken'] as String,
      );
    });
    if (tokens.accessToken.isEmpty || tokens.refreshToken.isEmpty) {
      throw const ApiException(status: 200, code: 'UNKNOWN');
    }
    return tokens;
  }

  // Never print tokens (logs, error reports).
  @override
  String toString() => 'AuthTokens(***)';
}

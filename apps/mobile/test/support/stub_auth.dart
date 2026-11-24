import 'package:servnova_mobile/features/auth/data/auth_repository.dart';
import 'package:servnova_mobile/features/auth/data/token_store.dart';
import 'package:servnova_mobile/features/auth/domain/auth_tokens.dart';

/// Scriptable [AuthRepository]. Set [loginError] to make EP-004 fail, replace
/// [refreshHandler] to script EP-005, set [logoutError] to make EP-006 fail.
class StubAuthRepository implements AuthRepository {
  AuthTokens loginTokens = const AuthTokens(accessToken: 'access-1', refreshToken: 'refresh-1');
  Object? loginError;
  Future<AuthTokens> Function(String refreshToken) refreshHandler = (_) async =>
      const AuthTokens(accessToken: 'access-2', refreshToken: 'refresh-2');
  Object? logoutError;
  void Function(String refreshToken)? onLogout;

  final loginCalls = <({String phone, String password})>[];
  final refreshCalls = <String>[];
  final logoutCalls = <String>[];

  @override
  Future<AuthTokens> login({required String phone, required String password}) async {
    loginCalls.add((phone: phone, password: password));
    if (loginError != null) throw loginError!;
    return loginTokens;
  }

  @override
  Future<AuthTokens> refresh(String refreshToken) {
    refreshCalls.add(refreshToken);
    return refreshHandler(refreshToken);
  }

  @override
  Future<void> logout(String refreshToken) async {
    logoutCalls.add(refreshToken);
    onLogout?.call(refreshToken);
    if (logoutError != null) throw logoutError!;
  }
}

/// A [TokenStore] whose write can be made to fail.
class FailingWriteTokenStore extends InMemoryTokenStore {
  @override
  Future<void> writeRefreshToken(String token) async => throw StateError('disk full');
}

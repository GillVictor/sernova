import 'package:servnova_mobile/features/auth/data/auth_repository.dart';
import 'package:servnova_mobile/features/auth/data/token_store.dart';
import 'package:servnova_mobile/features/auth/domain/auth_tokens.dart';

typedef RegisterCall = ({
  String phone,
  String password,
  String displayName,
  String language,
  String countryCode,
  String? email,
});

/// Scriptable [AuthRepository]. Set [loginError] to make EP-004 fail, replace
/// [refreshHandler] to script EP-005, set [logoutError] to make EP-006 fail,
/// [registerError] / [verifyError] / [resendError] for EP-001 / EP-002 / EP-003.
class StubAuthRepository implements AuthRepository {
  AuthTokens loginTokens = const AuthTokens(accessToken: 'access-1', refreshToken: 'refresh-1');
  Object? loginError;
  Future<AuthTokens> Function(String refreshToken) refreshHandler = (_) async =>
      const AuthTokens(accessToken: 'access-2', refreshToken: 'refresh-2');
  Object? logoutError;
  void Function(String refreshToken)? onLogout;

  Object? registerError;
  Future<void>? registerGate;
  AuthTokens verifyTokens = const AuthTokens(accessToken: 'access-v', refreshToken: 'refresh-v');
  Object? verifyError;
  Object? resendError;

  final loginCalls = <({String phone, String password})>[];
  final refreshCalls = <String>[];
  final logoutCalls = <String>[];
  final registerCalls = <RegisterCall>[];
  final verifyCalls = <({String phone, String code})>[];
  final resendCalls = <String>[];

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

  @override
  Future<void> register({
    required String phone,
    required String password,
    required String displayName,
    required String language,
    required String countryCode,
    String? email,
  }) async {
    registerCalls.add((
      phone: phone,
      password: password,
      displayName: displayName,
      language: language,
      countryCode: countryCode,
      email: email,
    ));
    await registerGate;
    if (registerError != null) throw registerError!;
  }

  @override
  Future<AuthTokens> verifyPhone({required String phone, required String code}) async {
    verifyCalls.add((phone: phone, code: code));
    if (verifyError != null) throw verifyError!;
    return verifyTokens;
  }

  @override
  Future<void> resendCode(String phone) async {
    resendCalls.add(phone);
    if (resendError != null) throw resendError!;
  }
}

/// A [TokenStore] whose write can be made to fail.
class FailingWriteTokenStore extends InMemoryTokenStore {
  @override
  Future<void> writeRefreshToken(String token) async => throw StateError('disk full');
}

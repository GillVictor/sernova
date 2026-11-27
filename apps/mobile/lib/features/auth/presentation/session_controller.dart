import 'package:flutter/foundation.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/api/api_failure.dart';
import '../data/auth_repository.dart';
import '../data/token_store.dart';
import '../domain/auth_tokens.dart';
import '../domain/phone_number.dart';

enum SessionStatus {
  /// The stored session (if any) has not been checked yet.
  restoring,
  signedOut,
  signedIn,
}

/// The signed-in session: EP-004 login, EP-005 renewal with rotation,
/// EP-006 logout.
///
/// - The access token (15 min) lives in memory only; the refresh token goes
///   through the [TokenStore].
/// - Renewal is single-flight: a refresh token used twice revokes the whole
///   family on the server, so concurrent callers must share one call.
/// - The server's answer to a renewal decides: TOKEN_REVOKED / TOKEN_EXPIRED
///   end the session; a network or server failure keeps the stored token so
///   that a later attempt can still succeed.
class SessionController extends ChangeNotifier {
  SessionController({required AuthRepository auth, required TokenStore store})
      : _auth = auth,
        _store = store;

  final AuthRepository _auth;
  final TokenStore _store;

  SessionStatus status = SessionStatus.restoring;

  /// Last failure to show on the login screen (login, or restoring the session).
  ApiFailure? failure;

  /// True while a login or logout call is running.
  bool busy = false;

  String? _accessToken;
  Future<bool>? _refreshing;
  bool _disposed = false;

  /// Bearer token for the API client; null when signed out.
  String? get accessToken => _accessToken;

  /// At start-up: tries to resume a stored session by renewing it.
  Future<void> restore() async {
    String? stored;
    try {
      stored = await _store.readRefreshToken();
    } catch (_) {
      stored = null;
    }
    if (stored == null) {
      _setStatus(SessionStatus.signedOut);
      return;
    }
    await refresh();
  }

  /// EP-004. Returns true when signed in; otherwise [failure] says why.
  Future<bool> login({required String phone, required String password}) async {
    if (busy) return false;
    busy = true;
    failure = null;
    _notify();
    try {
      final tokens = await _auth.login(phone: PhoneNumber.normalize(phone), password: password);
      await signInWith(tokens);
      return true;
    } catch (e) {
      failure = ApiFailure.from(e);
      if (status != SessionStatus.signedIn) status = SessionStatus.signedOut;
      return false;
    } finally {
      busy = false;
      _notify();
    }
  }

  /// Signs in with tokens obtained elsewhere (EP-002, after the phone check).
  Future<void> signInWith(AuthTokens tokens) async {
    _accessToken = tokens.accessToken;
    await _persist(tokens.refreshToken);
    failure = null;
    _setStatus(SessionStatus.signedIn);
  }

  /// EP-005. Renews both tokens. Concurrent callers share one request.
  /// Returns true when the access token was renewed.
  Future<bool> refresh() => _refreshing ??= _renew().whenComplete(() => _refreshing = null);

  Future<bool> _renew() async {
    String? current;
    try {
      current = await _store.readRefreshToken();
    } catch (_) {
      current = null;
    }
    if (current == null) {
      await _endSession();
      return false;
    }
    try {
      final tokens = await _auth.refresh(current);
      _accessToken = tokens.accessToken;
      await _persist(tokens.refreshToken);
      failure = null;
      _setStatus(SessionStatus.signedIn);
      return true;
    } on ApiException catch (e) {
      if (e.status == 401) {
        // Revoked, expired or reused: this token can never work again. Tell the
        // user why they are back on the login screen (only if they were in).
        if (status == SessionStatus.signedIn) failure = ApiFailure.from(e);
        await _endSession();
      } else {
        _keepForLater(ApiFailure.from(e));
      }
      return false;
    } catch (e) {
      _keepForLater(ApiFailure.from(e));
      return false;
    }
  }

  /// EP-006, then forget everything. Signs out locally even if the server
  /// cannot be reached (the refresh token then expires on its own).
  Future<void> logout() async {
    if (busy) return;
    busy = true;
    _notify();
    try {
      String? stored;
      try {
        stored = await _store.readRefreshToken();
      } catch (_) {
        stored = null;
      }
      if (stored != null) {
        try {
          await _auth.logout(stored); // needs the access token still in memory
        } catch (_) {
          // Best effort, see above.
        }
      }
      failure = null; // a voluntary sign-out leaves no error behind
      await _endSession();
    } finally {
      busy = false;
      _notify();
    }
  }

  Future<void> _persist(String refreshToken) async {
    try {
      await _store.writeRefreshToken(refreshToken);
    } catch (_) {
      // Signed in for this run; the next launch will ask for the password.
    }
  }

  /// Transient problem: keep the stored token. While restoring, fall back to
  /// the login screen; an already signed-in session stays as it is.
  void _keepForLater(ApiFailure f) {
    if (status == SessionStatus.restoring) {
      failure = f;
      status = SessionStatus.signedOut;
    }
    _notify();
  }

  Future<void> _endSession() async {
    _accessToken = null;
    try {
      await _store.clear();
    } catch (_) {
      // Nothing more can be done; the in-memory session is gone.
    }
    _setStatus(SessionStatus.signedOut);
  }

  void _setStatus(SessionStatus s) {
    status = s;
    _notify();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}

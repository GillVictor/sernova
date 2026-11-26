import 'package:flutter/foundation.dart';

import '../../../core/api/api_failure.dart';
import '../data/auth_repository.dart';
import '../domain/phone_number.dart';
import 'session_controller.dart';

/// The sign-up flow (UC01): EP-001 register, EP-002 verify the phone with the
/// SMS code, EP-003 resend the code. Registering does not sign the user in;
/// only a successful verification does, through [SessionController.signInWith].
class SignupController extends ChangeNotifier {
  SignupController({
    required AuthRepository auth,
    required SessionController session,
    required this.countryCode,
    this.language = 'fr',
  })  : _auth = auth,
        _session = session;

  final AuthRepository _auth;
  final SessionController _session;

  /// ISO 3166-1 alpha-2, sent with the registration (country of residence).
  final String countryCode;

  /// ISO 639-1, the interface language (the app only has French for now).
  final String language;

  /// True while a request is running; further calls are ignored.
  bool busy = false;

  /// Last failure, to show on the current screen.
  ApiFailure? failure;

  /// True after EP-003 succeeded, until the next action.
  bool codeResent = false;

  bool _disposed = false;

  /// EP-001. Returns true when the account was created and an SMS was sent.
  Future<bool> register({
    required String phone,
    required String password,
    required String displayName,
    String? email,
  }) =>
      _run(() async {
        final mail = email?.trim() ?? '';
        await _auth.register(
          phone: PhoneNumber.normalize(phone),
          password: password,
          displayName: displayName.trim(),
          language: language,
          countryCode: countryCode,
          email: mail.isEmpty ? null : mail,
        );
        return true;
      });

  /// EP-002. Returns true when the number is confirmed and the user is signed in.
  Future<bool> verifyPhone({required String phone, required String code}) => _run(() async {
        final tokens = await _auth.verifyPhone(phone: PhoneNumber.normalize(phone), code: code.trim());
        await _session.signInWith(tokens);
        return true;
      });

  /// EP-003. Returns true when a new code was sent.
  Future<bool> resendCode(String phone) => _run(() async {
        await _auth.resendCode(PhoneNumber.normalize(phone));
        codeResent = true;
        return true;
      });

  /// Forgets the last failure without notifying (called when a screen opens).
  void clearFailure() {
    failure = null;
    codeResent = false;
  }

  Future<bool> _run(Future<bool> Function() action) async {
    if (busy) return false;
    busy = true;
    failure = null;
    codeResent = false;
    _notify();
    try {
      return await action();
    } catch (e) {
      failure = ApiFailure.from(e);
      return false;
    } finally {
      busy = false;
      _notify();
    }
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

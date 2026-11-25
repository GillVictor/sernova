import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'token_store.dart';

/// The three operations the token store needs from the platform keychain.
/// A small seam so the logic below is tested without the plugin.
abstract class SecureKeyValue {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
  Future<void> delete(String key);
}

/// [SecureKeyValue] on `flutter_secure_storage` (iOS Keychain, Android
/// Keystore-backed encryption), D31. Plugin defaults on Android (AES-GCM
/// storage, RSA-OAEP key wrapping). The only code that touches the plugin.
class PlatformSecureKeyValue implements SecureKeyValue {
  PlatformSecureKeyValue({FlutterSecureStorage? storage})
      : _storage = storage ??
            const FlutterSecureStorage(
              // Not restored on another device from a backup.
              iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock_this_device),
            );

  final FlutterSecureStorage _storage;

  @override
  Future<String?> read(String key) => _storage.read(key: key);

  @override
  Future<void> write(String key, String value) => _storage.write(key: key, value: value);

  @override
  Future<void> delete(String key) => _storage.delete(key: key);
}

/// Keeps the refresh token in the platform's secure storage (D31, D32), so the
/// session survives an app restart. Only the refresh token is stored; the
/// access token stays in memory.
class SecureTokenStore implements TokenStore {
  SecureTokenStore([SecureKeyValue? storage]) : _storage = storage ?? PlatformSecureKeyValue();

  /// Single entry, namespaced so nothing else in the keychain is touched.
  static const refreshTokenKey = 'servnova.refreshToken';

  final SecureKeyValue _storage;

  /// An entry that cannot be read (a backup restored without its keystore key,
  /// a reinstalled app) can never work again: it is deleted and the user signs
  /// in with the password. Never throws.
  @override
  Future<String?> readRefreshToken() async {
    try {
      final value = await _storage.read(refreshTokenKey);
      return (value == null || value.isEmpty) ? null : value;
    } catch (_) {
      try {
        await _storage.delete(refreshTokenKey);
      } catch (_) {
        // Nothing more can be done; the next sign-in overwrites the entry.
      }
      return null;
    }
  }

  /// Throws if the token cannot be saved; the session then stays signed in for
  /// this run only (see SessionController).
  @override
  Future<void> writeRefreshToken(String token) => _storage.write(refreshTokenKey, token);

  @override
  Future<void> clear() => _storage.delete(refreshTokenKey);

  // Never print tokens (logs, error reports).
  @override
  String toString() => 'SecureTokenStore(***)';
}

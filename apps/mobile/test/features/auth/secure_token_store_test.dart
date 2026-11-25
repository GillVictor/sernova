import 'package:flutter_test/flutter_test.dart';
import 'package:servnova_mobile/features/auth/data/secure_token_store.dart';

/// In-memory stand-in for the platform keychain, with switchable failures.
class FakeSecureKeyValue implements SecureKeyValue {
  final values = <String, String>{};
  bool failRead = false;
  bool failWrite = false;
  bool failDelete = false;
  final deleted = <String>[];

  @override
  Future<String?> read(String key) async {
    if (failRead) throw StateError('cannot decrypt');
    return values[key];
  }

  @override
  Future<void> write(String key, String value) async {
    if (failWrite) throw StateError('keystore unavailable');
    values[key] = value;
  }

  @override
  Future<void> delete(String key) async {
    deleted.add(key);
    if (failDelete) throw StateError('cannot delete');
    values.remove(key);
  }
}

void main() {
  late FakeSecureKeyValue kv;
  late SecureTokenStore store;

  setUp(() {
    kv = FakeSecureKeyValue();
    store = SecureTokenStore(kv);
  });

  test('nothing stored yet: null', () async {
    expect(await store.readRefreshToken(), isNull);
  });

  test('a written token is read back', () async {
    await store.writeRefreshToken('refresh-1');
    expect(await store.readRefreshToken(), 'refresh-1');
  });

  test('rotation: the new token replaces the old one', () async {
    await store.writeRefreshToken('refresh-1');
    await store.writeRefreshToken('refresh-2');
    expect(await store.readRefreshToken(), 'refresh-2');
    expect(kv.values, hasLength(1));
  });

  test('clear removes the token', () async {
    await store.writeRefreshToken('refresh-1');
    await store.clear();
    expect(await store.readRefreshToken(), isNull);
  });

  test('only one namespaced entry is used, other keys are never touched', () async {
    kv.values['something-else'] = 'keep';
    await store.writeRefreshToken('refresh-1');
    await store.clear();
    expect(kv.values, {'something-else': 'keep'});
    expect(kv.deleted, [SecureTokenStore.refreshTokenKey]);
    expect(SecureTokenStore.refreshTokenKey, startsWith('servnova.'));
  });

  test('an empty stored value counts as no token', () async {
    kv.values[SecureTokenStore.refreshTokenKey] = '';
    expect(await store.readRefreshToken(), isNull);
  });

  group('unreadable storage (restored backup, lost keystore key)', () {
    test('read failure: returns null and drops the unreadable entry', () async {
      await store.writeRefreshToken('refresh-1');
      kv.failRead = true;
      expect(await store.readRefreshToken(), isNull);
      expect(kv.deleted, contains(SecureTokenStore.refreshTokenKey));
      expect(kv.values, isEmpty);
    });

    test('read failure and delete failure: still null, never throws', () async {
      kv.failRead = true;
      kv.failDelete = true;
      expect(await store.readRefreshToken(), isNull);
    });
  });

  test('write failure is reported to the caller (the session keeps working in memory)', () async {
    kv.failWrite = true;
    await expectLater(store.writeRefreshToken('refresh-1'), throwsA(isA<StateError>()));
  });

  test('the token never appears in toString', () async {
    await store.writeRefreshToken('refresh-1');
    expect(store.toString(), isNot(contains('refresh-1')));
  });
}

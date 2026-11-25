import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'app_dependencies.dart';
import 'core/api/api_client.dart';
import 'core/api/api_exception.dart';
import 'core/l10n/strings.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/data/auth_repository.dart';
import 'features/auth/data/token_store.dart';
import 'features/auth/presentation/auth_gate.dart';
import 'features/auth/presentation/session_controller.dart';
import 'shell/app_role.dart';
import 'shell/app_shell.dart';

const _apiBaseUrl = String.fromEnvironment('API_BASE_URL');
const _useFakeApi = bool.fromEnvironment('USE_FAKE_API');
const _countryCode = String.fromEnvironment('DEFAULT_COUNTRY_CODE', defaultValue: 'CG');

/// `--dart-define=START=provider` opens the provider dashboard once signed in
/// (development).
const _start = String.fromEnvironment('START', defaultValue: 'search');

/// Development token for authenticated routes; ignored in release builds. When
/// set (debug only) the login screen is skipped. The real session (FR-01) is
/// used otherwise.
const _devAccessToken = String.fromEnvironment('DEV_ACCESS_TOKEN');

/// With `USE_FAKE_API`: `--dart-define=FAKE_PROVIDER_ACTIVE=false` simulates a
/// simple client (no role switch shown).
const _fakeProviderActive = bool.fromEnvironment('FAKE_PROVIDER_ACTIVE', defaultValue: true);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Strings.load();

  AppDependencies? deps;
  SessionController? session;
  try {
    if (_useFakeApi) {
      deps = AppDependencies.fake(providerActive: _fakeProviderActive);
    } else {
      final built = _buildHttp();
      deps = built.deps;
      session = built.session;
    }
  } on ConfigException {
    deps = null;
  }
  // Resume a stored session (the login screen shows a spinner meanwhile).
  if (session != null) unawaited(session.restore());
  runApp(ServNovaApp(deps: deps, session: session));
}

/// Real API. Returns a session unless the debug-only development token is used.
({AppDependencies deps, SessionController? session}) _buildHttp() {
  if (_apiBaseUrl.isEmpty) throw const ConfigException();
  final uri = Uri.parse(_apiBaseUrl);
  // Plain HTTP only for a local backend in debug builds.
  const localHosts = {'localhost', '127.0.0.1', '10.0.2.2'};
  final allowInsecure = !kReleaseMode && localHosts.contains(uri.host);

  if (!kReleaseMode && _devAccessToken.isNotEmpty) {
    final api = ApiClient(
      baseUrl: uri,
      allowInsecure: allowInsecure,
      accessToken: () => _devAccessToken,
    );
    return (deps: AppDependencies.http(api), session: null);
  }

  // The client and the session need each other: the client reads the access
  // token and asks for a renewal on 401; the session calls the auth routes.
  late final SessionController session;
  final api = ApiClient(
    baseUrl: uri,
    allowInsecure: allowInsecure,
    accessToken: () => session.accessToken,
    onUnauthorized: () => session.refresh(),
  );
  // In-memory until the secure storage package (D31) is validated: the user
  // signs in again after each launch.
  session = SessionController(auth: HttpAuthRepository(api), store: InMemoryTokenStore());
  return (deps: AppDependencies.http(api), session: session);
}

class ServNovaApp extends StatelessWidget {
  const ServNovaApp({super.key, required this.deps, this.session});
  final AppDependencies? deps;

  /// Null in fake or development-token mode: the login screen is skipped.
  final SessionController? session;

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: Strings.t('app.name'),
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        home: deps == null
            ? Scaffold(
                body: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Text(Strings.error('CONFIG'), textAlign: TextAlign.center),
                  ),
                ),
              )
            : session == null
                ? _shell(deps!, null)
                : AuthGate(
                    session: session!,
                    signedInBuilder: (_) => _shell(deps!, session),
                  ),
      );

  Widget _shell(AppDependencies deps, SessionController? session) => AppShell(
        deps: deps,
        countryCode: _countryCode,
        preferredRole: _start == 'provider' ? AppRole.provider : AppRole.client,
        onLogout: session == null ? null : () => unawaited(session.logout()),
      );
}

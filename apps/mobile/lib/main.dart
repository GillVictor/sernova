import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'app_dependencies.dart';
import 'core/api/api_client.dart';
import 'core/api/api_exception.dart';
import 'core/l10n/strings.dart';
import 'core/theme/app_theme.dart';
import 'shell/app_role.dart';
import 'shell/app_shell.dart';

const _apiBaseUrl = String.fromEnvironment('API_BASE_URL');
const _useFakeApi = bool.fromEnvironment('USE_FAKE_API');
const _countryCode = String.fromEnvironment('DEFAULT_COUNTRY_CODE', defaultValue: 'CG');

/// `--dart-define=START=provider` opens the provider dashboard (development
/// only, until sign-in and role navigation arrive with FR-01).
const _start = String.fromEnvironment('START', defaultValue: 'search');

/// Development token for authenticated routes; ignored in release builds.
/// FR-01 replaces it with the real session.
const _devAccessToken = String.fromEnvironment('DEV_ACCESS_TOKEN');

/// With `USE_FAKE_API`: `--dart-define=FAKE_PROVIDER_ACTIVE=false` simulates a
/// simple client (no role switch shown).
const _fakeProviderActive = bool.fromEnvironment('FAKE_PROVIDER_ACTIVE', defaultValue: true);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Strings.load();

  AppDependencies? deps;
  try {
    deps = _useFakeApi ? AppDependencies.fake(providerActive: _fakeProviderActive) : AppDependencies.http(_buildClient());
  } on ConfigException {
    deps = null;
  }
  runApp(ServNovaApp(deps: deps));
}

ApiClient _buildClient() {
  if (_apiBaseUrl.isEmpty) throw const ConfigException();
  final uri = Uri.parse(_apiBaseUrl);
  // Plain HTTP only for a local backend in debug builds.
  const localHosts = {'localhost', '127.0.0.1', '10.0.2.2'};
  return ApiClient(
    baseUrl: uri,
    allowInsecure: !kReleaseMode && localHosts.contains(uri.host),
    accessToken: (kReleaseMode || _devAccessToken.isEmpty) ? null : () => _devAccessToken,
  );
}

class ServNovaApp extends StatelessWidget {
  const ServNovaApp({super.key, required this.deps});
  final AppDependencies? deps;

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
            : AppShell(
                deps: deps!,
                countryCode: _countryCode,
                preferredRole: _start == 'provider' ? AppRole.provider : AppRole.client,
              ),
      );
}

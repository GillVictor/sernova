import 'package:flutter/material.dart';

import '../../../core/api/api_failure.dart';
import '../../../core/l10n/strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../catalog/data/catalog_repository.dart';
import '../../provider/data/provider_repository.dart';
import '../../provider/domain/provider_models.dart';
import '../../provider/presentation/become_provider_page.dart';
import '../data/account_repository.dart';
import '../domain/account_summary.dart';

/// "Compte" tab of the client menu. For now: who is signed in and the way to
/// become a provider (EP-011, OP-28 d).
class ClientAccountPage extends StatefulWidget {
  const ClientAccountPage({
    super.key,
    required this.account,
    required this.provider,
    required this.catalog,
    this.countryCode = 'CG',
    this.onProviderActivated,
  });

  final AccountRepository account;
  final ProviderRepository provider;
  final CatalogRepository catalog;
  final String countryCode;

  /// Called once the provider capacity is on (the shell reloads the account).
  final VoidCallback? onProviderActivated;

  @override
  State<ClientAccountPage> createState() => _ClientAccountPageState();
}

class _ClientAccountPageState extends State<ClientAccountPage> {
  AccountSummary? _me;
  ApiFailure? _failure;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _failure = null;
    });
    try {
      final me = await widget.account.fetchMe();
      if (!mounted) return;
      setState(() {
        _me = me;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _failure = ApiFailure.from(e);
        _loading = false;
      });
    }
  }

  Future<void> _become() async {
    final done = await Navigator.of(context).push<bool>(MaterialPageRoute<bool>(
      builder: (_) => BecomeProviderPage(
        provider: widget.provider,
        catalog: widget.catalog,
        countryCode: widget.countryCode,
        onActivated: widget.onProviderActivated,
      ),
    ));
    if (done == true && mounted) await _load();
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final me = _me;
    return Scaffold(
      appBar: AppBar(title: Text(Strings.t('account.title'))),
      body: _loading
          ? Center(
              child: Semantics(
                label: Strings.t('common.loading'),
                child: const CircularProgressIndicator(),
              ),
            )
          : _failure != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      Text(
                        Strings.error(_failure!.code, retryAfterSeconds: _failure!.retryAfterSeconds),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton(onPressed: _load, child: Text(Strings.t('common.retry'))),
                    ]),
                  ),
                )
              : ListView(padding: const EdgeInsets.all(16), children: [
                  if (me != null && me.displayName.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Text(
                        me.displayName,
                        style: t.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                      ),
                    ),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(
                          Strings.t('account.provider.title'),
                          style: t.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 8),
                        if (me?.providerStatus == ProviderStatus.active)
                          Text(
                            Strings.t('account.provider.active'),
                            key: const Key('account-provider-active'),
                            style: t.bodyMedium?.copyWith(color: AppColors.muted),
                          )
                        else ...[
                          Text(
                            Strings.t('account.provider.intro'),
                            style: t.bodyMedium?.copyWith(color: AppColors.muted),
                          ),
                          const SizedBox(height: 12),
                          FilledButton(
                            key: const Key('account-become-provider'),
                            onPressed: _become,
                            child: Text(Strings.t('account.provider.cta')),
                          ),
                        ],
                      ]),
                    ),
                  ),
                ]),
    );
  }
}

import 'package:flutter/material.dart';

import '../../../core/l10n/strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/field_label.dart';
import '../../../shared/widgets/location_picker_sheet.dart';
import '../../../shared/widgets/sheet_result.dart';
import '../../account/data/account_repository.dart';
import '../../catalog/data/catalog_repository.dart';
import '../../catalog/domain/enums.dart';
import '../../catalog/domain/offer_models.dart';
import '../data/provider_repository.dart';
import '../domain/provider_models.dart';
import 'profile_controller.dart';
import 'widgets/provider_header.dart';

/// "Mon profil professionnel" (UC02, EP-014/015/018). The location picker uses
/// the public EP-023 through [catalog].
class ProviderProfilePage extends StatefulWidget {
  const ProviderProfilePage({
    super.key,
    required this.provider,
    required this.account,
    required this.catalog,
    this.countryCode = 'CG',
    this.onRequestVerification,
  });

  final ProviderRepository provider;
  final AccountRepository account;
  final CatalogRepository catalog;
  final String countryCode;

  /// Starts a verification (file upload EP-024 + EP-017). Hidden while null:
  /// it needs a file-picker dependency (OP-26).
  final void Function(VerificationType type)? onRequestVerification;

  @override
  State<ProviderProfilePage> createState() => _ProviderProfilePageState();
}

class _ProviderProfilePageState extends State<ProviderProfilePage> {
  late final ProfileController _c =
      ProfileController(provider: widget.provider, account: widget.account);
  final _name = TextEditingController();
  final _description = TextEditingController();
  final _portfolio = TextEditingController();
  final _video = TextEditingController();
  LocationSuggestion? _location;
  bool _filled = false;

  @override
  void initState() {
    super.initState();
    _c.addListener(_fillOnce);
    _c.load();
  }

  /// Copies the loaded profile into the fields, once.
  void _fillOnce() {
    final p = _c.profile;
    if (_filled || p == null) return;
    _filled = true;
    _name.text = p.businessName;
    _description.text = p.description;
    _portfolio.text = p.portfolioUrl ?? '';
    _video.text = p.videoUrl ?? '';
    setState(() => _location = p.workLocation);
  }

  @override
  void dispose() {
    _c.removeListener(_fillOnce);
    _c.dispose();
    _name.dispose();
    _description.dispose();
    _portfolio.dispose();
    _video.dispose();
    super.dispose();
  }

  Future<void> _pickLocation() async {
    final r = await showModalBottomSheet<SheetResult<LocationSuggestion>>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => LocationPickerSheet(
        title: Strings.t('provider.profile.fields.location.sheetTitle'),
        help: Strings.t('provider.profile.fields.location.help'),
        searchHelp: Strings.t('provider.profile.fields.location.searchHelp'),
        placeholder: Strings.t('provider.profile.fields.location.placeholder'),
        emptyLabel: Strings.t('provider.profile.fields.location.empty'),
        selectedId: _location?.id,
        search: (q) => widget.catalog.searchLocations(countryCode: widget.countryCode, q: q),
      ),
    );
    final picked = r?.value;
    if (picked != null) setState(() => _location = picked);
  }

  Future<void> _save() async {
    final messenger = ScaffoldMessenger.of(context);
    final ok = await _c.save(ProfileDraft(
      businessName: _name.text,
      description: _description.text,
      portfolioUrl: _portfolio.text,
      videoUrl: _video.text,
      workLocation: _location,
    ));
    if (!mounted || !ok) return;
    messenger.showSnackBar(SnackBar(
      content: Text(Strings.t(_c.nothingToSave
          ? 'provider.profile.nothingToSave'
          : 'provider.profile.saved')),
    ));
  }

  String? _issue(String field) {
    final i = _c.issues[field];
    if (i == null) return null;
    return i.local
        ? Strings.t('provider.profile.validation.${i.key}')
        : Strings.error(i.key);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListenableBuilder(
          listenable: _c,
          builder: (context, _) => Column(children: [
            ProviderHeader(initials: _c.account?.initials ?? ''),
            const Divider(height: 1, color: AppColors.border),
            Expanded(child: _body(context)),
          ]),
        ),
      ),
    );
  }

  Widget _body(BuildContext context) {
    final t = Theme.of(context).textTheme;
    switch (_c.status) {
      case ProfileStatus.loading:
        return const Center(child: CircularProgressIndicator());
      case ProfileStatus.error:
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Text(
                Strings.error(_c.failure?.code ?? 'UNKNOWN',
                    retryAfterSeconds: _c.failure?.retryAfterSeconds),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              FilledButton(onPressed: _c.load, child: Text(Strings.t('common.retry'))),
            ]),
          ),
        );
      case ProfileStatus.ready:
        break;
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
      children: [
        Text(Strings.t('provider.profile.title'),
            style: t.headlineMedium?.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(
            child: Text(Strings.t('provider.profile.subtitle'),
                style: t.bodyLarge?.copyWith(color: AppColors.muted)),
          ),
          const SizedBox(width: 8),
          Flexible(child: RoleChip(displayName: _c.account?.displayName)),
        ]),
        const SizedBox(height: 20),
        _card(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(
                child: Text(Strings.t('provider.profile.publicTitle'),
                    style: t.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                    color: AppColors.tint, borderRadius: BorderRadius.circular(12)),
                child: Text(Strings.t('provider.profile.publicBadge'),
                    style: t.labelMedium
                        ?.copyWith(color: AppColors.primary, fontWeight: FontWeight.w800)),
              ),
            ]),
            const SizedBox(height: 16),
            FieldLabel(
              label: Strings.t('provider.profile.fields.businessName.label'),
              help: Strings.t('provider.profile.fields.businessName.help'),
            ),
            TextField(
              controller: _name,
              maxLength: ProfileLimits.businessName,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(errorText: _issue('businessName')),
            ),
            const SizedBox(height: 8),
            FieldLabel(
              label: Strings.t('provider.profile.fields.description.label'),
              help: Strings.t('provider.profile.fields.description.help'),
            ),
            TextField(
              controller: _description,
              maxLines: 4,
              maxLength: ProfileLimits.description,
              decoration: InputDecoration(errorText: _issue('description')),
            ),
            const SizedBox(height: 8),
            FieldLabel(
              label: Strings.t('provider.profile.fields.location.label'),
              help: Strings.t('provider.profile.fields.location.help'),
            ),
            const SizedBox(height: 6),
            InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: _pickLocation,
              child: InputDecorator(
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.place_outlined),
                  suffixIcon: const Icon(Icons.keyboard_arrow_down),
                  errorText: _issue('workLocation'),
                ),
                child: Text(
                  _location?.label ??
                      Strings.t('provider.profile.fields.location.placeholder'),
                  style: TextStyle(
                      color: _location == null ? AppColors.muted : AppColors.ink),
                ),
              ),
            ),
            const SizedBox(height: 16),
            FieldLabel(
              label: Strings.t('provider.profile.fields.portfolioUrl.label'),
              help: Strings.t('provider.profile.fields.portfolioUrl.help'),
              optional: true,
            ),
            TextField(
              controller: _portfolio,
              keyboardType: TextInputType.url,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                hintText: Strings.t('provider.profile.fields.portfolioUrl.placeholder'),
                errorText: _issue('portfolioUrl'),
              ),
            ),
            const SizedBox(height: 16),
            FieldLabel(
              label: Strings.t('provider.profile.fields.videoUrl.label'),
              help: Strings.t('provider.profile.fields.videoUrl.help'),
              optional: true,
            ),
            TextField(
              controller: _video,
              keyboardType: TextInputType.url,
              decoration: InputDecoration(
                hintText: Strings.t('provider.profile.fields.videoUrl.placeholder'),
                errorText: _issue('videoUrl'),
              ),
            ),
            const SizedBox(height: 20),
            if (_c.saveFailure != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  Strings.error(_c.saveFailure!.code,
                      retryAfterSeconds: _c.saveFailure!.retryAfterSeconds),
                  style: const TextStyle(color: AppColors.danger),
                ),
              ),
            FilledButton(
              style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(60)),
              onPressed: _c.saving ? null : _save,
              child: _c.saving
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Text(Strings.t('provider.profile.save')),
            ),
          ]),
        ),
        const SizedBox(height: 20),
        _VerificationCard(c: _c, onRequest: widget.onRequestVerification),
      ],
    );
  }

  Widget _card({required Widget child}) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: AppColors.border),
        ),
        child: child,
      );
}

String verificationLevelLabel(VerificationLevel l) => Strings.t(switch (l) {
      VerificationLevel.n0 => 'provider.profile.verification.levels.n0',
      VerificationLevel.n1 => 'provider.profile.verification.levels.n1',
      VerificationLevel.n2 => 'provider.profile.verification.levels.n2',
      VerificationLevel.n3 => 'provider.profile.verification.levels.n3',
      VerificationLevel.unknown => 'provider.profile.verification.levels.unknown',
    });

class _VerificationCard extends StatelessWidget {
  const _VerificationCard({required this.c, this.onRequest});
  final ProfileController c;
  final void Function(VerificationType)? onRequest;

  /// State of a row: the latest record of that type; the phone counts as
  /// validated from level N1 (EP-002 raises the level at phone confirmation).
  ValidationState? _state(VerificationType type) {
    final records = c.verifications.where((v) => v.type == type).toList();
    if (records.isNotEmpty) return records.last.state;
    final level = c.profile?.level ?? VerificationLevel.unknown;
    if (type == VerificationType.phone &&
        (level == VerificationLevel.n1 ||
            level == VerificationLevel.n2 ||
            level == VerificationLevel.n3)) {
      return ValidationState.validated;
    }
    return null;
  }

  String? _reason(VerificationType type) {
    final r = c.verifications.where((v) => v.type == type).toList();
    return r.isEmpty ? null : r.last.rejectionReason;
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final level = c.profile?.level ?? VerificationLevel.unknown;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(
            child: Text(Strings.t('provider.profile.verification.title'),
                style: t.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.tint,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFB9CCF4)),
            ),
            child: Text(
              Strings.t('provider.profile.verification.levelChip',
                  params: {'name': verificationLevelLabel(level)}),
              style: t.titleSmall?.copyWith(color: AppColors.primary, fontWeight: FontWeight.w700),
            ),
          ),
        ]),
        const SizedBox(height: 12),
        if (c.verificationsFailed)
          Text(Strings.t('provider.profile.verification.loadFailed'),
              style: const TextStyle(color: AppColors.muted)),
        for (final type in const [
          VerificationType.phone,
          VerificationType.identity,
          VerificationType.activity,
        ])
          _VerificationRow(
            type: type,
            state: _state(type),
            reason: _reason(type),
            onRequest: onRequest,
          ),
      ]),
    );
  }
}

class _VerificationRow extends StatelessWidget {
  const _VerificationRow({required this.type, required this.state, this.reason, this.onRequest});
  final VerificationType type;
  final ValidationState? state;
  final String? reason;
  final void Function(VerificationType)? onRequest;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final validated = state == ValidationState.validated;
    final rejected = state == ValidationState.rejected;
    final pending = state == ValidationState.pending;
    final stateKey = validated
        ? 'validated'
        : rejected
            ? 'rejected'
            : pending
                ? 'pending'
                : 'none';
    final color = validated
        ? AppColors.success
        : rejected
            ? AppColors.danger
            : pending
                ? const Color(0xFFB45309)
                : AppColors.muted;
    final canRequest = onRequest != null &&
        type != VerificationType.phone &&
        !validated &&
        !pending;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(children: [
        validated
            ? const CircleAvatar(
                radius: 22,
                backgroundColor: AppColors.success,
                child: Icon(Icons.check, color: Colors.white),
              )
            : CircleAvatar(
                radius: 22,
                backgroundColor: AppColors.surface,
                child: Icon(
                  pending
                      ? Icons.hourglass_top
                      : rejected
                          ? Icons.error_outline
                          : Icons.radio_button_unchecked,
                  color: color,
                  size: 36,
                ),
              ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(Strings.t('provider.profile.verification.rows.${_rowKey(type)}'),
                style: t.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
            if (rejected && reason != null && reason!.isNotEmpty)
              Text(reason!, style: t.bodySmall?.copyWith(color: AppColors.danger)),
          ]),
        ),
        if (canRequest)
          TextButton(
            onPressed: () => onRequest!(type),
            child: Text(Strings.t('provider.profile.verification.states.$stateKey'),
                style: TextStyle(color: color, fontWeight: FontWeight.w600)),
          )
        else
          Text(Strings.t('provider.profile.verification.states.$stateKey'),
              style: t.titleSmall?.copyWith(color: color, fontWeight: FontWeight.w600)),
      ]),
    );
  }

  String _rowKey(VerificationType t) => switch (t) {
        VerificationType.phone => 'phone',
        VerificationType.identity => 'identity',
        _ => 'activity',
      };
}

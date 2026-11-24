import 'package:flutter/foundation.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/api/api_failure.dart';
import '../../account/data/account_repository.dart';
import '../../account/domain/account_summary.dart';
import '../data/provider_repository.dart';
import '../domain/provider_models.dart';

enum ProfileStatus { loading, ready, error }

/// A problem on one field: a local validation key, or a server error code.
class FieldIssue {
  const FieldIssue.local(this.key) : local = true;
  const FieldIssue.server(this.key) : local = false;
  final String key;
  final bool local;
}

/// State of "Mon profil professionnel" (EP-014, EP-015, EP-018, EP-009).
class ProfileController extends ChangeNotifier {
  ProfileController({required ProviderRepository provider, required AccountRepository account})
      : _provider = provider,
        _account = account;

  final ProviderRepository _provider;
  final AccountRepository _account;

  ProfileStatus status = ProfileStatus.loading;
  ProviderProfile? profile;
  List<VerificationRecord> verifications = const [];
  bool verificationsFailed = false;
  AccountSummary? account;
  ApiFailure? failure;

  bool saving = false;
  bool justSaved = false;
  bool nothingToSave = false;
  Map<String, FieldIssue> issues = const {};
  ApiFailure? saveFailure;

  bool _disposed = false;

  Future<void> load() async {
    status = ProfileStatus.loading;
    failure = null;
    _notify();
    try {
      profile = await _provider.fetchProfile();
      status = ProfileStatus.ready;
    } catch (e) {
      failure = ApiFailure.from(e);
      status = ProfileStatus.error;
      _notify();
      return;
    }
    _notify(); // show the form first, the rest completes it
    await Future.wait([_loadVerifications(), _loadAccount()]);
  }

  Future<void> _loadVerifications() async {
    try {
      verifications = await _provider.fetchVerifications();
      verificationsFailed = false;
    } catch (_) {
      verificationsFailed = true;
    }
    _notify();
  }

  Future<void> _loadAccount() async {
    try {
      account = await _account.fetchMe();
    } catch (_) {
      // The role chip simply falls back to "Prestataire".
    }
    _notify();
  }

  /// Validates, sends only the changed fields. Returns true when saved
  /// (or when nothing changed).
  Future<bool> save(ProfileDraft draft) async {
    final saved = profile;
    if (saved == null || saving) return false;
    justSaved = false;
    nothingToSave = false;
    saveFailure = null;

    final local = validateProfileDraft(draft);
    if (local.isNotEmpty) {
      issues = {for (final e in local.entries) e.key: FieldIssue.local(e.value)};
      _notify();
      return false;
    }
    issues = const {};

    final changes = diffProfile(saved, draft);
    if (changes.isEmpty) {
      nothingToSave = true;
      _notify();
      return true;
    }

    saving = true;
    _notify();
    try {
      profile = await _provider.updateProfile(changes);
      justSaved = true;
      saving = false;
      _notify();
      return true;
    } on ApiException catch (e) {
      final mapped = <String, FieldIssue>{};
      for (final fe in e.fieldErrors) {
        final field = fe.field == 'workLocationId' ? 'workLocation' : fe.field;
        mapped[field] = FieldIssue.server(fe.code);
      }
      if (mapped.isNotEmpty && e.status == 422) {
        issues = mapped;
      } else {
        saveFailure = ApiFailure.from(e);
      }
    } catch (e) {
      saveFailure = ApiFailure.from(e);
    }
    saving = false;
    _notify();
    return false;
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

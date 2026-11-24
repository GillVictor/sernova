import 'package:flutter_test/flutter_test.dart';
import 'package:servnova_mobile/core/api/api_exception.dart';
import 'package:servnova_mobile/features/catalog/domain/offer_models.dart';
import 'package:servnova_mobile/features/provider/domain/provider_models.dart';
import 'package:servnova_mobile/features/provider/presentation/profile_controller.dart';

import '../../support/stub_space.dart';

ProfileController make(StubSpace s) => ProfileController(provider: s, account: s);

ProfileDraft same(ProviderProfile p, {String? description, String? name}) => ProfileDraft(
      businessName: name ?? p.businessName,
      description: description ?? p.description,
      portfolioUrl: p.portfolioUrl ?? '',
      videoUrl: p.videoUrl ?? '',
      workLocation: p.workLocation,
    );

void main() {
  test('load shows the profile, then verifications and the account name', () async {
    final s = StubSpace()
      ..verifications = [
        const VerificationRecord(id: 'v1', type: VerificationType.identity, state: ValidationState.pending),
      ];
    final c = make(s);
    await c.load();

    expect(c.status, ProfileStatus.ready);
    expect(c.profile!.businessName, 'Jean M. – Plomberie');
    expect(c.verifications.single.state, ValidationState.pending);
    expect(c.account!.displayName, 'Jean M.');
    c.dispose();
  });

  test('a profile failure is an error state; a verifications failure is not', () async {
    final bad = StubSpace()..profileError = const ApiException(status: 404, code: 'PROFILE_NOT_FOUND');
    final c1 = make(bad);
    await c1.load();
    expect(c1.status, ProfileStatus.error);
    expect(c1.failure!.code, 'PROFILE_NOT_FOUND');
    c1.dispose();

    final partial = StubSpace()..verificationsError = const NetworkException();
    final c2 = make(partial);
    await c2.load();
    expect(c2.status, ProfileStatus.ready);
    expect(c2.verificationsFailed, isTrue);
    c2.dispose();
  });

  test('invalid draft: field issues, no request', () async {
    final s = StubSpace();
    final c = make(s);
    await c.load();

    final ok = await c.save(same(c.profile!, name: '  '));
    expect(ok, isFalse);
    expect(c.issues['businessName']!.local, isTrue);
    expect(c.issues['businessName']!.key, 'required');
    expect(s.updates, isEmpty);
    c.dispose();
  });

  test('sends only the changed fields and keeps the server answer', () async {
    final s = StubSpace();
    final c = make(s);
    await c.load();

    s.profile = sampleProfile(description: 'Nouvelle description');
    final ok = await c.save(same(c.profile!, description: 'Nouvelle description'));
    expect(ok, isTrue);
    expect(s.updates.single.values, {'description': 'Nouvelle description'});
    expect(c.justSaved, isTrue);
    expect(c.profile!.description, 'Nouvelle description');
    expect(c.saving, isFalse);
    c.dispose();
  });

  test('nothing changed: no request, flagged', () async {
    final s = StubSpace();
    final c = make(s);
    await c.load();
    final ok = await c.save(same(c.profile!));
    expect(ok, isTrue);
    expect(c.nothingToSave, isTrue);
    expect(s.updates, isEmpty);
    c.dispose();
  });

  test('server 422 field errors are attached to the fields', () async {
    final s = StubSpace()
      ..updateError = const ApiException(
        status: 422,
        code: 'VALIDATION_FAILED',
        fieldErrors: [FieldError(field: 'businessName', code: 'VALIDATION_FAILED')],
      );
    final c = make(s);
    await c.load();
    final ok = await c.save(same(c.profile!, name: 'Autre nom'));

    expect(ok, isFalse);
    expect(c.issues['businessName']!.local, isFalse);
    expect(c.issues['businessName']!.key, 'VALIDATION_FAILED');
    expect(c.saveFailure, isNull);
    c.dispose();
  });

  test('other failures are reported as a save failure', () async {
    final s = StubSpace()..updateError = const NetworkException();
    final c = make(s);
    await c.load();
    final ok = await c.save(same(c.profile!, name: 'Autre nom'));

    expect(ok, isFalse);
    expect(c.saveFailure!.code, 'NETWORK');
    expect(c.saving, isFalse);
    c.dispose();
  });

  test('changing the location sends workLocationId', () async {
    final s = StubSpace();
    final c = make(s);
    await c.load();
    final p = c.profile!;
    await c.save(ProfileDraft(
      businessName: p.businessName,
      description: p.description,
      portfolioUrl: '',
      videoUrl: '',
      workLocation: const LocationSuggestion(id: 'l2', city: 'Pointe-Noire'),
    ));
    expect(s.updates.single.values, {'workLocationId': 'l2'});
    c.dispose();
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:servnova_mobile/core/domain/count.dart';
import 'package:servnova_mobile/features/account/domain/account_summary.dart';
import 'package:servnova_mobile/features/catalog/domain/enums.dart';
import 'package:servnova_mobile/features/catalog/domain/offer_models.dart';
import 'package:servnova_mobile/features/orders/domain/order_models.dart';
import 'package:servnova_mobile/features/provider/domain/provider_models.dart';

import '../../support/stub_space.dart';

ProfileDraft draftOf(ProviderProfile p,
        {String? name, String? description, String? portfolio, String? video, LocationSuggestion? location}) =>
    ProfileDraft(
      businessName: name ?? p.businessName,
      description: description ?? p.description,
      portfolioUrl: portfolio ?? p.portfolioUrl ?? '',
      videoUrl: video ?? p.videoUrl ?? '',
      workLocation: location ?? p.workLocation,
    );

void main() {
  group('http(s) links only', () {
    test('accepts https and http with a host', () {
      expect(isHttpUrl('https://youtube.com/watch?v=1'), isTrue);
      expect(isHttpUrl('http://site.cg'), isTrue);
    });
    test('rejects other schemes and hostless values', () {
      for (final bad in ['javascript:alert(1)', 'ftp://x.cg', 'file:///etc/passwd', 'https://', 'site.cg', '']) {
        expect(isHttpUrl(bad), isFalse, reason: bad);
      }
    });
  });

  group('validateProfileDraft', () {
    final p = sampleProfile();

    test('valid draft has no errors', () {
      expect(validateProfileDraft(draftOf(p)), isEmpty);
    });

    test('name required and limited to 80', () {
      expect(validateProfileDraft(draftOf(p, name: '  ')), {'businessName': 'required'});
      expect(validateProfileDraft(draftOf(p, name: 'x' * 81)), {'businessName': 'tooLong'});
      expect(validateProfileDraft(draftOf(p, name: 'x' * 80)), isEmpty);
    });

    test('description limited to 1000', () {
      expect(validateProfileDraft(draftOf(p, description: 'x' * 1001)), {'description': 'tooLong'});
    });

    test('urls must be http(s) and at most 300 characters; empty is allowed', () {
      expect(validateProfileDraft(draftOf(p, portfolio: 'javascript:alert(1)')), {'portfolioUrl': 'url'});
      expect(validateProfileDraft(draftOf(p, video: 'https://${'a' * 300}.cg')), {'videoUrl': 'tooLong'});
      expect(validateProfileDraft(draftOf(p, portfolio: 'https://ok.cg')), isEmpty);
    });
  });

  group('diffProfile', () {
    final saved = sampleProfile(portfolio: 'https://old.cg');

    test('nothing changed', () {
      expect(diffProfile(saved, draftOf(saved)).isEmpty, isTrue);
    });

    test('only changed fields, trimmed', () {
      final c = diffProfile(saved, draftOf(saved, name: '  Nouveau nom ', description: 'Autre'));
      expect(c.values, {'businessName': 'Nouveau nom', 'description': 'Autre'});
    });

    test('a cleared optional link is sent as null', () {
      final d = ProfileDraft(
        businessName: saved.businessName,
        description: saved.description,
        portfolioUrl: '  ',
        videoUrl: '',
        workLocation: saved.workLocation,
      );
      expect(diffProfile(saved, d).values, {'portfolioUrl': null});
    });

    test('location is sent by id only when it changed', () {
      const other = LocationSuggestion(id: 'l9', city: 'Pointe-Noire');
      expect(diffProfile(saved, draftOf(saved, location: other)).values, {'workLocationId': 'l9'});
      expect(diffProfile(saved, draftOf(saved)).isEmpty, isTrue);
    });
  });

  test('parses EP-014 profile and EP-018 verification, tolerating unknown values', () {
    final p = ProviderProfile.fromJson({
      'businessName': 'Jean',
      'level': 'N2',
      'status': 'Actif',
      'completionRate': 96,
      'rating': 4.7,
      'reviewCount': 52,
      'workLocation': {'id': 'l1', 'city': 'Brazzaville', 'district': 'Poto-Poto'},
    });
    expect(p.level, VerificationLevel.n2);
    expect(p.status, ProviderStatus.active);
    expect(p.workLocation!.label, 'Brazzaville, Poto-Poto');
    expect(p.description, '');

    final v = VerificationRecord.fromJson({'id': 'v', 'type': 'Nouveau', 'status': 'Rejetee', 'rejectionReason': 'Flou'});
    expect(v.type, VerificationType.unknown);
    expect(v.state, ValidationState.rejected);
    expect(v.rejectionReason, 'Flou');
  });

  test('account initials and status', () {
    expect(const AccountSummary(displayName: 'Jean M.', providerStatus: ProviderStatus.active).initials, 'JM');
    expect(const AccountSummary(displayName: 'awa', providerStatus: ProviderStatus.unknown).initials, 'A');
    expect(const AccountSummary(displayName: '  ', providerStatus: ProviderStatus.unknown).initials, '?');
    final a = AccountSummary.fromJson({'user': {'displayName': 'Jean M.'}, 'providerStatus': 'Actif'});
    expect(a.displayName, 'Jean M.');
    expect(a.providerStatus, ProviderStatus.active);
  });

  test('transaction status parsing and wire values', () {
    expect(TransactionStatus.parse('EnCours'), TransactionStatus.inProgress);
    expect(TransactionStatus.parse('Nouveau'), TransactionStatus.unknown);
    expect(TransactionStatus.parse(null), TransactionStatus.unknown);
    expect(TransactionStatus.inProgress.wire, 'EnCours');
  });

  test('count label shows a plus when more pages exist', () {
    expect(const Count(12).label, '12');
    expect(const Count(100, atLeast: true).label, '100+');
  });
}

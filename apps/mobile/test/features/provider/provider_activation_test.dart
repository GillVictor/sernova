import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:servnova_mobile/core/api/api_exception.dart';
import 'package:servnova_mobile/features/provider/data/provider_repository.dart';
import 'package:servnova_mobile/features/provider/domain/provider_activation.dart';

import 'http_repositories_test.dart' show apiWith, json;

void main() {
  group('CoverageMode', () {
    test('wire values follow the data dictionary', () {
      expect(CoverageMode.neighborhood.wire, 'Quartier');
      expect(CoverageMode.city.wire, 'Ville');
      expect(CoverageMode.radius.wire, 'Rayon');
      expect(CoverageMode.country.wire, 'Pays');
    });

    test('tolerates an unknown value', () {
      expect(CoverageMode.parse('Pays'), CoverageMode.country);
      expect(CoverageMode.parse('Planète'), CoverageMode.unknown);
      expect(CoverageMode.parse(null), CoverageMode.unknown);
    });
  });

  group('ProviderActivation.toJson', () {
    test('trims the name and omits radiusKm outside the Rayon mode', () {
      final j = const ProviderActivation(
        businessName: '  Jean M. – Plomberie ',
        workLocationId: 'l1',
        coverageMode: CoverageMode.city,
        radiusKm: 30, // ignored: not a radius mode
        categoryIds: ['c1', 'c2'],
      ).toJson();
      expect(j, {
        'businessName': 'Jean M. – Plomberie',
        'workLocationId': 'l1',
        'coverageMode': 'Ville',
        'categoryIds': ['c1', 'c2'],
      });
    });

    test('sends radiusKm in the Rayon mode', () {
      final j = const ProviderActivation(
        businessName: 'A',
        workLocationId: 'l1',
        coverageMode: CoverageMode.radius,
        radiusKm: 25,
        categoryIds: ['c1'],
      ).toJson();
      expect(j['coverageMode'], 'Rayon');
      expect(j['radiusKm'], 25);
    });
  });

  group('HttpProviderRepository.activate (EP-011)', () {
    const activation = ProviderActivation(
      businessName: 'Jean',
      workLocationId: 'l1',
      coverageMode: CoverageMode.country,
      categoryIds: ['c1'],
    );

    test('POST /users/me/provider with the activation body', () async {
      final log = <http.Request>[];
      final repo = HttpProviderRepository(apiWith((r) async => json({'status': 'Actif'}, 201), log));
      await repo.activate(activation);
      expect(log.single.method, 'POST');
      expect(log.single.url.path, '/api/v1/users/me/provider');
      expect(jsonDecode(log.single.body), activation.toJson());
    });

    test('an empty 201 body is accepted (the response schema is not fixed, OP-41)', () async {
      final repo = HttpProviderRepository(apiWith((r) async => http.Response('', 201), []));
      await repo.activate(activation);
    });

    test('PROVIDER_ALREADY_ACTIVE (409) surfaces its code', () async {
      final repo = HttpProviderRepository(apiWith(
        (r) async => json({'code': 'PROVIDER_ALREADY_ACTIVE', 'status': 409, 'title': 'x'}, 409),
        [],
      ));
      expect(
        repo.activate(activation),
        throwsA(isA<ApiException>().having((e) => e.code, 'code', 'PROVIDER_ALREADY_ACTIVE')),
      );
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:servnova_mobile/core/api/api_exception.dart';
import 'package:servnova_mobile/features/provider/domain/provider_activation.dart';
import 'package:servnova_mobile/features/provider/presentation/become_provider_controller.dart';

import '../../support/stub_space.dart';

const activation = ProviderActivation(
  businessName: 'Jean',
  workLocationId: 'l1',
  coverageMode: CoverageMode.city,
  categoryIds: ['c1'],
);

void main() {
  test('activate sends the activation and reports success', () async {
    final s = StubSpace();
    final c = BecomeProviderController(s);
    expect(await c.activate(activation), isTrue);
    expect(s.activations.single, same(activation));
    expect(c.busy, isFalse);
    expect(c.failure, isNull);
  });

  test('a rejected activation keeps the contract code', () async {
    final s = StubSpace()
      ..activateError = ApiException(status: 409, code: 'PROVIDER_ALREADY_ACTIVE');
    final c = BecomeProviderController(s);
    expect(await c.activate(activation), isFalse);
    expect(c.failure?.code, 'PROVIDER_ALREADY_ACTIVE');
  });

  test('field errors of a 422 are kept', () async {
    final s = StubSpace()
      ..activateError = ApiException(
        status: 422,
        code: 'VALIDATION_FAILED',
        fieldErrors: const [FieldError(field: 'businessName', code: 'REQUIRED')],
      );
    final c = BecomeProviderController(s);
    await c.activate(activation);
    expect(c.failure?.fieldErrors.single.field, 'businessName');
  });

  test('a second call while busy does nothing', () async {
    final s = StubSpace();
    final c = BecomeProviderController(s);
    final first = c.activate(activation);
    expect(await c.activate(activation), isFalse);
    await first;
    expect(s.activations, hasLength(1));
  });

  test('a new attempt clears the previous failure', () async {
    final s = StubSpace()..activateError = ApiException(status: 422, code: 'LOCATION_REQUIRED');
    final c = BecomeProviderController(s);
    await c.activate(activation);
    expect(c.failure, isNotNull);
    s.activateError = null;
    expect(await c.activate(activation), isTrue);
    expect(c.failure, isNull);
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:servnova_mobile/core/format/money.dart';

void main() {
  test('formats XAF as FCFA with grouped thousands', () {
    expect(const Money(amount: 15000, currency: 'XAF').format(), '15\u202F000\u00A0FCFA');
    expect(const Money(amount: 500, currency: 'XOF').format(), '500\u00A0FCFA');
  });

  test('keeps other currency codes', () {
    expect(const Money(amount: 1234567, currency: 'EUR').format(), '1\u202F234\u202F567\u00A0EUR');
  });

  test('tryParse accepts {amount, currency} and rejects other shapes', () {
    expect(Money.tryParse({'amount': 15000, 'currency': 'XAF'}),
        const Money(amount: 15000, currency: 'XAF'));
    expect(Money.tryParse({'amount': 'x', 'currency': 'XAF'}), isNull);
    expect(Money.tryParse(null), isNull);
  });
}

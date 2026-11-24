/// Amount in the smallest currency unit (XAF and XOF have no decimals) plus
/// an ISO 4217 code, as in the contract ("Montants"). Never a double.
class Money {
  const Money({required this.amount, required this.currency});

  final int amount;
  final String currency;

  /// Returns null when the JSON does not look like `{amount, currency}`.
  static Money? tryParse(Object? json) {
    if (json is! Map<String, dynamic>) return null;
    final a = json['amount'];
    final c = json['currency'];
    if (a is! num || c is! String) return null;
    return Money(amount: a.toInt(), currency: c);
  }

  /// "15 000 FCFA" (XAF/XOF) or "15 000 EUR".
  String format() {
    final digits = amount.abs().toString();
    final grouped = digits.replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (_) => '\u202F',
    );
    final sign = amount < 0 ? '-' : '';
    final unit = (currency == 'XAF' || currency == 'XOF') ? 'FCFA' : currency;
    return '$sign$grouped\u00A0$unit';
  }

  @override
  bool operator ==(Object other) =>
      other is Money && other.amount == amount && other.currency == currency;

  @override
  int get hashCode => Object.hash(amount, currency);
}

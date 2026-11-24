/// `StatutTransaction` (docs/transaction-state-machine.md). [wire] is the
/// value sent in the `status` query parameter.
enum TransactionStatus {
  pending('EnAttente'),
  accepted('Acceptee'),
  scheduled('Planifiee'),
  inProgress('EnCours'),
  completed('Terminee'),
  confirmed('Confirmee'),
  closed('Cloturee'),
  cancelled('Annulee'),
  disputed('Contestee'),
  unknown('');

  const TransactionStatus(this.wire);
  final String wire;

  static TransactionStatus parse(Object? v) => TransactionStatus.values
      .firstWhere((s) => s.wire.isNotEmpty && s.wire == v, orElse: () => TransactionStatus.unknown);
}

/// Row of EP-065 (assumed `{id, reference, title, status, counterpartName}`,
/// OP-25). Only a display name of the other party, never contact details.
class OrderSummary {
  const OrderSummary({
    required this.id,
    required this.reference,
    required this.title,
    required this.status,
    this.counterpartName,
  });

  final String id;
  final String reference; // readable reference, e.g. "#1024" (D21)
  final String title;
  final TransactionStatus status;
  final String? counterpartName;

  factory OrderSummary.fromJson(Map<String, dynamic> j) => OrderSummary(
        id: j['id'] as String,
        reference: (j['reference'] as String?) ?? '',
        title: (j['title'] as String?) ?? '',
        status: TransactionStatus.parse(j['status']),
        counterpartName: j['counterpartName'] as String?,
      );
}

class OrderPage {
  const OrderPage({required this.items, this.nextCursor});
  final List<OrderSummary> items;
  final String? nextCursor;
}

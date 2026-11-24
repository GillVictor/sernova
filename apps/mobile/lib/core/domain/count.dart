/// A count obtained from a paginated list (the contract has no count route):
/// [atLeast] is true when more pages exist, so the true total is larger.
class Count {
  const Count(this.value, {this.atLeast = false});
  final int value;
  final bool atLeast;

  String get label => atLeast ? '$value+' : '$value';
}

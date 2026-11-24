/// Result of a picker sheet. `value == null` means "clear"; a dismissed sheet
/// returns no result at all (nothing changes).
class SheetResult<T> {
  const SheetResult(this.value);
  final T? value;
}

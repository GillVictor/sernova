/// Phone numbers as the API expects them: E.164 (`+` and 7 to 15 digits, no
/// leading zero after the plus sign), see data-dictionary "Utilisateur.telephone".
class PhoneNumber {
  PhoneNumber._();

  /// Removes what people type for readability (spaces, dashes, dots,
  /// parentheses). Adds nothing: a number without `+` stays as typed.
  static String normalize(String raw) => raw.replaceAll(RegExp(r'[\s().\-]'), '');

  /// True for a [normalize]d number in E.164 form.
  static bool isE164(String normalized) => RegExp(r'^\+[1-9]\d{6,14}$').hasMatch(normalized);
}

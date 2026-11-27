import 'api_exception.dart';

/// Error as shown to the user: a stable contract code, or NETWORK / UNKNOWN.
class ApiFailure {
  const ApiFailure(this.code, {this.retryAfterSeconds, this.fieldErrors = const []});
  final String code;
  final int? retryAfterSeconds;

  /// Fields the server rejected (`errors[]` of a 422), to mark them on the form.
  final List<FieldError> fieldErrors;

  factory ApiFailure.from(Object e) {
    if (e is ApiException) {
      return ApiFailure(e.code, retryAfterSeconds: e.retryAfterSeconds, fieldErrors: e.fieldErrors);
    }
    if (e is NetworkException) return const ApiFailure('NETWORK');
    return const ApiFailure('UNKNOWN');
  }
}

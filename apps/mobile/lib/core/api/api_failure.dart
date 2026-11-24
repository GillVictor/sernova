import 'api_exception.dart';

/// Error as shown to the user: a stable contract code, or NETWORK / UNKNOWN.
class ApiFailure {
  const ApiFailure(this.code, {this.retryAfterSeconds});
  final String code;
  final int? retryAfterSeconds;

  factory ApiFailure.from(Object e) {
    if (e is ApiException) {
      return ApiFailure(e.code, retryAfterSeconds: e.retryAfterSeconds);
    }
    if (e is NetworkException) return const ApiFailure('NETWORK');
    return const ApiFailure('UNKNOWN');
  }
}

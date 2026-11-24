/// One entry of `errors[]` in a 422 problem+json (contract, "Conventions").
class FieldError {
  const FieldError({required this.field, required this.code});
  final String field;
  final String code;
}

/// problem+json (RFC 9457) answered by the server. [code] is the stable code
/// from the contract sheet "Erreurs".
class ApiException implements Exception {
  const ApiException({
    required this.status,
    required this.code,
    this.fieldErrors = const [],
    this.retryAfterSeconds,
    this.traceId,
  });
  final int status;
  final String code;
  final List<FieldError> fieldErrors;
  final int? retryAfterSeconds;
  final String? traceId;

  @override
  String toString() => 'ApiException($status, $code, traceId: $traceId)';
}

/// The server could not be reached (offline, DNS, timeout).
class NetworkException implements Exception {
  const NetworkException();
  @override
  String toString() => 'NetworkException';
}

/// Base URL missing or insecure.
class ConfigException implements Exception {
  const ConfigException();
  @override
  String toString() => 'ConfigException';
}

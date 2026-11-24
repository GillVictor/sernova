import 'api_exception.dart';

/// A body that does not match the expected shape is a server/contract
/// problem: surface it as UNKNOWN instead of crashing the screen.
T parseBody<T>(T Function() parse) {
  try {
    return parse();
  } on TypeError {
    throw const ApiException(status: 200, code: 'UNKNOWN');
  }
}

/// `{items: [...], nextCursor}` helper (contract, "Pagination").
List<T> parseItems<T>(Object? body, T Function(Map<String, dynamic>) fromJson) =>
    parseBody(() => [
          for (final e in ((body as Map<String, dynamic>)['items'] as List? ?? const []))
            fromJson(e as Map<String, dynamic>),
        ]);

String? parseNextCursor(Object? body) =>
    parseBody(() => (body as Map<String, dynamic>)['nextCursor'] as String?);

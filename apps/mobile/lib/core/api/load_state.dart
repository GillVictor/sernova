import 'api_failure.dart';

enum LoadStatus { loading, data, failed }

/// Independent state of one block of a screen, so that one failing request
/// does not blank the whole screen.
class LoadState<T> {
  const LoadState.loading()
      : status = LoadStatus.loading,
        data = null,
        failure = null;
  const LoadState.data(T this.data)
      : status = LoadStatus.data,
        failure = null;
  const LoadState.failed(ApiFailure this.failure)
      : status = LoadStatus.failed,
        data = null;

  final LoadStatus status;
  final T? data;
  final ApiFailure? failure;

  bool get isLoading => status == LoadStatus.loading;
  bool get hasData => status == LoadStatus.data;
  bool get hasFailed => status == LoadStatus.failed;
}

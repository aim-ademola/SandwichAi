import 'package:sandwich_ai/src/core/network/api_engine_private/network_exception.dart';

class ApiResponse<T> {
  final T? data;
  final NetworkException? error;
  final bool isSuccess;

  ApiResponse._({this.data, this.error, required this.isSuccess});

  factory ApiResponse.success(T data) {
    return ApiResponse._(data: data, isSuccess: true);
  }

  factory ApiResponse.error(NetworkException error) {
    return ApiResponse._(error: error, isSuccess: false);
  }

  // Fix: Use NetworkException.defaultError() instead of trying to create with unnamed constructor
  factory ApiResponse.errorMessage(String message) {
    return ApiResponse._(
      error: NetworkException.defaultError(message),
      isSuccess: false,
    );
  }

  // Utility methods
  bool get hasError => error != null;
  bool get hasData => data != null;

  // Handle response with callbacks
  R when<R>({
    required R Function(T data) success,
    required R Function(NetworkException error) error,
  }) {
    if (isSuccess && data != null) {
      return success(data as T);
    } else {
      return error(this.error!);
    }
  }

  // Map data if success
  ApiResponse<R> map<R>(R Function(T) mapper) {
    if (isSuccess && data != null) {
      try {
        return ApiResponse.success(mapper(data as T));
      } catch (e) {
        return ApiResponse.error(
          NetworkException.formatException('Mapping failed: $e'),
        );
      }
    }
    return ApiResponse.error(error!);
  }
}

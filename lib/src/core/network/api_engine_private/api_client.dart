import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:sandwich_ai/src/core/network/api_engine_private/api_interceptors.dart';
import 'package:sandwich_ai/src/core/network/api_engine_private/backend_error_parser.dart';
import 'package:sandwich_ai/src/core/network/api_engine_private/network_exception.dart';
import 'package:sandwich_ai/src/core/network/api_engine_private/response_wrapper.dart';
import 'package:sandwich_ai/src/core/network/api_engine_public/api_constants.dart';

class ApiClient {
  static ApiClient? _instance;
  static ApiClient get instance => _instance ??= ApiClient._internal();

  late Dio _dio;
  final String _baseUrl = ApiConstants.baseUrl;

  ApiClient._internal() {
    _dio = Dio();
    _initializeDio();
  }

  void _initializeDio() {
    _dio.options = BaseOptions(
      baseUrl: _baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      sendTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    );

    if (kDebugMode) {
      _dio.interceptors.add(
        LogInterceptor(
          requestBody: true,
          responseBody: true,
          requestHeader: true,
          responseHeader: false,
          error: true,
        ),
      );
    }

    _dio.interceptors.add(AuthInterceptor());
    _dio.interceptors.add(RetryInterceptor());
    _dio.interceptors.add(ConnectivityInterceptor());
  }

  // Generic GET request
  Future<ApiResponse<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    T Function(dynamic)? fromJson,
  }) async {
    try {
      await _checkConnectivity();

      final response = await _dio.get(
        path,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );

      return _handleResponse<T>(response, fromJson);
    } catch (e) {
      return ApiResponse.error(_handleError(e));
    }
  }

  // Generic POST request
  Future<ApiResponse<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    T Function(dynamic)? fromJson,
  }) async {
    try {
      await _checkConnectivity();

      final response = await _dio.post(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );

      return _handleResponse<T>(response, fromJson);
    } catch (e) {
      return ApiResponse.error(_handleError(e));
    }
  }

  Future<ApiResponse<T>> patch<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    T Function(dynamic)? fromJson,
  }) async {
    try {
      await _checkConnectivity();

      final response = await _dio.patch(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );

      return _handleResponse<T>(response, fromJson);
    } catch (e) {
      return ApiResponse.error(_handleError(e));
    }
  }

  // Generic PUT request
  Future<ApiResponse<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    T Function(dynamic)? fromJson,
  }) async {
    try {
      await _checkConnectivity();

      final response = await _dio.put(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );

      return _handleResponse<T>(response, fromJson);
    } catch (e) {
      return ApiResponse.error(_handleError(e));
    }
  }

  // Generic DELETE request
  Future<ApiResponse<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    T Function(dynamic)? fromJson,
  }) async {
    try {
      await _checkConnectivity();

      final response = await _dio.delete(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );

      return _handleResponse<T>(response, fromJson);
    } catch (e) {
      return ApiResponse.error(_handleError(e));
    }
  }

  // File upload with progress tracking
  Future<ApiResponse<T>> uploadFile<T>(
    String path,
    FormData formData, {
    ProgressCallback? onSendProgress,
    CancelToken? cancelToken,
    T Function(dynamic)? fromJson,
  }) async {
    try {
      await _checkConnectivity();

      final response = await _dio.post(
        path,
        data: formData,
        onSendProgress: onSendProgress,
        cancelToken: cancelToken,
        options: Options(headers: {'Content-Type': 'multipart/form-data'}),
      );

      return _handleResponse<T>(response, fromJson);
    } catch (e) {
      return ApiResponse.error(_handleError(e));
    }
  }

  // File download with progress tracking
  Future<ApiResponse<String>> downloadFile(
    String url,
    String savePath, {
    ProgressCallback? onReceiveProgress,
    CancelToken? cancelToken,
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      await _checkConnectivity();

      final response = await _dio.download(
        url,
        savePath,
        onReceiveProgress: onReceiveProgress,
        cancelToken: cancelToken,
        queryParameters: queryParameters,
      );

      if (response.statusCode != null &&
          response.statusCode! >= 200 &&
          response.statusCode! < 300) {
        return ApiResponse.success(savePath);
      } else {
        return ApiResponse.error(_handleHttpError(response));
      }
    } catch (e) {
      return ApiResponse.error(_handleError(e));
    }
  }

  // Handle response parsing
  ApiResponse<T> _handleResponse<T>(
    Response response,
    T Function(dynamic)? fromJson,
  ) {
    final statusCode = response.statusCode ?? 0;
    if (statusCode >= 200 && statusCode < 300) {
      try {
        if (fromJson != null) {
          final data = fromJson(response.data);
          return ApiResponse.success(data);
        } else {
          return ApiResponse.success(response.data as T);
        }
      } catch (e) {
        return ApiResponse.error(
          NetworkException.formatException('Failed to parse response: $e'),
        );
      }
    } else {
      return ApiResponse.error(_handleHttpError(response));
    }
  }

  // Handle different types of errors
  NetworkException _handleError(dynamic error) {
    if (error is NetworkException) {
      return error;
    } else if (error is DioException) {
      return _handleDioError(error);
    } else if (error is SocketException) {
      return NetworkException.noInternetConnection();
    } else if (error is FormatException) {
      return NetworkException.formatException(error.message);
    } else {
      return NetworkException.defaultError(error.toString());
    }
  }

  // Handle DIO specific errors
  NetworkException _handleDioError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
        return NetworkException.requestTimeout();
      case DioExceptionType.sendTimeout:
        return NetworkException.sendTimeout();
      case DioExceptionType.receiveTimeout:
        return NetworkException.receiveTimeout();
      case DioExceptionType.badResponse:
        final response = error.response;
        if (response == null) {
          return NetworkException.defaultError(
            error.message ?? 'The server returned an error.',
          );
        }
        return _handleHttpError(response);
      case DioExceptionType.cancel:
        return NetworkException.requestCancelled();
      case DioExceptionType.connectionError:
        return NetworkException.noInternetConnection();
      case DioExceptionType.badCertificate:
        return NetworkException.badCertificate();
      case DioExceptionType.unknown:
        if (error.error is SocketException) {
          return NetworkException.noInternetConnection();
        }
        return NetworkException.defaultError(error.message ?? 'Unknown error');
    }
  }

  // Handle HTTP status code errors
  NetworkException _handleHttpError(Response response) {
    final details = BackendErrorParser.parse(
      response.data,
      statusCode: response.statusCode,
      fallbackMessage: _fallbackForStatus(response.statusCode),
    );

    switch (response.statusCode) {
      case 400:
        return NetworkException.fromBackend(
          details,
          type: NetworkExceptionType.badRequest,
          fallbackMessage: 'Bad request. Please check your input.',
        );
      case 401:
        return NetworkException.fromBackend(
          details,
          type: NetworkExceptionType.unauthorizedRequest,
          fallbackMessage: 'Unauthorized. Please login again.',
        );
      case 403:
        return NetworkException.fromBackend(
          details,
          type: NetworkExceptionType.forbidden,
          fallbackMessage:
              'Forbidden. You don\'t have permission to access this resource.',
        );
      case 404:
        return NetworkException.fromBackend(
          details,
          type: NetworkExceptionType.notFound,
          fallbackMessage: 'Resource not found.',
        );
      case 409:
        return NetworkException.fromBackend(
          details,
          type: NetworkExceptionType.conflict,
          fallbackMessage:
              'Conflict. The request conflicts with the current state.',
        );
      case 422:
        return NetworkException.fromBackend(
          details,
          type: NetworkExceptionType.unprocessableEntity,
          fallbackMessage: 'Validation failed. Please check your input.',
        );
      case 429:
        return NetworkException.fromBackend(
          details,
          type: NetworkExceptionType.tooManyRequests,
          fallbackMessage: 'Too many requests. Please try again later.',
        );
      case 500:
        return NetworkException.fromBackend(
          details,
          type: NetworkExceptionType.internalServerError,
          fallbackMessage: 'Internal server error. Please try again later.',
        );
      case 502:
        return NetworkException.fromBackend(
          details,
          type: NetworkExceptionType.badGateway,
          fallbackMessage:
              'Bad gateway. The server is temporarily unavailable.',
        );
      case 503:
        return NetworkException.fromBackend(
          details,
          type: NetworkExceptionType.serviceUnavailable,
          fallbackMessage:
              'Service unavailable. The server is temporarily down.',
        );
      case 504:
        return NetworkException.fromBackend(
          details,
          type: NetworkExceptionType.gatewayTimeout,
          fallbackMessage:
              'Gateway timeout. The server took too long to respond.',
        );
      default:
        return NetworkException.fromBackend(
          details,
          type: NetworkExceptionType.defaultError,
          fallbackMessage:
              'HTTP ${response.statusCode}: ${_fallbackForStatus(response.statusCode)}',
        );
    }
  }

  String _fallbackForStatus(int? statusCode) {
    switch (statusCode) {
      case 400:
        return 'Bad request. Please check your input.';
      case 401:
        return 'Unauthorized. Please login again.';
      case 403:
        return 'Forbidden. You don\'t have permission to access this resource.';
      case 404:
        return 'Resource not found.';
      case 409:
        return 'Conflict. The request conflicts with the current state.';
      case 422:
        return 'Validation failed. Please check your input.';
      case 429:
        return 'Too many requests. Please try again later.';
      case 500:
        return 'Internal server error. Please try again later.';
      case 502:
        return 'Bad gateway. The server is temporarily unavailable.';
      case 503:
        return 'Service unavailable. The server is temporarily down.';
      case 504:
        return 'Gateway timeout. The server took too long to respond.';
      default:
        return 'Something went wrong. Please try again.';
    }
  }

  // Check network connectivity
  Future<void> _checkConnectivity() async {
    final connectivity = Connectivity();
    final result = await connectivity.checkConnectivity();

    if (result.contains(ConnectivityResult.none)) {
      throw NetworkException.noInternetConnection();
    }
  }

  // Update base URL
  void updateBaseUrl(String baseUrl) {
    _dio.options.baseUrl = baseUrl;
  }

  // Add or update headers
  void updateHeaders(Map<String, String> headers) {
    _dio.options.headers.addAll(headers);
  }

  // Clear all headers
  void clearHeaders() {
    _dio.options.headers.clear();
    _dio.options.headers.addAll({
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    });
  }

  // Get current headers
  Map<String, dynamic> get headers => _dio.options.headers;

  // Cancel all requests
  void cancelRequests([String? reason]) {
    _dio.close();
  }
}

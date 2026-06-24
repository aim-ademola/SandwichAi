// lib/core/network/network_exceptions.dart
import 'package:sandwich_ai/src/core/network/api_engine_private/backend_error_parser.dart';

class NetworkException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic data;
  final String? code;
  final List<FieldError> fieldErrors;
  final NetworkExceptionType type;

  NetworkException._({
    required this.message,
    this.statusCode,
    this.data,
    this.code,
    this.fieldErrors = const [],
    required this.type,
  });

  factory NetworkException.fromBackend(
    ApiErrorDetails details, {
    required NetworkExceptionType type,
    String fallbackMessage = 'Something went wrong. Please try again.',
  }) {
    final message = details.message.trim().isEmpty
        ? fallbackMessage
        : details.message;
    return NetworkException._(
      message: message,
      statusCode: details.statusCode,
      data: details.raw,
      code: details.code,
      fieldErrors: details.fieldErrors,
      type: type,
    );
  }

  // Timeout errors
  static NetworkException requestTimeout() => NetworkException._(
    message:
        'Connection timeout. Please check your internet connection and try again.',
    type: NetworkExceptionType.requestTimeout,
  );

  static NetworkException sendTimeout() => NetworkException._(
    message: 'Send timeout. Please try again.',
    type: NetworkExceptionType.sendTimeout,
  );

  static NetworkException receiveTimeout() => NetworkException._(
    message: 'Receive timeout. The server is taking too long to respond.',
    type: NetworkExceptionType.receiveTimeout,
  );

  // Connection errors
  static NetworkException noInternetConnection() => NetworkException._(
    message: 'No internet connection. Please check your network settings.',
    type: NetworkExceptionType.noInternetConnection,
  );

  static NetworkException badCertificate() => NetworkException._(
    message: 'SSL certificate error. The connection is not secure.',
    type: NetworkExceptionType.badCertificate,
  );

  // Request cancellation
  static NetworkException requestCancelled() => NetworkException._(
    message: 'Request was cancelled.',
    type: NetworkExceptionType.requestCancelled,
  );

  // Client errors (4xx)
  static NetworkException badRequest(
    String message, {
    dynamic data,
    List<FieldError> fieldErrors = const [],
    String? code,
  }) => NetworkException._(
    message: message.isEmpty
        ? 'Bad request. Please check your input.'
        : message,
    statusCode: 400,
    data: data,
    code: code,
    fieldErrors: fieldErrors,
    type: NetworkExceptionType.badRequest,
  );

  static NetworkException unauthorizedRequest(
    String message, {
    dynamic data,
    List<FieldError> fieldErrors = const [],
    String? code,
  }) => NetworkException._(
    message: message.isEmpty ? 'Unauthorized. Please login again.' : message,
    statusCode: 401,
    data: data,
    code: code,
    fieldErrors: fieldErrors,
    type: NetworkExceptionType.unauthorizedRequest,
  );

  static NetworkException forbidden(
    String message, {
    dynamic data,
    List<FieldError> fieldErrors = const [],
    String? code,
  }) => NetworkException._(
    message: message.isEmpty
        ? 'Forbidden. You don\'t have permission to access this resource.'
        : message,
    statusCode: 403,
    data: data,
    code: code,
    fieldErrors: fieldErrors,
    type: NetworkExceptionType.forbidden,
  );

  static NetworkException notFound(
    String message, {
    dynamic data,
    List<FieldError> fieldErrors = const [],
    String? code,
  }) => NetworkException._(
    message: message.isEmpty ? 'Resource not found.' : message,
    statusCode: 404,
    data: data,
    code: code,
    fieldErrors: fieldErrors,
    type: NetworkExceptionType.notFound,
  );

  static NetworkException conflict(
    String message, {
    dynamic data,
    List<FieldError> fieldErrors = const [],
    String? code,
  }) => NetworkException._(
    message: message.isEmpty
        ? 'Conflict. The request conflicts with the current state.'
        : message,
    statusCode: 409,
    data: data,
    code: code,
    fieldErrors: fieldErrors,
    type: NetworkExceptionType.conflict,
  );

  static NetworkException unprocessableEntity(
    String message, {
    dynamic data,
    List<FieldError> fieldErrors = const [],
    String? code,
  }) => NetworkException._(
    message: message.isEmpty
        ? 'Validation failed. Please check your input.'
        : message,
    statusCode: 422,
    data: data,
    code: code,
    fieldErrors: fieldErrors,
    type: NetworkExceptionType.unprocessableEntity,
  );

  static NetworkException tooManyRequests(
    String message, {
    dynamic data,
    List<FieldError> fieldErrors = const [],
    String? code,
  }) => NetworkException._(
    message: message.isEmpty
        ? 'Too many requests. Please try again later.'
        : message,
    statusCode: 429,
    data: data,
    code: code,
    fieldErrors: fieldErrors,
    type: NetworkExceptionType.tooManyRequests,
  );

  // Server errors (5xx)
  static NetworkException internalServerError() => NetworkException._(
    message: 'Internal server error. Please try again later.',
    statusCode: 500,
    type: NetworkExceptionType.internalServerError,
  );

  static NetworkException badGateway() => NetworkException._(
    message: 'Bad gateway. The server is temporarily unavailable.',
    statusCode: 502,
    type: NetworkExceptionType.badGateway,
  );

  static NetworkException serviceUnavailable() => NetworkException._(
    message: 'Service unavailable. The server is temporarily down.',
    statusCode: 503,
    type: NetworkExceptionType.serviceUnavailable,
  );

  static NetworkException gatewayTimeout() => NetworkException._(
    message: 'Gateway timeout. The server took too long to respond.',
    statusCode: 504,
    type: NetworkExceptionType.gatewayTimeout,
  );

  // Format and parsing errors
  static NetworkException formatException(String message) => NetworkException._(
    message: 'Data format error: $message',
    type: NetworkExceptionType.formatException,
  );

  // Default/Unknown errors
  static NetworkException defaultError(String message) => NetworkException._(
    message: message.isEmpty
        ? 'Something went wrong. Please try again.'
        : message,
    type: NetworkExceptionType.defaultError,
  );

  @override
  String toString() => message;
}

enum NetworkExceptionType {
  requestTimeout,
  sendTimeout,
  receiveTimeout,
  noInternetConnection,
  badCertificate,
  requestCancelled,
  badRequest,
  unauthorizedRequest,
  forbidden,
  notFound,
  conflict,
  unprocessableEntity,
  tooManyRequests,
  internalServerError,
  badGateway,
  serviceUnavailable,
  gatewayTimeout,
  formatException,
  defaultError,
}

import 'package:dio/dio.dart';
import 'package:sandwich_ai/src/core/auth/session_expiry_handler.dart';
import 'package:sandwich_ai/src/core/config/prod_print.dart';
import 'package:sandwich_ai/src/core/local_sandbox/cache_manager.dart';
import 'package:sandwich_ai/src/core/network/api_engine_public/api_constants.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

// Auth Interceptor
class AuthInterceptor extends Interceptor {
  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // Add auth token to requests
    final token = await AuthCacheHelper.instance.getAccessToken();

    if (token != null && token.isNotEmpty) {
      if (!_isChatRequest(options)) {
        AppLogger.log('Authorization token attached');
      }
      options.headers['Authorization'] = 'Bearer $token';
    }

    if (_isAiRequest(options)) {
      final platformApiKey = ApiConstants.platformApiKey.trim();
      final internalApiKey = ApiConstants.internalApiKey.trim();
      if (platformApiKey.isNotEmpty) {
        options.headers['X-API-Key'] = platformApiKey;
      }
      if (internalApiKey.isNotEmpty) {
        options.headers['X-Internal-API-Key'] = internalApiKey;
      }
    }
    super.onRequest(options, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401 && !_isAiRequest(err.requestOptions)) {
      await SessionExpiryHandler.handleUnauthorized();
    }

    super.onError(err, handler);
  }

  bool _isAiRequest(RequestOptions options) {
    final aiBaseUrl = ApiConstants.aiBaseUrl;
    final uri = options.uri.toString();
    return uri.startsWith(aiBaseUrl) || options.path.startsWith(aiBaseUrl);
  }

  bool _isChatRequest(RequestOptions options) {
    final path = options.path.toLowerCase();
    final uriPath = options.uri.path.toLowerCase();
    return path == 'chat' ||
        path.startsWith('chat/') ||
        path.startsWith('/chat/') ||
        uriPath == '/chat' ||
        uriPath.startsWith('/chat/');
  }
}

// Retry Interceptor
class RetryInterceptor extends Interceptor {
  final int maxRetries;
  final Duration retryDelay;

  RetryInterceptor({
    this.maxRetries = 3,
    this.retryDelay = const Duration(seconds: 1),
  });

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (_shouldRetry(err) && err.requestOptions.extra['retryCount'] == null) {
      err.requestOptions.extra['retryCount'] = 0;
    }

    final retryCount = err.requestOptions.extra['retryCount'] ?? 0;

    if (_shouldRetry(err) && retryCount < maxRetries) {
      err.requestOptions.extra['retryCount'] = retryCount + 1;

      // Wait before retrying
      await Future.delayed(retryDelay * (retryCount + 1));

      try {
        final response = await Dio().fetch(err.requestOptions);
        return handler.resolve(response);
      } catch (e) {
        return super.onError(err, handler);
      }
    }

    super.onError(err, handler);
  }

  bool _shouldRetry(DioException err) {
    return err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.receiveTimeout ||
        err.type == DioExceptionType.connectionError ||
        (err.response?.statusCode != null &&
            [500, 502, 503, 504].contains(err.response!.statusCode));
  }
}

// Connectivity Interceptor
class ConnectivityInterceptor extends Interceptor {
  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final connectivity = Connectivity();
    final result = await connectivity.checkConnectivity();

    if (result.contains(ConnectivityResult.none)) {
      return handler.reject(
        DioException(
          requestOptions: options,
          type: DioExceptionType.connectionError,
          error: 'No internet connection',
        ),
      );
    }

    super.onRequest(options, handler);
  }
}

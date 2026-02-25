import 'package:dio/dio.dart';
import 'package:sandwich_ai/src/core/config/prod_print.dart';
import 'package:sandwich_ai/src/core/local_sandbox/cache_manager.dart';
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
      AppLogger.log('Token Gotten =====> $token');
      options.headers['Authorization'] = 'Bearer $token';
    }
    super.onRequest(options, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    // Handle 401 errors by refreshing token
    // if (err.response?.statusCode == 401) {
    //   try {
    //     final success = await _refreshToken();
    //     if (success) {
    //       // Retry the original request
    //       final response = await Dio().fetch(err.requestOptions);
    //       return handler.resolve(response);
    //     }
    //   } catch (e) {
    //     // Refresh failed, redirect to login
    //     await _redirectToLogin();
    //   }
    // }

    super.onError(err, handler);
  }

  // Future<bool> _refreshToken() async {
  //   try {
  //     final prefs = await SharedPreferences.getInstance();
  //     final refreshToken = prefs.getString('refresh_token');

  //     if (refreshToken == null) return false;

  //     final dio = Dio();
  //     final response = await dio.post(
  //       '/auth/refresh',
  //       data: {'refresh_token': refreshToken},
  //     );

  //     if (response.statusCode == 200) {
  //       final newToken = response.data['access_token'];
  //       await prefs.setString('auth_token', newToken);
  //       return true;
  //     }

  //     return false;
  //   } catch (e) {
  //     return false;
  //   }
  // }

  // Future<void> _redirectToLogin() async {
  //   final prefs = await SharedPreferences.getInstance();
  //   await prefs.clear();
  //   // Navigate to login screen
  //   // You can use your navigation logic here
  // }
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

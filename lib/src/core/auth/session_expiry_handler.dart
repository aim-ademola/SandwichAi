import 'package:sandwich_ai/router/router.dart';
import 'package:sandwich_ai/src/core/config/prod_print.dart';
import 'package:sandwich_ai/src/core/local_sandbox/cache_manager.dart';

class SessionExpiryHandler {
  SessionExpiryHandler._();

  static bool _isHandlingUnauthorized = false;

  static Future<void> handleUnauthorized() async {
    if (_isHandlingUnauthorized) return;
    _isHandlingUnauthorized = true;

    try {
      await AuthCacheHelper.instance.clearAuthData();

      final router = AppRouter.router;
      if (router.routeInformationProvider.value.uri.path != '/') {
        router.go('/');
      }
    } catch (error) {
      AppLogger.log('Failed to handle unauthorized session: $error');
      try {
        AppRouter.router.go('/');
      } catch (navigationError) {
        AppLogger.log('Failed to navigate to login: $navigationError');
      }
    } finally {
      _isHandlingUnauthorized = false;
    }
  }
}

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:sandwich_ai/src/core/config/prod_print.dart';

class AnalyticsService {
  AnalyticsService._();

  static final AnalyticsService instance = AnalyticsService._();

  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  FirebaseAnalytics get analytics => _analytics;

  /// Logs user login event
  Future<void> logLogin({
    required String email,
    required String orgCode,
  }) async {
    try {
      AppLogger.log(
        '[Firebase Analytics] logLogin - email: $email, orgCode: $orgCode',
      );
      await _analytics.logLogin(loginMethod: 'email_password');
      await _analytics.setUserProperty(name: 'org_code', value: orgCode);
      await _analytics.logEvent(
        name: 'login_user',
        parameters: {'email': email, 'org_code': orgCode},
      );
    } catch (e, stackTrace) {
      AppLogger.log(
        'Failed to log login event in Firebase Analytics: $e',
        level: LogLevel.error,
        stackTrace: stackTrace,
      );
    }
  }

  /// Logs user logout event
  Future<void> logLogout() async {
    try {
      AppLogger.log('[Firebase Analytics] logLogout');
      await _analytics.logEvent(name: 'logout_user');
    } catch (e, stackTrace) {
      AppLogger.log(
        'Failed to log logout event in Firebase Analytics: $e',
        level: LogLevel.error,
        stackTrace: stackTrace,
      );
    }
  }

  /// Logs order placement event
  Future<void> logOrderPlacement({
    required String orderId,
    required double totalAmount,
    required int itemsCount,
    required String orderType,
  }) async {
    try {
      AppLogger.log(
        '[Firebase Analytics] logOrderPlacement - orderId: $orderId, '
        'totalAmount: $totalAmount, itemsCount: $itemsCount, orderType: $orderType',
      );
      await _analytics.logEvent(
        name: 'place_order',
        parameters: {
          'order_id': orderId,
          'value': totalAmount,
          'currency': 'USD', // Adjust to local currency if available
          'items_count': itemsCount,
          'order_type': orderType,
        },
      );
    } catch (e, stackTrace) {
      AppLogger.log(
        'Failed to log order placement event in Firebase Analytics: $e',
        level: LogLevel.error,
        stackTrace: stackTrace,
      );
    }
  }

  /// Logs custom screen view
  Future<void> logScreenView(String screenName) async {
    try {
      AppLogger.log(
        '[Firebase Analytics] logScreenView - screenName: $screenName',
      );
      await _analytics.logScreenView(screenName: screenName);
    } catch (e, stackTrace) {
      AppLogger.log(
        'Failed to log screen view in Firebase Analytics: $e',
        level: LogLevel.error,
        stackTrace: stackTrace,
      );
    }
  }
}

import 'dart:convert';
import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:sandwich_ai/firebase_options.dart';
import 'package:sandwich_ai/src/core/config/prod_print.dart';
import 'package:sandwich_ai/src/core/globals/notifications/local_notification.dart';
import 'package:sandwich_ai/src/core/globals/notifications/notification_bell.dart';
import 'package:sandwich_ai/src/core/local_sandbox/cache_manager.dart';
import 'package:sandwich_ai/src/core/network/api_engine_private/api_client.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (!FirebaseMessagingService.isSupportedPlatform) return;

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  await FirebaseMessagingService.handleBackgroundMessage(message);
}

class FirebaseMessagingService with WidgetsBindingObserver {
  FirebaseMessagingService._();

  static final FirebaseMessagingService instance = FirebaseMessagingService._();

  static bool get isSupportedPlatform {
    if (kIsWeb) return false;
    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
  }

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final ApiClient _apiClient = ApiClient.instance;
  bool _initialized = false;
  String? _lastRegisteredToken;

  Future<void> initialize() async {
    if (_initialized || !isSupportedPlatform) return;

    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    WidgetsBinding.instance.addObserver(this);

    await NotificationService().initializeForFcm();
    await _requestPermission();
    await _disableNativeForegroundPresentation();
    await logAndRegisterCurrentToken();

    _messaging.onTokenRefresh.listen((token) {
      AppLogger.log('FCM token refreshed: $token');
      _debugLog('FCM_TOKEN_REFRESHED=$token');
      registerToken(token, previousToken: _lastRegisteredToken);
    });

    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      _logMessageEvent('initial', initialMessage);
      await _recordMessage(initialMessage);
    }

    _initialized = true;
    AppLogger.log('Firebase Cloud Messaging initialized successfully');
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      AppLogger.log('App resumed; logging FCM token');
      logAndRegisterCurrentToken();
    }
  }

  static Future<void> handleBackgroundMessage(RemoteMessage message) async {
    _logMessageEvent('background', message);
    await _recordMessage(message);

    if (message.notification == null) {
      await NotificationService().initializeForFcm();
      await NotificationService().showNotification(
        id: _notificationId(message),
        title: _messageTitle(message),
        body: _messageBody(message),
        payload: _messagePayload(message),
        allowFcmDelivery: true,
      );
    }
  }

  Future<void> _requestPermission() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    AppLogger.log('FCM permission status: ${settings.authorizationStatus}');
  }

  Future<void> _disableNativeForegroundPresentation() {
    return _messaging.setForegroundNotificationPresentationOptions(
      alert: false,
      badge: false,
      sound: false,
    );
  }

  Future<void> logAndRegisterCurrentToken() async {
    try {
      final token = await _messaging.getToken();
      if (token == null || token.isEmpty) {
        AppLogger.log('FCM token is not available yet');
        return;
      }
      AppLogger.log('FCM token: $token');
      _debugLog('FCM_TOKEN=$token');
      await registerToken(token);
    } catch (error, stackTrace) {
      AppLogger.log(
        'Failed to get FCM token: $error',
        level: LogLevel.warning,
        stackTrace: stackTrace,
      );
    }
  }

  Future<void> registerToken(String token, {String? previousToken}) async {
    try {
      if (token.isEmpty) return;

      final accessToken = await AuthCacheHelper.instance.getAccessToken();
      if (accessToken == null || accessToken.isEmpty) {
        AppLogger.log('FCM token not registered: user is not logged in yet');
        _debugLog('FCM_REGISTER_SKIPPED=no_auth');
        return;
      }

      final body = <String, dynamic>{
        'token': token,
        if (previousToken != null &&
            previousToken.isNotEmpty &&
            previousToken != token)
          'previousToken': previousToken,
        'platform': _platformName,
        'deviceName': await _deviceName(),
      };

      AppLogger.log('Registering FCM token with backend');
      _debugLog('FCM_REGISTER_REQUEST=${jsonEncode(body)}');

      final response = await _apiClient.post(
        'push-notifications/register-token',
        data: body,
      );

      response.when(
        success: (data) {
          _lastRegisteredToken = token;
          AppLogger.log('FCM token registered with backend');
          _debugLog('FCM_REGISTER_SUCCESS=${jsonEncode(data)}');
        },
        error: (error) {
          AppLogger.log(
            'Failed to register FCM token: ${error.message}',
            level: LogLevel.warning,
          );
          _debugLog('FCM_REGISTER_ERROR=${error.statusCode}:${error.message}');
        },
      );
    } catch (error, stackTrace) {
      AppLogger.log(
        'Failed to register FCM token: $error',
        level: LogLevel.warning,
        stackTrace: stackTrace,
      );
      _debugLog('FCM_REGISTER_EXCEPTION=$error');
    }
  }

  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    _logMessageEvent('foreground', message);
    await NotificationService().showNotification(
      id: _notificationId(message),
      title: _messageTitle(message),
      body: _messageBody(message),
      payload: _messagePayload(message),
      allowFcmDelivery: true,
    );
  }

  Future<void> _handleMessageOpenedApp(RemoteMessage message) {
    _logMessageEvent('opened', message);
    return _recordMessage(message);
  }

  static Future<void> _recordMessage(RemoteMessage message) {
    return NotificationBadgeController.instance.recordNotification(
      id: _notificationId(message),
      title: _messageTitle(message),
      body: _messageBody(message),
      payload: _messagePayload(message),
    );
  }

  static int _notificationId(RemoteMessage message) {
    final source = message.messageId;
    if (source != null && source.isNotEmpty) {
      return source.hashCode.abs() % 100000;
    }
    return DateTime.now().millisecondsSinceEpoch.remainder(100000);
  }

  static String _messageTitle(RemoteMessage message) {
    return message.notification?.title ??
        message.data['title']?.toString() ??
        'SandwichAi';
  }

  static String _messageBody(RemoteMessage message) {
    return message.notification?.body ??
        message.data['body']?.toString() ??
        message.data['message']?.toString() ??
        'You have a new update.';
  }

  static String _messagePayload(RemoteMessage message) {
    return jsonEncode({
      'source': 'firebase_messaging',
      'messageId': message.messageId,
      'sentTime': message.sentTime?.toIso8601String(),
      'data': message.data,
    });
  }

  static void _logMessageEvent(String stage, RemoteMessage message) {
    final logLine =
        'FCM event [$stage]: id=${message.messageId ?? '-'} '
        'title="${_messageTitle(message)}" data=${jsonEncode(message.data)}';
    AppLogger.log(logLine);
    _debugLog(logLine);
  }

  static void _debugLog(String message) {
    if (kDebugMode || kProfileMode) {
      debugPrint(message);
    }
  }

  String get _platformName {
    if (Platform.isAndroid) return 'android';
    if (Platform.isIOS) return 'ios';
    return defaultTargetPlatform.name;
  }

  Future<String> _deviceName() async {
    try {
      final deviceInfo = DeviceInfoPlugin();
      if (Platform.isAndroid) {
        final android = await deviceInfo.androidInfo;
        return '${android.manufacturer} ${android.model}'.trim();
      }
      if (Platform.isIOS) {
        final ios = await deviceInfo.iosInfo;
        return ios.name;
      }
    } catch (_) {
      // Device name is optional for backend registration.
    }
    return _platformName;
  }
}

import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:sandwich_ai/firebase_options.dart';
import 'package:sandwich_ai/src/core/config/prod_print.dart';
import 'package:sandwich_ai/src/core/globals/notifications/local_notification.dart';
import 'package:sandwich_ai/src/core/globals/notifications/notification_bell.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (!FirebaseMessagingService.isSupportedPlatform) return;

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  await FirebaseMessagingService.handleBackgroundMessage(message);
}

class FirebaseMessagingService {
  FirebaseMessagingService._();

  static final FirebaseMessagingService instance = FirebaseMessagingService._();

  static bool get isSupportedPlatform {
    if (kIsWeb) return false;
    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
  }

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized || !isSupportedPlatform) return;

    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    await _requestPermission();
    await _disableNativeForegroundPresentation();
    await _logToken();

    _messaging.onTokenRefresh.listen((token) {
      AppLogger.log('FCM token refreshed: $token');
    });

    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      await _recordMessage(initialMessage);
    }

    _initialized = true;
    AppLogger.log('Firebase Cloud Messaging initialized successfully');
  }

  static Future<void> handleBackgroundMessage(RemoteMessage message) async {
    final notification = message.notification;

    if (notification == null) {
      await NotificationService().initialize();
      await NotificationService().showNotification(
        id: _notificationId(message),
        title: _messageTitle(message),
        body: _messageBody(message),
        payload: _messagePayload(message),
      );
      return;
    }

    await _recordMessage(message);
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

  Future<void> _logToken() async {
    try {
      final token = await _messaging.getToken();
      if (token == null || token.isEmpty) {
        AppLogger.log('FCM token is not available yet');
        return;
      }
      AppLogger.log('FCM token: $token');
    } catch (error, stackTrace) {
      AppLogger.log(
        'Failed to get FCM token: $error',
        level: LogLevel.warning,
        stackTrace: stackTrace,
      );
    }
  }

  Future<void> _handleForegroundMessage(RemoteMessage message) {
    return NotificationService().showNotification(
      id: _notificationId(message),
      title: _messageTitle(message),
      body: _messageBody(message),
      payload: _messagePayload(message),
    );
  }

  Future<void> _handleMessageOpenedApp(RemoteMessage message) {
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
}

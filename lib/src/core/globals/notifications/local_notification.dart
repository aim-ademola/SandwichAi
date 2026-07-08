import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:sandwich_ai/src/core/config/prod_print.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sandwich_ai/src/core/globals/notifications/notification_bell.dart';
import 'package:sandwich_ai/src/core/theme/app_theme_extension.dart';
import 'package:sandwich_ai/src/core/constant/textstyle.dart';

/// Global Notification Service with Dialog Handler
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  // Global navigator key - set this in your MaterialApp
  static GlobalKey<NavigatorState>? navigatorKey;

  /// Initialize the notification service
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      tz.initializeTimeZones();

      const androidSettings = AndroidInitializationSettings(
        '@mipmap/ic_launcher',
      );

      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _notifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      await _requestPermissions();

      _initialized = true;
      AppLogger.log(' Notification Service initialized successfully');
    } catch (e) {
      AppLogger.log(' Failed to initialize Notification Service: $e');
    }
  }

  Future<bool> _requestPermissions() async {
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      final result = await _notifications
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >()
          ?.requestPermissions(alert: true, badge: true, sound: true);
      return result ?? false;
    }

    if (defaultTargetPlatform == TargetPlatform.android) {
      final androidImplementation = _notifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();

      final granted = await androidImplementation
          ?.requestNotificationsPermission();
      return granted ?? false;
    }

    return true;
  }

  /// Handle notification tap - shows beautiful dialog
  void _onNotificationTapped(NotificationResponse response) {
    AppLogger.log('Notification tapped: ${response.payload}');

    if (response.payload == null) return;

    final context = navigatorKey?.currentContext;
    if (context == null) {
      AppLogger.log('⚠️ Navigator context not available');
      return;
    }

    // Parse payload and show appropriate dialog
    _parseAndShowDialog(context, response.payload!);
  }

  /// Parse payload and show dialog
  void _parseAndShowDialog(BuildContext context, String payload) {
    final parts = payload.split('|');

    if (parts.isEmpty) return;

    final type = parts[0];

    switch (type) {
      case 'stock_alert':
        if (parts.length >= 3) {
          _showStockAlertDialog(
            context: context,
            alertType: parts[1],
            itemName: parts[2],
          );
        }
        break;
      case 'daily_stock_check':
        _showDailyStockCheckDialog(context);
        break;
      case 'custom_stock':
        if (parts.length >= 2) {
          _showCustomDialog(context: context, itemName: parts[1]);
        }
        break;
    }
  }

  /// Show stock alert dialog
  void _showStockAlertDialog({
    required BuildContext context,
    required String alertType,
    required String itemName,
  }) {
    IconData icon;
    Color iconColor;
    String title;
    String message;
    String actionText;

    switch (alertType) {
      case 'low':
        icon = Icons.inventory_2_outlined;
        iconColor = kPrimary;
        title = 'Low Stock Alert';
        message =
            '$itemName is running low on stock. Consider reordering soon.';
        actionText = 'View Stock';
        break;
      case 'critical':
        icon = Icons.warning_amber_rounded;
        iconColor = const Color(0xFFFF6B00);
        title = 'Critical Stock Alert';
        message =
            '$itemName is critically low! Immediate reordering recommended.';
        actionText = 'Reorder Now';
        break;
      case 'expiring':
        icon = Icons.access_time;
        iconColor = const Color(0xFFA1000C);
        title = 'Expiring Soon';
        message = '$itemName is expiring soon. Use or sell before expiration.';
        actionText = 'View Details';
        break;
      case 'expired':
        icon = Icons.error_outline;
        iconColor = const Color(0xFFE53935);
        title = 'Expired Item';
        message =
            '$itemName has expired. Remove from inventory and reorder if needed.';
        actionText = 'Remove Item';
        break;
      case 'out':
        icon = Icons.remove_shopping_cart;
        iconColor = const Color(0xFF757575);
        title = 'Out of Stock';
        message = '$itemName is completely out of stock. Reorder immediately.';
        actionText = 'Reorder';
        break;
      case 'near_reorder': // NEW
        icon = Icons.trending_down;
        iconColor = const Color(0xFFF57F17);
        title = 'Approaching Reorder Level';
        message =
            '$itemName is approaching its reorder level. Consider placing an order soon.';
        actionText = 'View Stock';
        break;
      default:
        return;
    }

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => StockAlertDialog(
        icon: icon,
        iconColor: iconColor,
        title: title,
        message: message,
        itemName: itemName,
        actionText: actionText,
        alertType: alertType,
      ),
    );
  }

  /// Show daily stock check dialog
  void _showDailyStockCheckDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => const DailyStockCheckDialog(),
    );
  }

  /// Show custom dialog
  void _showCustomDialog({
    required BuildContext context,
    required String itemName,
  }) {
    showDialog(
      context: context,
      builder: (context) => StockAlertDialog(
        icon: Icons.info_outline,
        iconColor: kPrimary,
        title: 'Stock Update',
        message: 'Update regarding $itemName',
        itemName: itemName,
        actionText: 'View',
        alertType: 'custom',
      ),
    );
  }

  /// Check if notification type is enabled
  Future<bool> _isNotificationEnabled(StockAlertType type) async {
    final prefs = await SharedPreferences.getInstance();

    switch (type) {
      case StockAlertType.lowStock:
        return prefs.getBool('notif_low_stock') ?? true;
      case StockAlertType.criticalStock:
        return prefs.getBool('notif_critical_stock') ?? true;
      case StockAlertType.expiringSoon:
        return prefs.getBool('notif_expiring_soon') ?? true;
      case StockAlertType.expired:
        return prefs.getBool('notif_expired') ?? true;
      case StockAlertType.outOfStock:
        return prefs.getBool('notif_out_of_stock') ?? true;
      case StockAlertType.nearReorder: // NEW
        return prefs.getBool('notif_near_reorder') ?? true;
    }
  }

  /// Show instant notification
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
    NotificationPriority priority = NotificationPriority.high,
    NotificationImportance importance = NotificationImportance.high,
  }) async {
    if (!_initialized) {
      AppLogger.log('⚠️ Notification Service not initialized');
      return;
    }

    try {
      final androidDetails = AndroidNotificationDetails(
        'default_channel',
        'Default Notifications',
        channelDescription: 'General notifications',
        importance: _mapImportance(importance),
        priority: _mapPriority(priority),
        icon: '@mipmap/ic_launcher',
      );

      const iosDetails = DarwinNotificationDetails();

      final details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _notifications.show(id, title, body, details, payload: payload);
      await NotificationBadgeController.instance.recordNotification(
        id: id,
        title: title,
        body: body,
        payload: payload,
      );

      AppLogger.log(' Notification sent: $title');
    } catch (e) {
      AppLogger.log(' Failed to show notification: $e');
    }
  }

  /// Show stock alert notification (checks if enabled first)
  Future<void> showStockAlert({
    required String itemName,
    required StockAlertType type,
    int? quantity,
    int? daysUntilExpiry,
    int? reorderLevel, // NEW parameter
  }) async {
    // Check if this notification type is enabled
    final isEnabled = await _isNotificationEnabled(type);
    if (!isEnabled) {
      AppLogger.log('⚠️ Notification type ${type.name} is disabled');
      return;
    }

    final id = _generateStockAlertId(itemName, type);
    final notification = _buildStockAlertNotification(
      itemName: itemName,
      type: type,
      quantity: quantity,
      daysUntilExpiry: daysUntilExpiry,
      reorderLevel: reorderLevel, // NEW parameter
    );

    await showNotification(
      id: id,
      title: notification.title,
      body: notification.body,
      payload: notification.payload,
      priority: notification.priority,
      importance: notification.importance,
    );
  }

  /// Schedule notification for later
  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
    String? payload,
    NotificationPriority priority = NotificationPriority.high,
    NotificationImportance importance = NotificationImportance.high,
  }) async {
    if (!_initialized) {
      AppLogger.log('⚠️ Notification Service not initialized');
      return;
    }

    try {
      final androidDetails = AndroidNotificationDetails(
        'scheduled_channel',
        'Scheduled Notifications',
        channelDescription: 'Scheduled notifications',
        importance: _mapImportance(importance),
        priority: _mapPriority(priority),
        icon: '@mipmap/ic_launcher',
      );

      const iosDetails = DarwinNotificationDetails();

      final details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _notifications.zonedSchedule(
        id,
        title,
        body,
        tz.TZDateTime.from(scheduledTime, tz.local),
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        payload: payload,
      );

      AppLogger.log(' Notification scheduled: $title at $scheduledTime');
    } catch (e) {
      AppLogger.log(' Failed to schedule notification: $e');
    }
  }

  /// Cancel a specific notification
  Future<void> cancelNotification(int id) async {
    await _notifications.cancel(id);
    AppLogger.log(' Notification $id cancelled');
  }

  /// Cancel all notifications
  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
    AppLogger.log(' All notifications cancelled');
  }

  /// Build stock alert notification details
  _StockAlertNotification _buildStockAlertNotification({
    required String itemName,
    required StockAlertType type,
    int? quantity,
    int? daysUntilExpiry,
    int? reorderLevel,
  }) {
    switch (type) {
      case StockAlertType.lowStock:
        return _StockAlertNotification(
          title: '⚠️ Low Stock Alert',
          body:
              '$itemName is running low${quantity != null ? ' ($quantity remaining)' : ''}',
          payload: 'stock_alert|low|$itemName',
          priority: NotificationPriority.high,
          importance: NotificationImportance.high,
        );

      case StockAlertType.criticalStock:
        return _StockAlertNotification(
          title: '🚨 Critical Stock Alert',
          body: '$itemName is critically low! Reorder immediately.',
          payload: 'stock_alert|critical|$itemName',
          priority: NotificationPriority.max,
          importance: NotificationImportance.max,
        );

      case StockAlertType.expiringSoon:
        return _StockAlertNotification(
          title: '⏰ Expiring Soon',
          body: '$itemName expires in ${daysUntilExpiry ?? 0} days',
          payload: 'stock_alert|expiring|$itemName',
          priority: NotificationPriority.high,
          importance: NotificationImportance.high,
        );

      case StockAlertType.expired:
        return _StockAlertNotification(
          title: ' Expired Item',
          body: '$itemName has expired! Consider reordering.',
          payload: 'stock_alert|expired|$itemName',
          priority: NotificationPriority.max,
          importance: NotificationImportance.max,
        );

      case StockAlertType.outOfStock:
        return _StockAlertNotification(
          title: '📦 Out of Stock',
          body: '$itemName is out of stock',
          payload: 'stock_alert|out|$itemName',
          priority: NotificationPriority.max,
          importance: NotificationImportance.max,
        );

      case StockAlertType.nearReorder: // NEW
        return _StockAlertNotification(
          title: '📊 Approaching Reorder Level',
          body:
              '$itemName is approaching reorder level${quantity != null && reorderLevel != null ? ' ($quantity/$reorderLevel)' : ''}',
          payload: 'stock_alert|near_reorder|$itemName',
          priority: NotificationPriority.high,
          importance: NotificationImportance.high,
        );
    }
  }

  /// Generate notification ID - CRITICAL alerts use timestamp for repeats
  int _generateStockAlertId(String itemName, StockAlertType type) {
    // For CRITICAL alerts (low stock and out of stock), use timestamp to allow repeated notifications
    if (type == StockAlertType.lowStock ||
        type == StockAlertType.outOfStock ||
        type == StockAlertType.criticalStock) {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final hash = '${itemName}_${type.name}_$timestamp'.hashCode.abs();
      return 10000 + (hash % 90000); // Expanded range for more unique IDs
    }

    // For other alerts, use consistent ID to prevent duplicates
    final hash = '${itemName}_${type.name}'.hashCode.abs();
    return 10000 + (hash % 10000);
  }

  Importance _mapImportance(NotificationImportance importance) {
    switch (importance) {
      case NotificationImportance.min:
        return Importance.min;
      case NotificationImportance.low:
        return Importance.low;
      case NotificationImportance.defaultImportance:
        return Importance.defaultImportance;
      case NotificationImportance.high:
        return Importance.high;
      case NotificationImportance.max:
        return Importance.max;
    }
  }

  Priority _mapPriority(NotificationPriority priority) {
    switch (priority) {
      case NotificationPriority.min:
        return Priority.min;
      case NotificationPriority.low:
        return Priority.low;
      case NotificationPriority.defaultPriority:
        return Priority.defaultPriority;
      case NotificationPriority.high:
        return Priority.high;
      case NotificationPriority.max:
        return Priority.max;
    }
  }
}

// Beautiful Stock Alert Dialog
class StockAlertDialog extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String message;
  final String itemName;
  final String actionText;
  final String alertType;

  const StockAlertDialog({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.message,
    required this.itemName,
    required this.actionText,
    required this.alertType,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 8,
      backgroundColor: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header with gradient
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    iconColor.withValues(alpha: 0.1),
                    iconColor.withValues(alpha: 0.05),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: iconColor.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, size: 48, color: iconColor),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    title,
                    style: WorkSansAppTextStyles.medium.copyWith(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: Colors.black,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            // Content
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F5F5),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      itemName,
                      style: WorkSansAppTextStyles.medium.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: kPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    message,
                    style: WorkSansAppTextStyles.medium.copyWith(
                      fontSize: 15,
                      fontWeight: FontWeight.w400,
                      color: const Color(0xFF757575),
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  // Action buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            side: BorderSide(
                              color: iconColor.withValues(alpha: 0.3),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            'Dismiss',
                            style: WorkSansAppTextStyles.medium.copyWith(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF757575),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            // Navigate to stock page or perform action
                            // You can implement navigation logic here
                          },
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            backgroundColor: iconColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: Text(
                            actionText,
                            style: WorkSansAppTextStyles.medium.copyWith(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Daily Stock Check Dialog
class DailyStockCheckDialog extends StatelessWidget {
  const DailyStockCheckDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 8,
      backgroundColor: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    kPrimary.withValues(alpha: 0.1),
                    kPrimary.withValues(alpha: 0.05),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: kPrimary.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.schedule, size: 48, color: kPrimary),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '📊 Daily Stock Check',
                    style: WorkSansAppTextStyles.medium.copyWith(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: Colors.black,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Text(
                    'Time to review your inventory levels and ensure everything is in stock.',
                    style: WorkSansAppTextStyles.medium.copyWith(
                      fontSize: 15,
                      fontWeight: FontWeight.w400,
                      color: const Color(0xFF757575),
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        // Navigate to stock page
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        backgroundColor: kPrimary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        'Review Inventory',
                        style: WorkSansAppTextStyles.medium.copyWith(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      'Later',
                      style: WorkSansAppTextStyles.medium.copyWith(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF757575),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Enums
enum StockAlertType {
  lowStock,
  criticalStock,
  expiringSoon,
  expired,
  outOfStock,
  nearReorder, // NEW
}

enum NotificationPriority { min, low, defaultPriority, high, max }

enum NotificationImportance { min, low, defaultImportance, high, max }

class _StockAlertNotification {
  final String title;
  final String body;
  final String payload;
  final NotificationPriority priority;
  final NotificationImportance importance;

  _StockAlertNotification({
    required this.title,
    required this.body,
    required this.payload,
    required this.priority,
    required this.importance,
  });
}

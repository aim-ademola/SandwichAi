import 'package:sandwich_ai/src/core/config/prod_print.dart';
import 'package:sandwich_ai/src/core/globals/notifications/local_notification.dart';
import 'package:sandwich_ai/src/core/local_sandbox/cache_manager.dart';
import 'package:sandwich_ai/src/features/stock_control/data/model/branch_stock_model.dart';

/// Stock Notification Helper with Department-based Access Control
class StockNotificationHelper {
  static final StockNotificationHelper _instance =
      StockNotificationHelper._internal();
  factory StockNotificationHelper() => _instance;
  StockNotificationHelper._internal();

  final _notificationService = NotificationService();
  final _authCacheHelper = AuthCacheHelper.instance;
  final Set<String> _notifiedItems = {}; // Track already notified items

  /// Check if the current user is in STOCK_CONTROL department
  Future<bool> _isAllowedUser() async {
    try {
      final authData = await _authCacheHelper.getUserData();

      if (authData == null) {
        return false;
      }

      final userDept = authData.department?.toUpperCase().trim() ?? '';

      return userDept == 'STOCK_CONTROL' ||
          userDept == 'STOCK CONTROL' ||
          userDept == 'STOCKCONTROL' ||
          userDept == 'PROCUREMENT' ||
          userDept == 'PROCESSING' ||
          userDept == 'KITCHEN';
    } catch (e) {
      AppLogger.log('Error checking user department: $e');
      return false;
    }
  }

  /// Check if a notification should be blocked (for non-critical alerts only)
  bool _shouldBlockNotification(String itemKey, StockAlertType type) {
    // NEVER block critical alerts (low stock, out of stock, critical stock)
    if (type == StockAlertType.lowStock ||
        type == StockAlertType.outOfStock ||
        type == StockAlertType.criticalStock) {
      return false; // Always allow these to repeat
    }

    // For other alerts, check if already notified
    return _notifiedItems.contains(itemKey);
  }

  /// Check stock levels and send notifications (only for STOCK_CONTROL users)
  Future<void> checkStockLevels(List<CatalogItem> items) async {
    // Only allow notifications for STOCK_CONTROL department
    if (!await _isAllowedUser()) {
      AppLogger.log(
        'User not in STOCK_CONTROL department. Notifications blocked.',
      );
      return;
    }

    for (final item in items) {
      await _checkItemStatus(item);
    }
  }

  /// Check individual item and send appropriate notification
  Future<void> _checkItemStatus(CatalogItem item) async {
    // Double-check department access
    if (!await _isAllowedUser()) {
      return;
    }

    final itemKey = '${item.name}_${item.id}';

    // Priority 1: Check for expired items (highest priority)
    if (item.expiryDays <= 0) {
      final notificationKey = '${itemKey}_expired';
      if (!_shouldBlockNotification(notificationKey, StockAlertType.expired)) {
        await _notificationService.showStockAlert(
          itemName: item.name,
          type: StockAlertType.expired,
        );
        _notifiedItems.add(notificationKey);
      }
      return;
    }

    // Priority 2: Check for out of stock - ALWAYS SEND (CRITICAL)
    if (item.quantity <= 0 || item.status == ItemStatus.outOfStock) {
      // NO BLOCKING - Always send out of stock alerts
      await _notificationService.showStockAlert(
        itemName: item.name,
        type: StockAlertType.outOfStock,
        quantity: item.quantity.toInt(),
      );
      AppLogger.log(
        '🚨 OUT OF STOCK alert sent for ${item.name} (CRITICAL - No blocking)',
      );
      return;
    }

    // Priority 3: Check for low stock - ALWAYS SEND (CRITICAL)
    if (item.status == ItemStatus.lowStock) {
      // NO BLOCKING - Always send low stock alerts
      // Determine if critical or just low
      final isCritical = item.quantity <= (item.reorderLevel * 0.5);

      await _notificationService.showStockAlert(
        itemName: item.name,
        type: isCritical
            ? StockAlertType.criticalStock
            : StockAlertType.lowStock,
        quantity: item.quantity.toInt(),
      );
      AppLogger.log(
        '⚠️ LOW STOCK alert sent for ${item.name} (CRITICAL - No blocking)',
      );
      return;
    }

    // Priority 4: Check for near reorder level
    if (item.status == ItemStatus.nearReorder) {
      final notificationKey = '${itemKey}_near_reorder';
      if (!_shouldBlockNotification(
        notificationKey,
        StockAlertType.nearReorder,
      )) {
        await _notificationService.showStockAlert(
          itemName: item.name,
          type: StockAlertType.nearReorder,
          quantity: item.quantity.toInt(),
          reorderLevel: item.reorderLevel.toInt(),
        );
        _notifiedItems.add(notificationKey);
      }
      return;
    }

    // Priority 5: Check for expiring soon (within 7 days)
    if (item.expiryDays > 0 && item.expiryDays <= 7) {
      final notificationKey = '${itemKey}_expiring';
      if (!_shouldBlockNotification(
        notificationKey,
        StockAlertType.expiringSoon,
      )) {
        await _notificationService.showStockAlert(
          itemName: item.name,
          type: StockAlertType.expiringSoon,
          daysUntilExpiry: item.expiryDays,
        );
        _notifiedItems.add(notificationKey);
      }
    }
  }

  /// Check single item immediately (only for STOCK_CONTROL users)
  Future<void> checkSingleItem(CatalogItem item) async {
    if (!await _isAllowedUser()) {
      return;
    }

    await _checkItemStatus(item);
  }

  /// Clear notification history (useful for testing or reset)
  void clearNotificationHistory() {
    _notifiedItems.clear();
    AppLogger.log(
      '✅ Notification history cleared. Critical alerts (low/out of stock) will continue to repeat.',
    );
  }

  /// Remove item from notification history (when stock is replenished)
  void markItemRestocked(String itemName, String itemId) {
    final itemKey = '${itemName}_$itemId';
    // Note: Low stock and out of stock alerts are never blocked anyway,
    // but we still remove them for consistency
    _notifiedItems.remove('${itemKey}_low');
    _notifiedItems.remove('${itemKey}_critical');
    _notifiedItems.remove('${itemKey}_out');
    _notifiedItems.remove('${itemKey}_near_reorder');
    _notifiedItems.remove('${itemKey}_expired');
    _notifiedItems.remove('${itemKey}_expiring');
    AppLogger.log(
      '✅ ${itemName} marked as restocked. Notification history cleared for this item.',
    );
  }

  /// Check and notify for items that meet specific criteria (only for STOCK_CONTROL users)
  Future<void> checkAndNotify({
    required List<CatalogItem> items,
    bool checkExpiry = true,
    bool checkStock = true,
    bool checkReorderLevels = true,
    int expiryThresholdDays = 7,
    int lowStockThreshold = 10,
  }) async {
    if (!await _isAllowedUser()) {
      return;
    }

    for (final item in items) {
      if (checkExpiry && item.expiryDays <= expiryThresholdDays) {
        await _checkItemStatus(item);
      }

      if (checkStock && item.quantity <= lowStockThreshold) {
        await _checkItemStatus(item);
      }

      if (checkReorderLevels && item.isNearReorder) {
        await _checkItemStatus(item);
      }
    }
  }

  /// Check items by status type
  Future<void> checkItemsByStatus(
    List<CatalogItem> items,
    ItemStatus status,
  ) async {
    if (!await _isAllowedUser()) {
      return;
    }

    final filteredItems = items.where((item) => item.status == status).toList();

    for (final item in filteredItems) {
      await _checkItemStatus(item);
    }
  }

  /// Send custom stock notification (only for STOCK_CONTROL users)
  Future<void> sendCustomStockNotification({
    required String itemName,
    required String title,
    required String message,
  }) async {
    if (!await _isAllowedUser()) {
      return;
    }

    await _notificationService.showNotification(
      id: DateTime.now().millisecondsSinceEpoch % 10000 + 10000,
      title: title,
      body: message,
      payload: 'custom_stock|$itemName',
    );
  }

  /// Schedule daily stock check notification (only for STOCK_CONTROL users)
  Future<void> scheduleDailyStockCheck({
    required int hour,
    required int minute,
  }) async {
    if (!await _isAllowedUser()) {
      AppLogger.log(
        'User not in STOCK_CONTROL department. Daily check not scheduled.',
      );
      return;
    }

    final now = DateTime.now();
    var scheduledTime = DateTime(now.year, now.month, now.day, hour, minute);

    // If time has passed today, schedule for tomorrow
    if (scheduledTime.isBefore(now)) {
      scheduledTime = scheduledTime.add(const Duration(days: 1));
    }

    await _notificationService.scheduleNotification(
      id: 9999, // Fixed ID for daily stock check
      title: '📊 Daily Stock Check',
      body: 'Time to review your inventory levels',
      scheduledTime: scheduledTime,
      payload: 'daily_stock_check',
    );
  }

  /// Cancel daily stock check notification
  Future<void> cancelDailyStockCheck() async {
    await _notificationService.cancelNotification(9999);
  }

  /// Get notification summary
  Map<String, int> getNotificationSummary() {
    int expired = 0;
    int expiring = 0;
    int lowStock = 0;
    int outOfStock = 0;
    int nearReorder = 0;
    int critical = 0;

    for (final key in _notifiedItems) {
      if (key.contains('_expired')) expired++;
      if (key.contains('_expiring')) expiring++;
      if (key.contains('_low')) {
        if (key.contains('critical')) {
          critical++;
        } else {
          lowStock++;
        }
      }
      if (key.contains('_out')) outOfStock++;
      if (key.contains('_near_reorder')) nearReorder++;
    }

    return {
      'expired': expired,
      'expiring': expiring,
      'lowStock': lowStock,
      'critical': critical,
      'outOfStock': outOfStock,
      'nearReorder': nearReorder,
      'total': _notifiedItems.length,
    };
  }

  /// Get items that need immediate attention
  List<CatalogItem> getItemsNeedingAttention(List<CatalogItem> items) {
    return items.where((item) => item.needsAttention).toList();
  }

  /// Get items by priority
  Map<String, List<CatalogItem>> categorizeItemsByPriority(
    List<CatalogItem> items,
  ) {
    return {
      'critical': items
          .where(
            (item) =>
                item.status == ItemStatus.expired ||
                item.status == ItemStatus.outOfStock,
          )
          .toList(),
      'high': items
          .where((item) => item.status == ItemStatus.lowStock)
          .toList(),
      'medium': items
          .where((item) => item.status == ItemStatus.nearReorder)
          .toList(),
      'low': items.where((item) => item.status == ItemStatus.useSoon).toList(),
    };
  }

  /// Batch check all critical items
  Future<void> checkCriticalItems(List<CatalogItem> items) async {
    if (!await _isAllowedUser()) {
      return;
    }

    final criticalItems = items.where((item) {
      return item.status == ItemStatus.expired ||
          item.status == ItemStatus.outOfStock ||
          item.status == ItemStatus.lowStock;
    }).toList();

    for (final item in criticalItems) {
      await _checkItemStatus(item);
    }
  }

  /// Check if current user has access to stock notifications
  Future<bool> hasNotificationAccess() async {
    return await _isAllowedUser();
  }
}

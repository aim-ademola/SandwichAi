import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:sandwich_ai/src/core/globals/app_icon.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sandwich_ai/src/core/constant/textstyle.dart';
import 'package:sandwich_ai/src/core/globals/notifications/notifications_screen.dart';
import 'package:sandwich_ai/src/core/theme/app_theme_extension.dart';

String cleanNotificationText(String value) {
  return value
      .replaceAll('Ã¢Å¡Â Ã¯Â¸Â', '')
      .replaceAll('âš ï¸', '')
      .replaceAll('Ã¢ÂÂ°', '')
      .replaceAll('â°', '')
      .replaceAll('⚠️', '')
      .replaceAll('⏰', '')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}

class NotificationLogItem {
  const NotificationLogItem({
    required this.id,
    required this.title,
    required this.body,
    required this.createdAt,
    this.payload,
    this.isRead = false,
  });

  final int id;
  final String title;
  final String body;
  final String? payload;
  final DateTime createdAt;
  final bool isRead;

  NotificationLogItem copyWith({bool? isRead}) {
    return NotificationLogItem(
      id: id,
      title: title,
      body: body,
      payload: payload,
      createdAt: createdAt,
      isRead: isRead ?? this.isRead,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'body': body,
      'payload': payload,
      'createdAt': createdAt.toIso8601String(),
      'isRead': isRead,
    };
  }

  factory NotificationLogItem.fromJson(Map<String, dynamic> json) {
    return NotificationLogItem(
      id: json['id'] as int? ?? 0,
      title: cleanNotificationText(json['title'] as String? ?? 'Notification'),
      body: cleanNotificationText(json['body'] as String? ?? ''),
      payload: json['payload'] as String?,
      createdAt:
          DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
      isRead: json['isRead'] as bool? ?? false,
    );
  }
}

class NotificationBadgeController extends ChangeNotifier {
  NotificationBadgeController._();

  static final NotificationBadgeController instance =
      NotificationBadgeController._();

  static const _storageKey = 'notification_unread_count';
  static const _historyStorageKey = 'notification_history';
  static const _maxHistoryItems = 80;

  int _unreadCount = 0;
  List<NotificationLogItem> _items = const [];
  bool _loaded = false;

  int get unreadCount => _unreadCount;
  List<NotificationLogItem> get items => List.unmodifiable(_items);

  Future<void> load() async {
    if (_loaded) return;
    final prefs = await SharedPreferences.getInstance();
    _unreadCount = prefs.getInt(_storageKey) ?? 0;
    _items = _readItems(prefs);
    _loaded = true;
    notifyListeners();
  }

  Future<void> increment() async {
    await load();
    _unreadCount++;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_storageKey, _unreadCount);
    notifyListeners();
  }

  Future<void> recordNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    await load();
    final item = NotificationLogItem(
      id: id,
      title: _cleanTitle(title),
      body: cleanNotificationText(body),
      payload: payload,
      createdAt: DateTime.now(),
    );
    _items = [item, ..._items].take(_maxHistoryItems).toList();
    _unreadCount++;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_storageKey, _unreadCount);
    await _writeItems(prefs);
    notifyListeners();
  }

  Future<void> clear() async {
    await load();
    if (_unreadCount == 0 && !_items.any((item) => !item.isRead)) return;
    _unreadCount = 0;
    _items = _items.map((item) => item.copyWith(isRead: true)).toList();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_storageKey, _unreadCount);
    await _writeItems(prefs);
    notifyListeners();
  }

  List<NotificationLogItem> _readItems(SharedPreferences prefs) {
    final raw = prefs.getString(_historyStorageKey);
    if (raw == null || raw.isEmpty) return const [];

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];

      return decoded
          .whereType<Map>()
          .map(
            (item) => NotificationLogItem.fromJson(
              item.map((key, value) => MapEntry(key.toString(), value)),
            ),
          )
          .toList();
    } catch (_) {
      return const [];
    }
  }

  Future<void> _writeItems(SharedPreferences prefs) {
    return prefs.setString(
      _historyStorageKey,
      jsonEncode(_items.map((item) => item.toJson()).toList()),
    );
  }

  String _cleanTitle(String title) {
    return cleanNotificationText(title)
        .replaceAll(RegExp(r'^[^\w\s]+'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }
}

class NotificationBellAction extends StatefulWidget {
  const NotificationBellAction({
    super.key,
    this.iconColor,
    this.backgroundColor,
    this.badgeColor,
    this.badgeTextColor,
    this.margin = const EdgeInsets.only(right: 8),
  });

  final Color? iconColor;
  final Color? backgroundColor;
  final Color? badgeColor;
  final Color? badgeTextColor;
  final EdgeInsetsGeometry margin;

  @override
  State<NotificationBellAction> createState() => _NotificationBellActionState();
}

class _NotificationBellActionState extends State<NotificationBellAction> {
  final _controller = NotificationBadgeController.instance;

  @override
  void initState() {
    super.initState();
    _controller.load();
  }

  @override
  Widget build(BuildContext context) {
    final iconColor = widget.iconColor ?? context.modeTextPrimary;
    final backgroundColor =
        widget.backgroundColor ?? iconColor.withValues(alpha: 0.08);
    final badgeColor = widget.badgeColor ?? context.modeError;
    final badgeTextColor = widget.badgeTextColor ?? Colors.white;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final count = _controller.unreadCount;

        return Padding(
          padding: widget.margin,
          child: SizedBox(
            width: 48,
            height: 48,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Center(
                  child: Material(
                    color: backgroundColor,
                    borderRadius: BorderRadius.circular(24),
                    child: IconButton(
                      tooltip: 'Notifications',
                      icon: AppIconSlot(
                        Icons.notifications_none_rounded,
                        color: iconColor,
                      ),
                      color: iconColor,
                      onPressed: () => _openNotificationsScreen(context),
                    ),
                  ),
                ),
                if (count > 0)
                  Positioned(
                    top: 5,
                    right: 3,
                    child: Container(
                      constraints: const BoxConstraints(
                        minWidth: 18,
                        minHeight: 18,
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 5),
                      decoration: BoxDecoration(
                        color: badgeColor,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: context.modeSurface,
                          width: 2,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        count > 99 ? '99+' : count.toString(),
                        style: WorkSansAppTextStyles.medium.copyWith(
                          color: badgeTextColor,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          height: 1,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _openNotificationsScreen(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const NotificationsScreen()),
    );
  }
}

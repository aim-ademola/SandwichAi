import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sandwich_ai/src/core/constant/textstyle.dart';
import 'package:sandwich_ai/src/core/theme/app_theme_extension.dart';

class NotificationBadgeController extends ChangeNotifier {
  NotificationBadgeController._();

  static final NotificationBadgeController instance =
      NotificationBadgeController._();

  static const _storageKey = 'notification_unread_count';

  int _unreadCount = 0;
  bool _loaded = false;

  int get unreadCount => _unreadCount;

  Future<void> load() async {
    if (_loaded) return;
    final prefs = await SharedPreferences.getInstance();
    _unreadCount = prefs.getInt(_storageKey) ?? 0;
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

  Future<void> clear() async {
    await load();
    if (_unreadCount == 0) return;
    _unreadCount = 0;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_storageKey, _unreadCount);
    notifyListeners();
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
                      icon: Icon(Icons.notifications_none_rounded),
                      color: iconColor,
                      onPressed: () => _showNotificationsSheet(context, count),
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

  Future<void> _showNotificationsSheet(BuildContext context, int count) async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: context.modeSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: context.modePrimary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.notifications_active_outlined,
                        color: context.modePrimary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Notifications',
                            style: WorkSansAppTextStyles.medium.copyWith(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: context.modeTextPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            count == 0
                                ? 'No unread notifications'
                                : '$count unread notification${count == 1 ? '' : 's'}',
                            style: WorkSansAppTextStyles.medium.copyWith(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: context.modeTextMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: context.modeSurfaceAlt,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: context.modeBorder.withValues(alpha: 0.45),
                    ),
                  ),
                  child: Text(
                    count == 0
                        ? 'New stock and order alerts will appear here.'
                        : 'You have new stock or order alerts waiting in the notification tray.',
                    style: WorkSansAppTextStyles.medium.copyWith(
                      fontSize: 13,
                      height: 1.45,
                      color: context.modeTextSecondary,
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Close'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: count == 0
                            ? null
                            : () async {
                                await _controller.clear();
                                if (context.mounted) Navigator.pop(context);
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: context.modePrimary,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Mark read'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

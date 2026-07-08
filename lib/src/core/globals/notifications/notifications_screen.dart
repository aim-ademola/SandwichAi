import 'package:flutter/material.dart';
import 'package:sandwich_ai/src/core/constant/textstyle.dart';
import 'package:sandwich_ai/src/core/globals/notifications/notification_bell.dart';
import 'package:sandwich_ai/src/core/theme/app_theme_extension.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final _controller = NotificationBadgeController.instance;

  @override
  void initState() {
    super.initState();
    _controller.load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.modeBackground,
      appBar: AppBar(
        backgroundColor: context.modeSurface,
        foregroundColor: context.modeTextPrimary,
        elevation: 0,
        title: Text(
          'Notifications',
          style: WorkSansAppTextStyles.medium.copyWith(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: context.modeTextPrimary,
          ),
        ),
        actions: [
          AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              return TextButton(
                onPressed: _controller.unreadCount == 0
                    ? null
                    : () => _controller.clear(),
                child: const Text('Mark all read'),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            final items = _controller.items;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _NotificationSummary(
                  unreadCount: _controller.unreadCount,
                  totalCount: items.length,
                ),
                Expanded(
                  child: items.isEmpty
                      ? const _EmptyNotifications()
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                          itemBuilder: (context, index) {
                            return _NotificationTile(item: items[index]);
                          },
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: 10),
                          itemCount: items.length,
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _NotificationSummary extends StatelessWidget {
  const _NotificationSummary({
    required this.unreadCount,
    required this.totalCount,
  });

  final int unreadCount;
  final int totalCount;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: context.modeSurface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: context.modeBorder.withValues(alpha: 0.45)),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: context.modePrimary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
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
                    unreadCount == 0
                        ? 'No unread notifications'
                        : '$unreadCount unread notification${unreadCount == 1 ? '' : 's'}',
                    style: WorkSansAppTextStyles.medium.copyWith(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: context.modeTextPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    totalCount == 0
                        ? 'New stock and order alerts will appear here.'
                        : '$totalCount notification${totalCount == 1 ? '' : 's'} in this device history.',
                    style: WorkSansAppTextStyles.medium.copyWith(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: context.modeTextMuted,
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

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({required this.item});

  final NotificationLogItem item;

  @override
  Widget build(BuildContext context) {
    final config = _NotificationVisuals.fromPayload(item.payload);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.modeSurface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: item.isRead
              ? context.modeBorder.withValues(alpha: 0.45)
              : config.color.withValues(alpha: 0.55),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: config.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(config.icon, color: config.color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        item.title.isEmpty ? 'Notification' : item.title,
                        style: WorkSansAppTextStyles.medium.copyWith(
                          fontSize: 14,
                          fontWeight: item.isRead
                              ? FontWeight.w600
                              : FontWeight.w800,
                          color: context.modeTextPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _formatTime(item.createdAt),
                      style: WorkSansAppTextStyles.medium.copyWith(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: context.modeTextMuted,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  item.body,
                  style: WorkSansAppTextStyles.medium.copyWith(
                    fontSize: 13,
                    height: 1.35,
                    fontWeight: FontWeight.w500,
                    color: context.modeTextSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _formatTime(DateTime createdAt) {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inMinutes < 1) return 'Now';
    if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
    if (difference.inHours < 24) return '${difference.inHours}h ago';
    if (difference.inDays < 7) return '${difference.inDays}d ago';

    final day = createdAt.day.toString().padLeft(2, '0');
    final month = createdAt.month.toString().padLeft(2, '0');
    return '$day/$month/${createdAt.year}';
  }
}

class _EmptyNotifications extends StatelessWidget {
  const _EmptyNotifications();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.notifications_none_rounded,
              size: 56,
              color: context.modeTextMuted,
            ),
            const SizedBox(height: 14),
            Text(
              'No notifications yet',
              style: WorkSansAppTextStyles.medium.copyWith(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: context.modeTextPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Stock and order alerts will show here when they come in.',
              textAlign: TextAlign.center,
              style: WorkSansAppTextStyles.medium.copyWith(
                fontSize: 13,
                height: 1.35,
                fontWeight: FontWeight.w500,
                color: context.modeTextMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotificationVisuals {
  const _NotificationVisuals({required this.icon, required this.color});

  final IconData icon;
  final Color color;

  factory _NotificationVisuals.fromPayload(String? payload) {
    if (payload == null) {
      return const _NotificationVisuals(
        icon: Icons.notifications_outlined,
        color: Color(0xFFEC4613),
      );
    }

    if (payload.startsWith('stock_alert|out') ||
        payload.startsWith('stock_alert|expired')) {
      return const _NotificationVisuals(
        icon: Icons.error_outline,
        color: Color(0xFFE53935),
      );
    }

    if (payload.startsWith('stock_alert|critical')) {
      return const _NotificationVisuals(
        icon: Icons.warning_amber_rounded,
        color: Color(0xFFFF6B00),
      );
    }

    if (payload.startsWith('stock_alert')) {
      return const _NotificationVisuals(
        icon: Icons.inventory_2_outlined,
        color: Color(0xFF1969FE),
      );
    }

    if (payload.startsWith('order')) {
      return const _NotificationVisuals(
        icon: Icons.receipt_long_outlined,
        color: Color(0xFF1A9D2F),
      );
    }

    return const _NotificationVisuals(
      icon: Icons.notifications_outlined,
      color: Color(0xFFEC4613),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sandwich_ai/src/core/local_sandbox/cache_manager.dart';

class LogoutService {
  static final LogoutService _instance = LogoutService._internal();
  static LogoutService get instance => _instance;

  LogoutService._internal();

  /// Performs complete logout with cleanup
  Future<void> logout(BuildContext context) async {
    try {
      // 1. Clear authentication cache
      await AuthCacheHelper.instance.clearAuthData();

      // 2. Navigate to login screen
      // Using go() with replace ensures we clear the navigation stack
      if (context.mounted) {
        context.go('/');
      }
    } catch (e) {
      debugPrint('Error during logout: $e');

      // Even if cleanup fails, still navigate to login
      if (context.mounted) {
        context.go('/');
      }
    }
  }

  Future<void> showLogoutDialog(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await logout(context);
    }
  }
}

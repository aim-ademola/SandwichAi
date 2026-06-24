// ignore_for_file: deprecated_member_use

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sandwich_ai/src/core/globals/app_drawer.dart';
import 'package:sandwich_ai/src/core/theme/app_theme_extension.dart';
import 'package:sandwich_ai/src/features/auth/data/repo/logout_service.dart';
import 'package:sandwich_ai/src/features/auth/forgot_pwd/presentation/chnge_pwd.dart';
import 'package:sandwich_ai/src/features/stock_control/presentation/daily_stock_alerts.dart';
import 'package:showcaseview/showcaseview.dart';
import 'package:sandwich_ai/src/core/constant/textstyle.dart';
import 'package:sandwich_ai/src/core/local_sandbox/drawer_onboarding_cache.dart';
import 'package:sandwich_ai/src/features/stock_control/presentation/complete_stock_reqs.dart';
import 'package:sandwich_ai/src/features/stock_control/presentation/precuremnt_req.dart';
import 'package:sandwich_ai/src/features/stock_control/presentation/wastage_log_tabs.dart';

class StockControlAppDrawer extends StatelessWidget {
  const StockControlAppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return ShowCaseWidget(
      onFinish: () async {
        await DrawerOnboardingCache.instance
            .markStockControlDrawerOnboardingSeen();
      },
      blurValue: 1,
      builder: (context) => _StockControlAppDrawerContent(),
    );
  }
}

class _StockControlAppDrawerContent extends StatefulWidget {
  const _StockControlAppDrawerContent();

  @override
  State<_StockControlAppDrawerContent> createState() =>
      _StockControlAppDrawerContentState();
}

class _StockControlAppDrawerContentState
    extends State<_StockControlAppDrawerContent> {
  final GlobalKey _stockTransferKey = GlobalKey();
  final GlobalKey _requisitionKey = GlobalKey();
  final GlobalKey _settleRequestsKey = GlobalKey();
  final GlobalKey _wastageLogsKey = GlobalKey();
  final GlobalKey _notificationSettingsKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _checkOnboarding();
  }

  Future<void> _checkOnboarding() async {
    final hasSeenOnboarding = await DrawerOnboardingCache.instance
        .hasSeenStockControlDrawerOnboarding();

    if (!hasSeenOnboarding && mounted) {
      // Wait for drawer to build, then show showcase
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ShowCaseWidget.of(context).startShowCase([
            _stockTransferKey,
            _requisitionKey,
            _settleRequestsKey,
            _wastageLogsKey,
            _notificationSettingsKey,
          ]);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppDrawerShell(
      moduleTitle: 'Stock Control',
      moduleSubtitle: 'Inventory movement and branch stock visibility',
      footerChildren: [
        _buildDrawerItem(
          context,
          icon: Icons.lock_outline_rounded,
          title: 'Change Password',
          onTap: () {
            Navigator.push(
              context,
              CupertinoPageRoute(builder: (_) => ChangePasswordScreen()),
            );
          },
        ),
        const SizedBox(height: 8),
        _buildDrawerItem(
          context,
          icon: Icons.logout,
          title: 'Logout',
          isLogout: true,
          onTap: () {
            LogoutService.instance.showLogoutDialog(context);
          },
        ),
      ],
      children: [
        Showcase(
          key: _stockTransferKey,
          description:
              'Initiate stock transfers to other departments. Track and manage all outgoing stock movements.',
          targetBorderRadius: BorderRadius.circular(12),
          tooltipBackgroundColor: kPrimary,
          textColor: Colors.white,
          targetPadding: const EdgeInsets.all(8),
          child: _buildDrawerItem(
            context,
            icon: Icons.call_made,
            title: 'Stock Transfer',
            onTap: () {
              context.push('/stock-req');
            },
          ),
        ),
        const SizedBox(height: 8),
        Showcase(
          key: _requisitionKey,
          description:
              'Raise Requisitions to Procurement for items needed in stock',
          targetBorderRadius: BorderRadius.circular(12),
          tooltipBackgroundColor: kPrimary,
          textColor: Colors.white,
          targetPadding: const EdgeInsets.all(8),
          child: _buildDrawerItem(
            context,
            icon: Icons.receipt_long,
            title: 'Requisition',
            onTap: () {
              Navigator.push(
                context,
                CupertinoPageRoute(
                  builder: (_) => StockProcurementRequestScreen(),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        Showcase(
          key: _settleRequestsKey,
          description:
              'View and fulfill incoming stock requests from other departments. Mark requests as complete.',
          targetBorderRadius: BorderRadius.circular(12),
          tooltipBackgroundColor: kPrimary,
          textColor: Colors.white,
          targetPadding: const EdgeInsets.all(8),
          child: _buildDrawerItem(
            context,
            icon: Icons.done_all_outlined,
            title: 'Settle Requests',
            onTap: () {
              Navigator.push(
                context,
                CupertinoPageRoute(
                  // ✅ No branchId needed — bloc fetches it from cache
                  builder: (_) => const CompleteStockRequestDetailsScreen(),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        Showcase(
          key: _wastageLogsKey,
          description:
              'Record and monitor wastage across your stock. Identify patterns and reduce losses.',
          targetBorderRadius: BorderRadius.circular(12),
          tooltipBackgroundColor: kPrimary,
          textColor: Colors.white,
          targetPadding: const EdgeInsets.all(8),
          child: _buildDrawerItem(
            context,
            icon: Icons.warning_amber,
            title: 'Wastage Logs',
            onTap: () {
              Navigator.push(
                context,
                CupertinoPageRoute(builder: (_) => WasteLogsTabScreen()),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        Showcase(
          key: _notificationSettingsKey,
          description:
              'Configure daily stock check reminders and manage notification preferences. Get alerts for low stock, expiring items, and more.',
          targetBorderRadius: BorderRadius.circular(12),
          tooltipBackgroundColor: kPrimary,
          textColor: Colors.white,
          targetPadding: const EdgeInsets.all(8),
          child: _buildDrawerItem(
            context,
            icon: Icons.notifications_outlined,
            title: 'Notification Settings',
            badge: _buildNewBadge(),
            onTap: () {
              Navigator.push(
                context,
                CupertinoPageRoute(
                  builder: (_) => const StockNotificationSettingsScreen(),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDrawerItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isLogout = false,
    Widget? badge,
  }) {
    return AppDrawerItem(
      icon: icon,
      title: title,
      onTap: onTap,
      isLogout: isLogout,
      badge: badge,
    );
  }

  Widget _buildNewBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: kPrimary,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        'NEW',
        style: WorkSansAppTextStyles.medium.copyWith(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
    );
  }
}

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sandwich_ai/src/core/globals/app_drawer.dart';
import 'package:sandwich_ai/src/features/auth/data/repo/logout_service.dart';
import 'package:sandwich_ai/src/features/auth/forgot_pwd/presentation/chnge_pwd.dart';
import 'package:sandwich_ai/src/features/processing/presentation/processing_to_stock_requisitin_tab.dart';

class KitchenAppDrawer extends StatelessWidget {
  const KitchenAppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return AppDrawerShell(
      moduleTitle: 'Kitchen',
      moduleSubtitle: 'Kitchen workflow and production readiness',
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
            // Show logout confirmation dialog
            LogoutService.instance.showLogoutDialog(context);
          },
        ),
      ],
      children: [
        _buildDrawerItem(
          context,
          icon: Icons.people_alt_outlined,
          title: 'Schedule Shift',
          onTap: () {
            context.push('/kitchen-shift');
          },
        ),
        const SizedBox(height: 8),
        _buildDrawerItem(
          context,
          icon: Icons.call_made,
          title: 'Stock Requisition',
          onTap: () {
            Navigator.push(
              context,
              CupertinoPageRoute(
                builder: (_) =>
                    ProcesssingToStockRequisitionTabScreen(dpt: 'KITCHEN'),
              ),
            );
          },
        ),

        const SizedBox(height: 8),
        _buildDrawerItem(
          context,
          icon: Icons.fact_check_outlined,
          title: 'Recipe Compliance',
          onTap: () {
            context.push('/recipe-compl');
          },
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildDrawerItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isLogout = false,
  }) {
    return AppDrawerItem(
      icon: icon,
      title: title,
      onTap: onTap,
      isLogout: isLogout,
    );
  }
}

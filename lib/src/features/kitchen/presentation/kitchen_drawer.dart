import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sandwich_ai/src/core/theme/app_theme_extension.dart';
import 'package:sandwich_ai/src/core/constant/textstyle.dart';
import 'package:sandwich_ai/src/core/globals/drawer_header.dart';
import 'package:sandwich_ai/src/features/auth/data/repo/logout_service.dart';
import 'package:sandwich_ai/src/features/auth/forgot_pwd/presentation/chnge_pwd.dart';
import 'package:sandwich_ai/src/features/processing/presentation/processing_to_stock_requisitin_tab.dart';

class KitchenAppDrawer extends StatelessWidget {
  const KitchenAppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: context.modeSurface,
      child: SafeArea(
        child: Column(
          children: [
            // Drawer Header
            buildDrawerHeader(),
            const SizedBox(height: 20),
            // Menu Items
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
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
                              ProcesssingToStockRequisitionTabScreen(
                                dpt: 'KITCHEN',
                              ),
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
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: _buildDrawerItem(
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
            ),
            // Logout Button
            Padding(
              padding: const EdgeInsets.all(16),
              child: _buildDrawerItem(
                context,
                icon: Icons.logout,
                title: 'Logout',
                isLogout: true,
                onTap: () {
                  // Show logout confirmation dialog
                  LogoutService.instance.showLogoutDialog(context);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isLogout = false,
  }) {
    final colors = context.appColors;
    final foreground = isLogout ? colors.error : colors.textPrimary;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: isLogout ? colors.logoutSurface : colors.drawerItem,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: foreground, size: 24),
            const SizedBox(width: 16),
            Text(
              title,
              style: WorkSansAppTextStyles.medium.copyWith(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: foreground,
              ),
            ),
            const Spacer(),
            Icon(
              Icons.chevron_right,
              color: isLogout ? colors.error : colors.textSecondary,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

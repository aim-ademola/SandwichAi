import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sandwich_ai/src/core/constant/appcolors.dart';
import 'package:sandwich_ai/src/core/constant/textstyle.dart';
import 'package:sandwich_ai/src/features/auth/data/repo/logout_service.dart';
import 'package:sandwich_ai/src/features/pos/presentation/compaints.dart';
import 'package:sandwich_ai/src/features/pos/presentation/pos_staff_screen.dart';
import 'package:sandwich_ai/src/features/pos/presentation/printer_settings_screen.dart';
import 'package:sandwich_ai/src/features/processing/presentation/processing_to_stock_requisitin_tab.dart';

class PosAppDrawer extends StatelessWidget {
  const PosAppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.white,
      child: SafeArea(
        child: Column(
          children: [
            // Drawer Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              decoration: BoxDecoration(
                color: kPrimary,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'SandwichAI',
                    style: WorkSansAppTextStyles.medium.copyWith(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Manager Dashboard',
                    style: WorkSansAppTextStyles.medium.copyWith(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Menu Items
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  const SizedBox(height: 8),

                  // _buildDrawerItem(
                  //   context,
                  //   icon: Icons.feedback_outlined,
                  //   title: 'Complaints',
                  //   onTap: () {
                  //     Navigator.pop(context);
                  //     context.push('/complaints');
                  //   },
                  // ),
                  // const SizedBox(height: 8),
                  _buildDrawerItem(
                    context,
                    icon: Icons.person_2_outlined,
                    title: 'Capture Customer Details',
                    onTap: () {
                      context.push('/customer-dtls');
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
                                dpt: 'CUSTOMER_SERVICE',
                              ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 8),
                  _buildDrawerItem(
                    context,
                    icon: Icons.people_alt_outlined,
                    title: 'Manage Customers',
                    onTap: () {
                      context.push('/customer-list');
                    },
                  ),
                  const SizedBox(height: 8),
                  _buildDrawerItem(
                    context,
                    icon: Icons.print_outlined,
                    title: 'Printer Settings',
                    onTap: () {
                      Navigator.push(
                        context,
                        CupertinoPageRoute(
                          builder: (_) => PrinterSettingsScreen(),
                        ),
                      );
                    },
                  ),
                ],
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
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: isLogout ? Colors.red.shade50 : const Color(0xFFF8F6F6),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isLogout ? Colors.red : kprimaryTextColor1,
              size: 24,
            ),
            const SizedBox(width: 16),
            Text(
              title,
              style: WorkSansAppTextStyles.medium.copyWith(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: isLogout ? Colors.red : kprimaryTextColor1,
              ),
            ),
            const Spacer(),
            Icon(
              Icons.chevron_right,
              color: isLogout ? Colors.red : kprimaryTextColor2,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

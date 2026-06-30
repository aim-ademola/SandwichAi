import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sandwich_ai/src/core/globals/app_drawer.dart';
import 'package:sandwich_ai/src/features/pos/presentation/printer_settings_screen.dart';
import 'package:sandwich_ai/src/features/processing/presentation/processing_to_stock_requisitin_tab.dart';

class PosAppDrawer extends StatelessWidget {
  const PosAppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return AppDrawerShell(
      moduleTitle: 'Point of Sale',
      moduleSubtitle: 'Customer service, payments and orders',
      footerChildren: const [AppDrawerThemeSwitch()],
      children: [
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
                builder: (_) => ProcesssingToStockRequisitionTabScreen(
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
              CupertinoPageRoute(builder: (_) => PrinterSettingsScreen()),
            );
          },
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
  }) {
    return AppDrawerItem(
      icon: icon,
      title: title,
      onTap: onTap,
      isLogout: isLogout,
    );
  }
}

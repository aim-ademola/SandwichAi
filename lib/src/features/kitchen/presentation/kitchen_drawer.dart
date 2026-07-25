import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sandwich_ai/src/core/globals/app_drawer.dart';
import 'package:sandwich_ai/src/features/kitchen/presentation/kitchen_order_statistics.dart';
import 'package:sandwich_ai/src/features/processing/presentation/processing_to_stock_requisitin_tab.dart';

class KitchenAppDrawer extends StatelessWidget {
  const KitchenAppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return AppDrawerShell(
      moduleTitle: 'Kitchen',
      moduleSubtitle: 'Kitchen workflow and production readiness',
      footerChildren: const [AppDrawerThemeSwitch()],
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
          icon: Icons.analytics_outlined,
          title: 'Order Statistics',
          onTap: () {
            Navigator.push(
              context,
              CupertinoPageRoute(
                builder: (_) => const KitchenOrderStatisticsScreen(),
              ),
            );
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

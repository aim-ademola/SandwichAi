// ignore_for_file: deprecated_member_use

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sandwich_ai/src/core/globals/app_drawer.dart';
import 'package:sandwich_ai/src/core/theme/app_theme_extension.dart';
import 'package:showcaseview/showcaseview.dart';
import 'package:sandwich_ai/src/core/local_sandbox/drawer_onboarding_cache.dart';
import 'package:sandwich_ai/src/features/procurement/presentation/procurement_good_reveived_tab.dart';

class ProcurementAppDrawer extends StatelessWidget {
  const ProcurementAppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return ShowCaseWidget(
      onFinish: () async {
        await DrawerOnboardingCache.instance
            .markProcurementDrawerOnboardingSeen();
      },
      blurValue: 1,
      builder: (context) => _ProcurementAppDrawerContent(),
    );
  }
}

class _ProcurementAppDrawerContent extends StatefulWidget {
  const _ProcurementAppDrawerContent();

  @override
  State<_ProcurementAppDrawerContent> createState() =>
      _ProcurementAppDrawerContentState();
}

class _ProcurementAppDrawerContentState
    extends State<_ProcurementAppDrawerContent> {
  final GlobalKey _goodsReceivedKey = GlobalKey();
  // final GlobalKey _stockRequisitionKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _checkOnboarding();
  }

  Future<void> _checkOnboarding() async {
    final hasSeenOnboarding = await DrawerOnboardingCache.instance
        .hasSeenProcurementDrawerOnboarding();

    if (!hasSeenOnboarding && mounted) {
      // Wait for drawer to build, then show showcase
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ShowCaseWidget.of(context).startShowCase([_goodsReceivedKey]);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppDrawerShell(
      moduleTitle: 'Procurement',
      moduleSubtitle: 'Supplier orders and received goods',
      footerChildren: const [AppDrawerThemeSwitch()],
      children: [
        _buildDrawerItem(
          context,
          icon: Icons.receipt_long_outlined,
          title: 'Purchase Orders',
          onTap: () {
            _closeDrawerAndPush(context, '/order-form');
          },
        ),
        const SizedBox(height: 8),
        Showcase(
          key: _goodsReceivedKey,
          description:
              'View and manage all goods received from suppliers. Track delivery status and verify incoming inventory.',
          targetBorderRadius: BorderRadius.circular(12),
          tooltipBackgroundColor: kPrimary,
          textColor: Colors.white,
          targetPadding: const EdgeInsets.all(8),
          child: _buildDrawerItem(
            context,
            icon: Icons.call_received_outlined,
            title: 'Good Received Log',
            onTap: () {
              _closeDrawerAndOpen(
                context,
                () => Navigator.push(
                  context,
                  CupertinoPageRoute(builder: (_) => GoodsReceivedTabScreen()),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),

        // Showcase(
        //   key: _stockRequisitionKey,
        //   description:
        //       'Create and manage stock requisition requests for procurement. View pending and completed requisitions.',
        //   targetBorderRadius: BorderRadius.circular(12),
        //   tooltipBackgroundColor: kPrimary,
        //   textColor: Colors.white,
        //   targetPadding: const EdgeInsets.all(8),
        //   child: _buildDrawerItem(
        //     context,
        //     icon: Icons.call_made,
        //     title: 'Stock Requisition',
        //     onTap: () {
        //       Navigator.push(
        //         context,
        //         CupertinoPageRoute(
        //           builder: (_) =>
        //               ProcesssingToStockRequisitionTabScreen(
        //                 dpt: 'PROCUREMENT',
        //               ),
        //         ),
        //       );
        //     },
        //   ),
        // ),
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

  void _closeDrawerAndPush(BuildContext context, String location) {
    _closeDrawerAndOpen(context, () => context.push(location));
  }

  void _closeDrawerAndOpen(BuildContext context, VoidCallback open) {
    final scaffoldState = Scaffold.maybeOf(context);
    if (scaffoldState?.isDrawerOpen ?? false) {
      scaffoldState!.closeDrawer();
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!context.mounted) return;
      open();
    });
  }
}

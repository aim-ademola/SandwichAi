import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:sandwich_ai/src/core/globals/drawer_header.dart';
import 'package:sandwich_ai/src/features/auth/data/repo/logout_service.dart';
import 'package:sandwich_ai/src/features/auth/forgot_pwd/presentation/chnge_pwd.dart';
import 'package:showcaseview/showcaseview.dart';
import 'package:sandwich_ai/src/core/constant/appcolors.dart';
import 'package:sandwich_ai/src/core/constant/textstyle.dart';
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

  Future<void> _markOnboardingComplete() async {
    await DrawerOnboardingCache.instance.markProcurementDrawerOnboardingSeen();
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.white,
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
                        Navigator.push(
                          context,
                          CupertinoPageRoute(
                            builder: (_) => GoodsReceivedTabScreen(),
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
            // const SizedBox(height: 5),

            // Logout Button
            Padding(
              padding: const EdgeInsets.all(16),
              child: _buildDrawerItem(
                context,
                icon: Icons.logout,
                title: 'Logout',
                isLogout: true,
                onTap: () {
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

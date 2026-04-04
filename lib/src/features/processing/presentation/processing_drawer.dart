import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sandwich_ai/src/core/globals/drawer_header.dart';
import 'package:sandwich_ai/src/features/auth/data/repo/logout_service.dart'
    show LogoutService;
import 'package:sandwich_ai/src/features/auth/forgot_pwd/presentation/chnge_pwd.dart';
import 'package:sandwich_ai/src/features/processing/presentation/product_intake_tab.dart';
import 'package:showcaseview/showcaseview.dart';
import 'package:sandwich_ai/src/core/constant/appcolors.dart';
import 'package:sandwich_ai/src/core/constant/textstyle.dart';
import 'package:sandwich_ai/src/core/local_sandbox/drawer_onboarding_cache.dart';
import 'package:sandwich_ai/src/features/processing/presentation/processing_tabs.dart';
import 'package:sandwich_ai/src/features/processing/presentation/processing_to_stock_requisitin_tab.dart';
import 'package:sandwich_ai/src/features/stock_control/presentation/wastage_log_tabs.dart';

class ProcessingAppDrawer extends StatelessWidget {
  const ProcessingAppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return ShowCaseWidget(
      onFinish: () async {
        await DrawerOnboardingCache.instance.markDrawerOnboardingSeen();
      },
      blurValue: 1,
      builder: (context) => _ProcessingAppDrawerContent(),
    );
  }
}

class _ProcessingAppDrawerContent extends StatefulWidget {
  const _ProcessingAppDrawerContent();

  @override
  State<_ProcessingAppDrawerContent> createState() =>
      _ProcessingAppDrawerContentState();
}

class _ProcessingAppDrawerContentState
    extends State<_ProcessingAppDrawerContent> {
  final GlobalKey _assignTaskKey = GlobalKey();
  final GlobalKey _validateStockKey = GlobalKey();
  final GlobalKey _stockRequisitionKey = GlobalKey();
  final GlobalKey _productIntakeKey = GlobalKey();
  final GlobalKey _recipeComplianceKey = GlobalKey();
  final GlobalKey _outputVerificationKey = GlobalKey();
  final GlobalKey _wastageLogsKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _checkOnboarding();
  }

  Future<void> _checkOnboarding() async {
    final hasSeenOnboarding = await DrawerOnboardingCache.instance
        .hasSeenDrawerOnboarding();

    if (!hasSeenOnboarding && mounted) {
      // Wait for drawer to build, then show showcase
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ShowCaseWidget.of(context).startShowCase([
            _assignTaskKey,
            _validateStockKey,
            _stockRequisitionKey,
            _productIntakeKey,
            _recipeComplianceKey,
            _outputVerificationKey,
            _wastageLogsKey,
          ]);
        }
      });
    }
  }

  Future<void> _markOnboardingComplete() async {
    await DrawerOnboardingCache.instance.markDrawerOnboardingSeen();
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
                    key: _assignTaskKey,
                    description:
                        'Create and assign tasks to your team members. Track progress and manage workload efficiently.',
                    targetBorderRadius: BorderRadius.circular(12),
                    tooltipBackgroundColor: kPrimary,
                    textColor: Colors.white,
                    targetPadding: const EdgeInsets.all(8),
                    child: _buildDrawerItem(
                      context,
                      icon: Icons.assignment_outlined,
                      title: 'Assign Task',
                      onTap: () {
                        Navigator.push(
                          context,
                          CupertinoPageRoute(
                            builder: (_) => ProcessingTaskTabScreen(),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 8),
                  Showcase(
                    key: _validateStockKey,
                    description:
                        'Review and approve stock transfer requests from Stock Control',
                    targetBorderRadius: BorderRadius.circular(12),
                    tooltipBackgroundColor: kPrimary,
                    textColor: Colors.white,
                    targetPadding: const EdgeInsets.all(8),
                    child: _buildDrawerItem(
                      context,
                      icon: Icons.call_received,
                      title: 'Validate Stock Transfer',
                      onTap: () {
                        context.push('/processing-req');
                      },
                    ),
                  ),
                  const SizedBox(height: 8),
                  Showcase(
                    key: _stockRequisitionKey,
                    description:
                        'Request and track requisitions to Stock Control',
                    targetBorderRadius: BorderRadius.circular(12),
                    tooltipBackgroundColor: kPrimary,
                    textColor: Colors.white,
                    targetPadding: const EdgeInsets.all(8),
                    child: _buildDrawerItem(
                      context,
                      icon: Icons.call_made,
                      title: 'Stock Requisition',
                      onTap: () {
                        Navigator.push(
                          context,
                          CupertinoPageRoute(
                            builder: (_) =>
                                ProcesssingToStockRequisitionTabScreen(
                                  dpt: 'PROCESSING',
                                ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 8),
                  Showcase(
                    key: _productIntakeKey,
                    description:
                        'Record and track incoming products. Monitor quality status and manage product intakes efficiently.',
                    targetBorderRadius: BorderRadius.circular(12),
                    tooltipBackgroundColor: kPrimary,
                    textColor: Colors.white,
                    targetPadding: const EdgeInsets.all(8),
                    child: _buildDrawerItem(
                      context,
                      icon: Icons.inventory_2_outlined,
                      title: 'Product Intake',
                      onTap: () {
                        Navigator.push(
                          context,
                          CupertinoPageRoute(
                            builder: (_) => const ProductIntakeTabScreen(),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 8),
                  Showcase(
                    key: _recipeComplianceKey,
                    description:
                        'Monitor recipe adherence and ensure quality standards are maintained across all production.',
                    targetBorderRadius: BorderRadius.circular(12),
                    tooltipBackgroundColor: kPrimary,
                    textColor: Colors.white,
                    targetPadding: const EdgeInsets.all(8),
                    child: _buildDrawerItem(
                      context,
                      icon: Icons.fact_check_outlined,
                      title: 'Recipe Compliance',
                      onTap: () {
                        context.push('/recipe-compl');
                      },
                    ),
                  ),
                  const SizedBox(height: 8),
                  Showcase(
                    key: _outputVerificationKey,
                    description:
                        'Verify production outputs and validate quantities against expected results.',
                    targetBorderRadius: BorderRadius.circular(12),
                    tooltipBackgroundColor: kPrimary,
                    textColor: Colors.white,
                    targetPadding: const EdgeInsets.all(8),
                    child: _buildDrawerItem(
                      context,
                      icon: Icons.task_alt_outlined,
                      title: 'Output Verification',
                      onTap: () {
                        context.push('/output-ver-proc');
                      },
                    ),
                  ),
                  const SizedBox(height: 8),
                  Showcase(
                    key: _wastageLogsKey,
                    description:
                        'Track and analyze wastage patterns to optimize operations and reduce costs.',
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
                          CupertinoPageRoute(
                            builder: (_) => WasteLogsTabScreen(),
                          ),
                        );
                      },
                    ),
                  ),
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

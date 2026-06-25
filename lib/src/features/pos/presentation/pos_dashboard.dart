import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:sandwich_ai/src/core/globals/notifications/notification_bell.dart';
import 'package:sandwich_ai/src/core/theme/app_theme_extension.dart';
import 'package:sandwich_ai/src/core/constant/textstyle.dart';
import 'package:sandwich_ai/src/features/pos/bloc/pos_dashboard_state_bloc/bloc.dart';
import 'package:sandwich_ai/src/features/pos/bloc/pos_dashboard_state_bloc/event.dart';
import 'package:sandwich_ai/src/features/pos/bloc/pos_dashboard_state_bloc/state.dart';

import 'package:sandwich_ai/src/features/pos/presentation/pos_drawer.dart';

class PosDashboardScreen extends StatefulWidget {
  const PosDashboardScreen({super.key});

  @override
  State<PosDashboardScreen> createState() => _PosDashboardScreenState();
}

class _PosDashboardScreenState extends State<PosDashboardScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    // Load dashboard data when screen initializes
    context.read<DashboardBloc>().add(const LoadDashboardSummary());
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTextStyle.merge(
      style: WorkSansAppTextStyles.medium,
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: const Color(0xFFF8F6F6),
        drawer: const PosAppDrawer(),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.menu, color: Colors.black),
            onPressed: () {
              _scaffoldKey.currentState?.openDrawer();
            },
          ),
          title: Text(
            'SandwichAI',
            style: WorkSansAppTextStyles.medium.copyWith(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          actions: [
            const NotificationBellAction(margin: EdgeInsets.zero),
            BlocBuilder<DashboardBloc, DashboardState>(
              builder: (context, state) {
                return IconButton(
                  icon: Icon(
                    Icons.refresh,
                    color: state is DashboardRefreshing
                        ? Colors.grey
                        : Colors.black,
                  ),
                  onPressed: state is DashboardRefreshing
                      ? null
                      : () {
                          context.read<DashboardBloc>().add(
                            const RefreshDashboardSummary(),
                          );
                        },
                );
              },
            ),
          ],
        ),
        body: BlocBuilder<DashboardBloc, DashboardState>(
          builder: (context, state) {
            if (state is DashboardLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state is DashboardError) {
              return _buildErrorState(state.error);
            }

            if (state is DashboardLoaded || state is DashboardRefreshing) {
              final summary = state is DashboardLoaded
                  ? state.summary
                  : (state as DashboardRefreshing).currentSummary;

              return LayoutBuilder(
                builder: (context, constraints) {
                  final horizontalPadding = _getHorizontalPadding(
                    constraints.maxWidth,
                  );
                  final iconSize = _getIconSize(constraints.maxWidth);
                  final cardTextSize = _getCardTextSize(constraints.maxWidth);
                  final headerTextSize = _getHeaderTextSize(
                    constraints.maxWidth,
                  );
                  final bodyTextSize = _getBodyTextSize(constraints.maxWidth);
                  final spacing = _getSpacing(constraints.maxWidth);

                  return Stack(
                    children: [
                      SingleChildScrollView(
                        padding: EdgeInsets.all(horizontalPadding),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Grid of Cards
                            GridView.count(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              crossAxisCount: 2,
                              crossAxisSpacing: spacing,
                              mainAxisSpacing: spacing,
                              childAspectRatio: 1.0,
                              children: [
                                _buildDashboardCard(
                                  icon: Icons.shopping_cart_outlined,
                                  label: 'New Order',
                                  iconSize: iconSize,
                                  textSize: cardTextSize,
                                  onTap: () {
                                    context.goNamed('Pos-nav', extra: 1);
                                  },
                                ),
                                _buildDashboardCard(
                                  icon: Icons.receipt_long_outlined,
                                  label: 'Active Orders',
                                  iconSize: iconSize,
                                  textSize: cardTextSize,
                                  onTap: () {
                                    context.goNamed('Pos-nav', extra: 2);
                                  },
                                ),
                              ],
                            ),
                            SizedBox(height: spacing * 2.5),

                            // Today's Snapshot Section
                            Text(
                              "Today's Snapshot",
                              style: WorkSansAppTextStyles.medium.copyWith(
                                fontSize: headerTextSize,
                                fontWeight: FontWeight.w600,
                                color: Colors.black,
                              ),
                            ),
                            SizedBox(height: spacing * 2.5),

                            // Snapshot Cards with real data
                            _buildSnapshotCard(
                              asset: 'assets/svg/ordersss.svg',
                              color: const Color(0xFFE3F2FD),
                              label: 'Orders',
                              value: '${summary.totalOrders}',
                              textSize: bodyTextSize,
                            ),
                            SizedBox(height: spacing * 0.7),
                            _buildSnapshotCard(
                              asset: 'assets/svg/sales.svg',
                              color: const Color(0xFFE8F5E9),
                              label: 'Sales',
                              value: summary.formattedSales,
                              textSize: bodyTextSize,
                            ),
                            SizedBox(height: spacing * 0.7),
                            _buildSnapshotCard(
                              asset: 'assets/svg/pending.svg',
                              color: const Color(0xFFFFF9C4),
                              label: 'Pending Orders',
                              value: '${summary.pendingOrders}',
                              textSize: bodyTextSize,
                            ),
                            SizedBox(height: spacing * 0.7),
                            _buildSnapshotCard(
                              asset: 'assets/svg/sales.svg',
                              color: const Color(0xFFE1F5FE),
                              label: 'Completed Orders',
                              value: '${summary.completedOrders}',
                              textSize: bodyTextSize,
                            ),
                            SizedBox(height: spacing * 0.7),
                            _buildSnapshotCard(
                              asset: 'assets/svg/sales.svg',
                              color: const Color(0xFFF3E5F5),
                              label: 'Avg Order Value',
                              value: summary.formattedAvgOrder,
                              textSize: bodyTextSize,
                            ),
                            SizedBox(height: 30),
                          ],
                        ),
                      ),
                      // Loading overlay during refresh
                      if (state is DashboardRefreshing)
                        Positioned(
                          top: 0,
                          left: 0,
                          right: 0,
                          child: LinearProgressIndicator(
                            backgroundColor: Colors.grey[200],
                            valueColor: AlwaysStoppedAnimation<Color>(kPrimary),
                          ),
                        ),
                    ],
                  );
                },
              );
            }

            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Oops! Something went wrong',
              style: WorkSansAppTextStyles.medium.copyWith(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: WorkSansAppTextStyles.medium.copyWith(
                fontSize: 14,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                context.read<DashboardBloc>().add(const LoadDashboardSummary());
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: kPrimary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardCard({
    required IconData icon,
    String? svg,
    required String label,
    required double iconSize,
    required double textSize,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: kPrimary,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            svg != null
                ? SvgPicture.asset(svg)
                : Icon(icon, size: iconSize, color: Colors.white),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  style: WorkSansAppTextStyles.medium.copyWith(
                    fontSize: textSize,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                Icon(Icons.arrow_right_outlined, color: kWhite),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSnapshotCard({
    required Color color,
    required String label,
    required String value,
    required double textSize,
    required String asset,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(8),
            ),
            child: SvgPicture.asset(asset, fit: BoxFit.scaleDown),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              label,
              style: WorkSansAppTextStyles.medium.copyWith(
                fontSize: textSize,
                fontWeight: FontWeight.w500,
                color: Colors.black,
              ),
            ),
          ),
          Text(
            value,
            style: WorkSansAppTextStyles.medium.copyWith(
              fontSize: textSize,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  // Responsive sizing functions
  double _getHorizontalPadding(double width) {
    if (width < 360) return 16;
    if (width < 600) return 20;
    if (width < 900) return 24;
    return 32;
  }

  double _getIconSize(double width) {
    if (width < 360) return 32;
    if (width < 600) return 36;
    if (width < 900) return 40;
    return 44;
  }

  double _getCardTextSize(double width) {
    if (width < 360) return 15;
    if (width < 600) return 16;
    if (width < 900) return 17;
    return 18;
  }

  double _getHeaderTextSize(double width) {
    if (width < 360) return 16;
    if (width < 600) return 17;
    if (width < 900) return 18;
    return 19;
  }

  double _getBodyTextSize(double width) {
    if (width < 360) return 14;
    if (width < 600) return 15;
    if (width < 900) return 16;
    return 17;
  }

  double _getSpacing(double width) {
    if (width < 360) return 12;
    if (width < 600) return 14;
    if (width < 900) return 16;
    return 18;
  }
}

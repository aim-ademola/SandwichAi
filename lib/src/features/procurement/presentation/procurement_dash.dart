import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:sandwich_ai/src/core/constant/appcolors.dart';
import 'package:sandwich_ai/src/core/constant/textstyle.dart';
import 'package:sandwich_ai/src/features/procurement/data/model/supplier_stat_model.dart';
import 'package:sandwich_ai/src/features/procurement/data/repository/procurement_order_repo.dart';
import 'package:sandwich_ai/src/features/procurement/data/repository/supplier_stat_repo.dart';

import 'package:sandwich_ai/src/features/procurement/presentation/procurement_drawer.dart';
import 'package:sandwich_ai/src/features/procurement/procurement_blocs/procurement_order_blocs/bloc.dart';
import 'package:sandwich_ai/src/features/procurement/procurement_blocs/procurement_order_blocs/event.dart';
import 'package:sandwich_ai/src/features/procurement/procurement_blocs/procurement_order_blocs/state.dart';
import 'package:sandwich_ai/src/features/procurement/procurement_blocs/supplier_stat_bloc/bloc.dart';
import 'package:sandwich_ai/src/features/procurement/procurement_blocs/supplier_stat_bloc/event.dart';
import 'package:sandwich_ai/src/features/procurement/procurement_blocs/supplier_stat_bloc/state.dart';

class ProcurementDashboardScreen extends StatefulWidget {
  const ProcurementDashboardScreen({super.key});

  @override
  State<ProcurementDashboardScreen> createState() =>
      _ProcurementDashboardScreenState();
}

class _ProcurementDashboardScreenState
    extends State<ProcurementDashboardScreen> {
  final int _selectedIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) =>
              SupplierStatsBloc(repository: SupplierStatsRepository())
                ..add(const LoadSupplierStats()),
        ),
        BlocProvider(
          create: (context) =>
              ProcurementBloc(repository: ProcurementRepository())
                ..add(LoadProcurementOrders(branchId: '')),
        ),
      ],
      child: DefaultTextStyle.merge(
        style: WorkSansAppTextStyles.medium,
        child: Scaffold(
          drawer: ProcurementAppDrawer(),
          key: _scaffoldKey,
          backgroundColor: const Color(0xFFF8F6F6),
          appBar: _buildAppBar(context),
          body: _buildBody(context),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.menu, color: kprimaryTextColor1),
        onPressed: () {
          _scaffoldKey.currentState?.openDrawer();
        },
      ),
      title: Text(
        'Dashboard',
        style: WorkSansAppTextStyles.medium.copyWith(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: kprimaryTextColor1,
        ),
      ),
      centerTitle: true,
    );
  }

  Widget _buildBody(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final horizontalPadding = _getHorizontalPadding(constraints.maxWidth);
        final maxContentWidth = _getMaxContentWidth(constraints.maxWidth);

        return RefreshIndicator(
          color: kPrimary,
          onRefresh: () async {
            context.read<SupplierStatsBloc>().add(const RefreshSupplierStats());
            context.read<ProcurementBloc>().add(RefreshProcurementOrders());

            await Future.delayed(const Duration(milliseconds: 500));
          },
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxContentWidth),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 24),
                    _buildStatusCards(constraints.maxWidth),
                    // const SizedBox(height: 32),
                    // _buildBudgetSection(constraints.maxWidth),
                    const SizedBox(height: 32),
                    _buildSuppliersSection(constraints.maxWidth),

                    // _buildRecentActivity(constraints.maxWidth),
                    const SizedBox(height: 60),
                    _buildActionButtons(constraints.maxWidth),
                    const SizedBox(height: 50),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusCards(double width) {
    final cardHeight = _getStatusCardHeight(width);
    final fontSize = _getStatusCardFontSize(width);
    final numberFontSize = _getStatusCardNumberSize(width);

    return BlocBuilder<ProcurementBloc, ProcurementState>(
      builder: (context, state) {
        int pendingCount = 0;
        int approvedCount = 0;
        int receivedCount = 0;

        if (state is ProcurementLoaded) {
          final allOrders = state.response.data;
          pendingCount = allOrders
              .where((order) => order.status == 'PENDING')
              .length;
          approvedCount = allOrders
              .where((order) => order.status == 'APPROVED')
              .length;
          receivedCount = allOrders
              .where((order) => order.status == 'RECEIVED')
              .length;
        } else if (state is ProcurementRefreshing) {
          final allOrders = state.currentData.data;
          pendingCount = allOrders
              .where((order) => order.status == 'PENDING')
              .length;
          approvedCount = allOrders
              .where((order) => order.status == 'APPROVED')
              .length;
          receivedCount = allOrders
              .where((order) => order.status == 'RECEIVED')
              .length;
        }

        return Row(
          children: [
            Expanded(
              child: _buildStatusCard(
                height: cardHeight,
                number: pendingCount.toString(),
                label: 'Pending',
                color: const Color(0xFFF7E9DD),
                numberColor: kPrimary,
                fontSize: fontSize,
                numberFontSize: numberFontSize,
                isLoading: state is ProcurementLoading,
              ),
            ),
            SizedBox(width: _getCardSpacing(width)),
            Expanded(
              child: _buildStatusCard(
                height: cardHeight,
                number: approvedCount.toString(),
                label: 'Approved',
                color: const Color(0xFFF7E9DD),
                numberColor: kPrimary,
                fontSize: fontSize,
                numberFontSize: numberFontSize,
                isLoading: state is ProcurementLoading,
              ),
            ),
            SizedBox(width: _getCardSpacing(width)),
            Expanded(
              child: _buildStatusCard(
                height: cardHeight,
                number: receivedCount.toString(),
                label: 'Received',
                color: const Color(0xFFF7E9DD),
                numberColor: kPrimary,
                fontSize: fontSize,
                numberFontSize: numberFontSize,
                isLoading: state is ProcurementLoading,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatusCard({
    required double height,
    required String number,
    required String label,
    required Color color,
    required Color numberColor,
    required double fontSize,
    required double numberFontSize,
    bool isLoading = false,
  }) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (isLoading)
            SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(numberColor),
              ),
            )
          else
            Text(
              number,
              style: WorkSansAppTextStyles.medium.copyWith(
                fontSize: numberFontSize,
                fontWeight: FontWeight.bold,
                color: numberColor,
              ),
            ),
          const SizedBox(height: 4),
          Text(
            label,
            style: WorkSansAppTextStyles.medium.copyWith(
              fontSize: fontSize,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF757575),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBudgetSection(double width) {
    final titleFontSize = _getSectionTitleSize(width);
    final budgetFontSize = _getBudgetFontSize(width);

    return Container(
      padding: EdgeInsets.all(_getContainerPadding(width)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Budget',
            style: WorkSansAppTextStyles.medium.copyWith(
              fontSize: titleFontSize,
              fontWeight: FontWeight.bold,
              color: kprimaryTextColor1,
            ),
          ),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              '₦350,000 / ₦500,000',
              style: WorkSansAppTextStyles.medium.copyWith(
                fontSize: budgetFontSize,
                fontWeight: FontWeight.w600,
                color: kprimaryTextColor1,
              ),
            ),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: 0.7,
              minHeight: _getProgressBarHeight(width),
              backgroundColor: const Color(0xFFFFE0CC),
              valueColor: const AlwaysStoppedAnimation<Color>(kPrimary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuppliersSection(double width) {
    final titleFontSize = _getSectionTitleSize(width);
    final supplierNumberSize = _getSupplierNumberSize(width);
    final supplierLabelSize = _getSupplierLabelSize(width);
    final cardHeight = _getSupplierCardHeight(width);

    return BlocBuilder<SupplierStatsBloc, SupplierStatsState>(
      builder: (context, state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Suppliers',
                  style: WorkSansAppTextStyles.medium.copyWith(
                    fontSize: titleFontSize,
                    fontWeight: FontWeight.bold,
                    color: kprimaryTextColor1,
                  ),
                ),
                if (state is SupplierStatsLoading)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(kPrimary),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            if (state is SupplierStatsError)
              _buildErrorState(state.error, width, context)
            else if (state is SupplierStatsLoaded)
              _buildSupplierStatsCards(
                state.stats,
                cardHeight,
                width,
                supplierNumberSize,
                supplierLabelSize,
              )
            else
              _buildSupplierStatsCards(
                SupplierStats.empty,
                cardHeight,
                width,
                supplierNumberSize,
                supplierLabelSize,
              ),
          ],
        );
      },
    );
  }

  Widget _buildErrorState(String error, double width, BuildContext context) {
    return Container(
      padding: EdgeInsets.all(_getContainerPadding(width)),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade200, width: 1),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red.shade700, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Failed to load supplier stats',
                  style: WorkSansAppTextStyles.medium.copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.red.shade700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  error,
                  style: WorkSansAppTextStyles.medium.copyWith(
                    fontSize: 12,
                    color: Colors.red.shade600,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.refresh, color: Colors.red.shade700),
            onPressed: () {
              context.read<SupplierStatsBloc>().add(const LoadSupplierStats());
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSupplierStatsCards(
    SupplierStats stats,
    double cardHeight,
    double width,
    double supplierNumberSize,
    double supplierLabelSize,
  ) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildSupplierStatCard(
                height: cardHeight,
                value: stats.onTimeDeliveryPercentage.toStringAsFixed(0) + '%',
                label: 'On-Time Delivery',
                width: width,
                numberSize: supplierNumberSize,
                labelSize: supplierLabelSize,
                showPercentage: false,
              ),
            ),
            SizedBox(width: _getCardSpacing(width)),
            Expanded(
              child: _buildSupplierStatCard(
                height: cardHeight,
                value: stats.averageRating.toStringAsFixed(1),
                label: 'Average Rating',
                width: width,
                numberSize: supplierNumberSize,
                labelSize: supplierLabelSize,
              ),
            ),
          ],
        ),
        SizedBox(height: _getCardSpacing(width)),
        Row(
          children: [
            Expanded(
              child: _buildSupplierStatCard(
                height: cardHeight,
                value: stats.totalSuppliers.toString(),
                label: 'Total Suppliers',
                width: width,
                numberSize: supplierNumberSize,
                labelSize: supplierLabelSize,
              ),
            ),
            SizedBox(width: _getCardSpacing(width)),
            Expanded(
              child: _buildSupplierStatCard(
                height: cardHeight,
                value: stats.activeSuppliers.toString(),
                label: 'Active Suppliers',
                width: width,
                numberSize: supplierNumberSize,
                labelSize: supplierLabelSize,
              ),
            ),
          ],
        ),
        SizedBox(height: _getCardSpacing(width)),
        Row(
          children: [
            Expanded(
              child: _buildSupplierStatCard(
                height: cardHeight,
                value: stats.pendingSuppliers.toString(),
                label: 'Pending Suppliers',
                width: width,
                numberSize: supplierNumberSize,
                labelSize: supplierLabelSize,
                valueColor: const Color(0xFFFF9800),
              ),
            ),
            SizedBox(width: _getCardSpacing(width)),
            Expanded(
              child: _buildSupplierStatCard(
                height: cardHeight,
                value: stats.verifiedSuppliers.toString(),
                label: 'Verified Suppliers',
                width: width,
                numberSize: supplierNumberSize,
                labelSize: supplierLabelSize,
                valueColor: const Color(0xFF4CAF50),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSupplierStatCard({
    required double height,
    required String value,
    required String label,
    required double width,
    required double numberSize,
    required double labelSize,
    Color? valueColor,
    bool showPercentage = false,
  }) {
    return Container(
      height: height,
      padding: EdgeInsets.all(_getContainerPadding(width)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE0E0E0), width: 1),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            value,
            style: WorkSansAppTextStyles.medium.copyWith(
              fontSize: numberSize,
              fontWeight: FontWeight.bold,
              color: valueColor ?? kprimaryTextColor1,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: WorkSansAppTextStyles.medium.copyWith(
              fontSize: labelSize,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF757575),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivity(double width) {
    final titleFontSize = _getSectionTitleSize(width);
    final activityTitleSize = _getActivityTitleSize(width);
    final activitySubtitleSize = _getActivitySubtitleSize(width);
    final iconSize = _getActivityIconSize(width);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Activity',
          style: WorkSansAppTextStyles.medium.copyWith(
            fontSize: titleFontSize,
            fontWeight: FontWeight.bold,
            color: kprimaryTextColor1,
          ),
        ),
        const SizedBox(height: 16),
        _buildActivityItem(
          icon: Icons.access_time,
          iconColor: const Color(0xFFFFB74D),
          iconBgColor: const Color(0xFFF6DEC7),
          title: 'Pending Approval',
          subtitle: 'Order #12345 from Fresh Veggies Inc.',
          width: width,
          activityTitleSize: activityTitleSize,
          activitySubtitleSize: activitySubtitleSize,
          iconSize: iconSize,
        ),
        const SizedBox(height: 12),
        _buildActivityItem(
          icon: Icons.local_shipping_outlined,
          iconColor: const Color(0xFFFF5722),
          iconBgColor: const Color(0xFFF6DEC7),
          title: 'Delayed Delivery',
          subtitle: 'Order #67890 is running late',
          width: width,
          activityTitleSize: activityTitleSize,
          activitySubtitleSize: activitySubtitleSize,
          iconSize: iconSize,
        ),
      ],
    );
  }

  Widget _buildActivityItem({
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    required String title,
    required String subtitle,
    required double width,
    required double activityTitleSize,
    required double activitySubtitleSize,
    required double iconSize,
  }) {
    return Container(
      padding: EdgeInsets.all(_getContainerPadding(width)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: iconSize,
            height: iconSize,
            decoration: BoxDecoration(
              color: iconBgColor,
              borderRadius: BorderRadius.circular(100),
            ),
            child: Icon(icon, color: iconColor, size: iconSize * 0.5),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: WorkSansAppTextStyles.medium.copyWith(
                    fontSize: activityTitleSize,
                    fontWeight: FontWeight.w600,
                    color: kprimaryTextColor1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: WorkSansAppTextStyles.medium.copyWith(
                    fontSize: activitySubtitleSize,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFF757575),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(double width) {
    final buttonHeight = _getButtonHeight(width);
    final buttonFontSize = _getButtonFontSize(width);

    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: buttonHeight,
            child: ElevatedButton(
              onPressed: () {
                context.push('/order-form');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: kPrimary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'New Order',
                style: WorkSansAppTextStyles.medium.copyWith(
                  fontSize: buttonFontSize,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                  color: kWhite,
                ),
              ),
            ),
          ),
        ),
        SizedBox(width: _getCardSpacing(width)),
        Expanded(
          child: SizedBox(
            height: buttonHeight,
            child: OutlinedButton(
              onPressed: () {
                context.push('/order-list');
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: kPrimary,
                side: const BorderSide(color: kPrimary, width: 1.5),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'View All Order',
                style: WorkSansAppTextStyles.medium.copyWith(
                  fontSize: buttonFontSize,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                  color: kPrimary,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Responsive sizing functions
  double _getHorizontalPadding(double width) {
    if (width < 360) return 16;
    if (width < 600) return 20;
    if (width < 900) return 32;
    return 48;
  }

  double _getMaxContentWidth(double width) {
    if (width < 600) return double.infinity;
    if (width < 900) return 600;
    return 800;
  }

  double _getStatusCardHeight(double width) {
    if (width < 360) return 80;
    if (width < 600) return 90;
    return 100;
  }

  double _getStatusCardFontSize(double width) {
    if (width < 360) return 12;
    if (width < 600) return 13;
    return 14;
  }

  double _getStatusCardNumberSize(double width) {
    if (width < 360) return 28;
    if (width < 600) return 32;
    return 36;
  }

  double _getCardSpacing(double width) {
    if (width < 360) return 12;
    if (width < 600) return 16;
    return 20;
  }

  double _getContainerPadding(double width) {
    if (width < 360) return 16;
    if (width < 600) return 20;
    return 24;
  }

  double _getSectionTitleSize(double width) {
    if (width < 360) return 16;
    if (width < 600) return 18;
    return 20;
  }

  double _getBudgetFontSize(double width) {
    if (width < 360) return 16;
    if (width < 600) return 18;
    return 20;
  }

  double _getProgressBarHeight(double width) {
    if (width < 360) return 8;
    if (width < 600) return 10;
    return 12;
  }

  double _getSupplierCardHeight(double width) {
    if (width < 360) return 100;
    if (width < 600) return 110;
    return 120;
  }

  double _getSupplierNumberSize(double width) {
    if (width < 360) return 28;
    if (width < 600) return 32;
    return 36;
  }

  double _getSupplierLabelSize(double width) {
    if (width < 360) return 12;
    if (width < 600) return 13;
    return 14;
  }

  double _getActivityIconSize(double width) {
    if (width < 360) return 40;
    if (width < 600) return 48;
    return 56;
  }

  double _getActivityTitleSize(double width) {
    if (width < 360) return 14;
    if (width < 600) return 15;
    return 16;
  }

  double _getActivitySubtitleSize(double width) {
    if (width < 360) return 12;
    if (width < 600) return 13;
    return 14;
  }

  double _getButtonHeight(double width) {
    if (width < 360) return 48;
    if (width < 600) return 52;
    return 56;
  }

  double _getButtonFontSize(double width) {
    if (width < 360) return 14;
    if (width < 600) return 15;
    return 16;
  }
}

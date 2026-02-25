import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sandwich_ai/src/core/constant/appcolors.dart';
import 'package:sandwich_ai/src/core/constant/textstyle.dart';
import 'package:sandwich_ai/src/features/procurement/data/model/procurement_order_model.dart';
import 'package:sandwich_ai/src/features/procurement/presentation/Procurement_req_dtls.dart';
import 'package:sandwich_ai/src/features/procurement/presentation/procurement_drawer.dart';
import 'package:sandwich_ai/src/features/procurement/presentation/order_form.dart'; // Add this import
import 'package:sandwich_ai/src/features/procurement/procurement_blocs/procurement_order_blocs/bloc.dart';
import 'package:sandwich_ai/src/features/procurement/procurement_blocs/procurement_order_blocs/event.dart';
import 'package:sandwich_ai/src/features/procurement/procurement_blocs/procurement_order_blocs/state.dart';

class ProcurementOrdersScreen extends StatefulWidget {
  const ProcurementOrdersScreen({super.key});

  @override
  State<ProcurementOrdersScreen> createState() =>
      _ProcurementOrdersScreenState();
}

class _ProcurementOrdersScreenState extends State<ProcurementOrdersScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(_onTabChanged);
    context.read<ProcurementBloc>().add(
      LoadProcurementOrders(branchId: context.read<ProcurementBloc>().branchId),
    );
  }

  void _onTabChanged() {
    final statuses = ['PENDING', 'APPROVED', 'REJECTED', 'COMPLETED'];
    context.read<ProcurementBloc>().add(
      FilterByStatus(status: statuses[_tabController.index]),
    );
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTextStyle.merge(
      style: WorkSansAppTextStyles.medium,
      child: Scaffold(
        drawer: ProcurementAppDrawer(),
        key: _scaffoldKey,
        backgroundColor: const Color(0xFFF8F6F6),
        appBar: _buildAppBar(context),
        body: _buildBody(context),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.menu, color: Colors.black),
        onPressed: () {
          _scaffoldKey.currentState?.openDrawer();
        },
      ),
      title: Text(
        'Procurement Requests',
        style: WorkSansAppTextStyles.medium.copyWith(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Colors.black,
        ),
      ),
      centerTitle: true,
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh, color: Colors.black),
          onPressed: () {
            context.read<ProcurementBloc>().add(
              const RefreshProcurementOrders(),
            );
          },
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(48),
        child: BlocBuilder<ProcurementBloc, ProcurementState>(
          builder: (context, state) {
            return _buildTabBar(state);
          },
        ),
      ),
    );
  }

  Widget _buildTabBar(ProcurementState state) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final tabFontSize = _getTabFontSize(constraints.maxWidth);

        int pendingCount = 0;
        int approvedCount = 0;
        int rejectedCount = 0;
        int completedCount = 0;

        if (state is ProcurementLoaded) {
          pendingCount = state.pendingCount;
          approvedCount = state.approvedCount;
          rejectedCount = state.rejectedCount;
          completedCount = state.completedCount;
        }

        return Container(
          color: Colors.white,
          child: TabBar(
            controller: _tabController,
            isScrollable: false,
            labelColor: kPrimary,
            unselectedLabelColor: const Color(0xFF757575),
            labelStyle: WorkSansAppTextStyles.medium.copyWith(
              fontSize: tabFontSize,
              fontWeight: FontWeight.w600,
            ),
            unselectedLabelStyle: WorkSansAppTextStyles.medium.copyWith(
              fontSize: tabFontSize,
              fontWeight: FontWeight.w500,
            ),
            indicatorColor: kPrimary,
            indicatorWeight: 3,
            tabs: [
              Tab(text: 'Pending ($pendingCount)'),
              Tab(text: 'Approved ($approvedCount)'),
              Tab(text: 'Rejected ($rejectedCount)'),
              Tab(text: 'Completed ($completedCount)'),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBody(BuildContext context) {
    return BlocBuilder<ProcurementBloc, ProcurementState>(
      builder: (context, state) {
        if (state is ProcurementLoading) {
          return const Center(
            child: CircularProgressIndicator(color: kPrimary),
          );
        }

        if (state is ProcurementError) {
          return _buildErrorState(state);
        }

        if (state is ProcurementEmpty) {
          return _buildEmptyState();
        }

        if (state is ProcurementLoaded) {
          return _buildOrderList(state.filteredOrders);
        }

        if (state is ProcurementRefreshing) {
          final filteredOrders = state.currentData.getByStatus(
            state.selectedStatus,
          );

          return Stack(
            children: [
              _buildOrderList(filteredOrders),
              const Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: LinearProgressIndicator(color: kPrimary),
              ),
            ],
          );
        }

        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildErrorState(ProcurementError state) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(_getErrorIcon(state.errorType), size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              state.error,
              style: WorkSansAppTextStyles.medium.copyWith(
                fontSize: 16,
                color: const Color(0xFF757575),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                context.read<ProcurementBloc>().add(
                  LoadProcurementOrders(
                    branchId: context.read<ProcurementBloc>().branchId,
                  ),
                );
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: kPrimary,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.receipt_long_outlined,
            size: 64,
            color: Color(0xFF757575),
          ),
          const SizedBox(height: 16),
          Text(
            'No procurement orders found',
            style: WorkSansAppTextStyles.medium.copyWith(
              fontSize: 16,
              color: const Color(0xFF757575),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderList(List<ProcurementRequest> orders) {
    if (orders.isEmpty) {
      return Center(
        child: Text(
          'No orders in this category',
          style: WorkSansAppTextStyles.medium.copyWith(
            fontSize: 16,
            color: const Color(0xFF757575),
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final horizontalPadding = _getHorizontalPadding(constraints.maxWidth);
        final maxContentWidth = _getMaxContentWidth(constraints.maxWidth);

        return Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxContentWidth),
            child: ListView.separated(
              padding: EdgeInsets.symmetric(
                horizontal: horizontalPadding,
                vertical: 16,
              ),
              itemCount: orders.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                return _buildOrderCard(orders[index], constraints.maxWidth);
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildOrderCard(ProcurementRequest order, double screenWidth) {
    final supplierFontSize = _getSupplierFontSize(screenWidth);
    final orderNumberFontSize = _getOrderNumberFontSize(screenWidth);
    final amountFontSize = _getAmountFontSize(screenWidth);
    final statusFontSize = _getStatusFontSize(screenWidth);
    final isApproved = order.status.toUpperCase() == 'APPROVED';

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          CupertinoPageRoute(
            builder: (context) => ProcurementDetailsScreen(order: order),
          ),
        );
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: EdgeInsets.all(_getCardPadding(screenWidth)),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE0E0E0), width: 1),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        order.requestedBy,
                        style: WorkSansAppTextStyles.medium.copyWith(
                          fontSize: supplierFontSize,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Order ${order.requestId}',
                        style: WorkSansAppTextStyles.medium.copyWith(
                          fontSize: orderNumberFontSize,
                          fontWeight: FontWeight.w400,
                          color: const Color(0xFF757575),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${order.itemCount} item${order.itemCount != 1 ? 's' : ''}',
                        style: WorkSansAppTextStyles.medium.copyWith(
                          fontSize: orderNumberFontSize - 1,
                          fontWeight: FontWeight.w400,
                          color: const Color(0xFF757575),
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '₦${_formatAmount(order.totalAmountDouble)}',
                      style: WorkSansAppTextStyles.medium.copyWith(
                        fontSize: amountFontSize,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildStatusBadge(
                      order.status,
                      statusFontSize,
                      screenWidth,
                    ),
                  ],
                ),
              ],
            ),
            if (order.priority == 'URGENT') ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.warning, size: 14, color: Colors.red.shade700),
                    const SizedBox(width: 4),
                    Text(
                      'URGENT',
                      style: WorkSansAppTextStyles.medium.copyWith(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.red.shade700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            // Order Item button for approved orders
            if (isApproved) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      CupertinoPageRoute(
                        builder: (context) => OrderFormScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.shopping_cart, size: 18),
                  label: Text(
                    'Order Item',
                    style: WorkSansAppTextStyles.medium.copyWith(
                      fontSize: _getButtonFontSize(screenWidth),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPrimary,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(
                      vertical: _getButtonPaddingVertical(screenWidth),
                      horizontal: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status, double fontSize, double screenWidth) {
    Color bgColor;
    Color textColor;

    switch (status.toUpperCase()) {
      case 'PENDING':
        bgColor = const Color(0xFFF7EADD);
        textColor = kPrimary;
        break;
      case 'APPROVED':
        bgColor = const Color(0xFFE8F5E9);
        textColor = const Color(0xFF4CAF50);
        break;
      case 'REJECTED':
        bgColor = const Color(0xFFFFEBEE);
        textColor = const Color(0xFFE53935);
        break;
      case 'COMPLETED':
        bgColor = const Color(0xFFE3F2FD);
        textColor = const Color(0xFF1976D2);
        break;
      default:
        bgColor = const Color(0xFFF5F5F5);
        textColor = const Color(0xFF757575);
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: _getStatusPaddingHorizontal(screenWidth),
        vertical: _getStatusPaddingVertical(screenWidth),
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        status,
        style: WorkSansAppTextStyles.medium.copyWith(
          fontSize: fontSize,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }

  String _formatAmount(double amount) {
    if (amount >= 1000) {
      return (amount / 1000).toStringAsFixed(amount % 1000 == 0 ? 0 : 1);
    }
    return amount.toStringAsFixed(2);
  }

  IconData _getErrorIcon(ProcurementErrorType errorType) {
    switch (errorType) {
      case ProcurementErrorType.network:
        return Icons.wifi_off;
      case ProcurementErrorType.timeout:
        return Icons.access_time;
      case ProcurementErrorType.server:
        return Icons.cloud_off;
      default:
        return Icons.error_outline;
    }
  }

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

  double _getTabFontSize(double width) {
    if (width < 360) return 11;
    if (width < 600) return 12;
    return 13;
  }

  double _getCardPadding(double width) {
    if (width < 360) return 16;
    if (width < 600) return 18;
    return 20;
  }

  double _getSupplierFontSize(double width) {
    if (width < 360) return 15;
    if (width < 600) return 16;
    return 17;
  }

  double _getOrderNumberFontSize(double width) {
    if (width < 360) return 12;
    if (width < 600) return 13;
    return 14;
  }

  double _getAmountFontSize(double width) {
    if (width < 360) return 16;
    if (width < 600) return 17;
    return 18;
  }

  double _getStatusFontSize(double width) {
    if (width < 360) return 11;
    if (width < 600) return 12;
    return 13;
  }

  double _getStatusPaddingHorizontal(double width) {
    if (width < 360) return 10;
    if (width < 600) return 12;
    return 14;
  }

  double _getStatusPaddingVertical(double width) {
    if (width < 360) return 4;
    if (width < 600) return 5;
    return 6;
  }

  double _getButtonFontSize(double width) {
    if (width < 360) return 13;
    if (width < 600) return 14;
    return 15;
  }

  double _getButtonPaddingVertical(double width) {
    if (width < 360) return 10;
    if (width < 600) return 12;
    return 14;
  }
}

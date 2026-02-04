import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:sandwich_ai/src/core/constant/appcolors.dart';
import 'package:sandwich_ai/src/core/constant/textstyle.dart';

import 'package:sandwich_ai/src/features/kitchen/blocs/kitchen-dash_bloc/bloc.dart';
import 'package:sandwich_ai/src/features/kitchen/blocs/kitchen-dash_bloc/event.dart';
import 'package:sandwich_ai/src/features/kitchen/blocs/kitchen-dash_bloc/state.dart';
import 'package:sandwich_ai/src/features/kitchen/data/model/kitchen_dash_model.dart';
import 'package:sandwich_ai/src/features/kitchen/presentation/kitchen_drawer.dart';

class KitchenDashboardScreen extends StatefulWidget {
  const KitchenDashboardScreen({super.key});

  @override
  State<KitchenDashboardScreen> createState() => _KitchenDashboardScreenState();
}

class _KitchenDashboardScreenState extends State<KitchenDashboardScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // Track which order is currently being updated
  String? _updatingOrderId;

  @override
  void initState() {
    super.initState();
    context.read<KitchenDashboardBloc>().add(const LoadDashboardData());
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTextStyle.merge(
      style: WorkSansAppTextStyles.medium,
      child: Scaffold(
        drawer: KitchenAppDrawer(),
        key: _scaffoldKey,
        backgroundColor: const Color(0xFFF8F6F6),
        appBar: _buildAppBar(context),
        body: BlocConsumer<KitchenDashboardBloc, KitchenDashboardState>(
          listener: (context, state) {
            if (state is OrderActionSuccess) {
              // Set loading state when action starts
              setState(() {
                _updatingOrderId = state.orderId;
              });

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: Colors.green,
                  behavior: SnackBarBehavior.floating,
                  duration: const Duration(milliseconds: 1500),
                ),
              );
            } else if (state is OrderActionError) {
              setState(() {
                _updatingOrderId = null;
              });

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.error),
                  backgroundColor: Colors.red,
                  behavior: SnackBarBehavior.floating,
                  duration: const Duration(seconds: 3),
                ),
              );
            } else if (state is DashboardLoaded) {
              // Clear loading state when data is refreshed
              setState(() {
                _updatingOrderId = null;
              });
            }
          },
          buildWhen: (previous, current) {
            // Don't rebuild for OrderActionSuccess/Error - they're just for snackbars
            return current is! OrderActionSuccess &&
                current is! OrderActionError;
          },
          builder: (context, state) {
            if (state is DashboardLoading) {
              return _buildLoadingState();
            } else if (state is DashboardLoaded) {
              return _buildLoadedState(
                context,
                state.dashboardData,
                state.filteredOrders,
                state.currentFilter,
                isRefreshing: false,
              );
            } else if (state is DashboardRefreshing) {
              return _buildLoadedState(
                context,
                state.currentData,
                state.currentData.recentOrders,
                OrderFilter.all,
                isRefreshing: true,
              );
            } else if (state is DashboardEmpty) {
              return _buildEmptyState();
            } else if (state is DashboardError) {
              return _buildErrorState(state);
            }
            return _buildLoadingState();
          },
        ),
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
        'Live Orders',
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
            context.read<KitchenDashboardBloc>().add(
              const RefreshDashboardData(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: kPrimary),
          const SizedBox(height: 16),
          Text(
            'Loading dashboard...',
            style: WorkSansAppTextStyles.medium.copyWith(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long_outlined, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No orders yet',
            style: WorkSansAppTextStyles.medium.copyWith(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Orders will appear here once customers place them',
            style: WorkSansAppTextStyles.medium.copyWith(
              fontSize: 14,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              context.read<KitchenDashboardBloc>().add(
                const RefreshDashboardData(),
              );
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Refresh'),
            style: ElevatedButton.styleFrom(
              backgroundColor: kPrimary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(DashboardError state) {
    IconData errorIcon;
    String errorTitle;
    String errorMessage;

    switch (state.errorType) {
      case DashboardErrorType.network:
        errorIcon = Icons.wifi_off;
        errorTitle = 'No Internet Connection';
        errorMessage = 'Please check your network and try again';
        break;
      case DashboardErrorType.timeout:
        errorIcon = Icons.timer_off;
        errorTitle = 'Connection Timeout';
        errorMessage = 'The request took too long. Please try again';
        break;
      case DashboardErrorType.server:
        errorIcon = Icons.cloud_off;
        errorTitle = 'Server Error';
        errorMessage = 'Something went wrong on our end';
        break;
      default:
        errorIcon = Icons.error_outline;
        errorTitle = 'Something Went Wrong';
        errorMessage = state.error;
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(errorIcon, size: 80, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text(
              errorTitle,
              style: WorkSansAppTextStyles.medium.copyWith(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              errorMessage,
              style: WorkSansAppTextStyles.medium.copyWith(
                fontSize: 14,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                context.read<KitchenDashboardBloc>().add(
                  const LoadDashboardData(),
                );
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

  Widget _buildLoadedState(
    BuildContext context,
    KitchenDashboardData dashboardData,
    List<KitchenOrder> filteredOrders,
    OrderFilter currentFilter, {
    bool isRefreshing = false,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final horizontalPadding = _getHorizontalPadding(constraints.maxWidth);
        final maxContentWidth = _getMaxContentWidth(constraints.maxWidth);

        return RefreshIndicator(
          onRefresh: () async {
            context.read<KitchenDashboardBloc>().add(
              const RefreshDashboardData(),
            );
            await Future.delayed(const Duration(seconds: 1));
          },
          color: kPrimary,
          child: Stack(
            children: [
              Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: maxContentWidth),
                  child: ListView(
                    padding: EdgeInsets.symmetric(
                      horizontal: horizontalPadding,
                      vertical: 16,
                    ),
                    children: [
                      _buildStatsCards(dashboardData, constraints.maxWidth),
                      SizedBox(
                        height: _getSectionSpacing(constraints.maxWidth),
                      ),
                      _buildFilterTabs(currentFilter, constraints.maxWidth),
                      SizedBox(
                        height: _getSectionSpacing(constraints.maxWidth),
                      ),
                      if (filteredOrders.isEmpty)
                        _buildNoOrdersForFilter(currentFilter)
                      else
                        ...filteredOrders.map(
                          (order) => Padding(
                            padding: EdgeInsets.only(
                              bottom: _getOrderSpacing(constraints.maxWidth),
                            ),
                            child: _buildOrderCard(order, constraints.maxWidth),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              if (isRefreshing)
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: LinearProgressIndicator(
                    backgroundColor: Colors.transparent,
                    valueColor: AlwaysStoppedAnimation<Color>(kPrimary),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildNoOrdersForFilter(OrderFilter filter) {
    String message;
    switch (filter) {
      case OrderFilter.newOrder:
        message = 'No new orders';
        break;
      case OrderFilter.inProgress:
        message = 'No orders in progress';
        break;
      case OrderFilter.completed:
        message = 'No completed orders';
        break;
      default:
        message = 'No orders';
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(Icons.filter_list_off, size: 60, color: Colors.grey[400]),
            const SizedBox(height: 12),
            Text(
              message,
              style: WorkSansAppTextStyles.medium.copyWith(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsCards(KitchenDashboardData data, double screenWidth) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Ongoing',
            '${data.orderStats.ongoingOrders}',
            const Color.fromARGB(255, 254, 226, 180),
            kPrimary,
            Icons.pending_actions,
            screenWidth,
          ),
        ),
        SizedBox(width: _getCardSpacing(screenWidth)),
        Expanded(
          child: _buildStatCard(
            'Delivered',
            '${data.orderStats.ordersDelivered}',
            const Color.fromARGB(255, 176, 251, 182),
            const Color(0xFF4CAF50),
            Icons.check_circle,
            screenWidth,
          ),
        ),
        SizedBox(width: _getCardSpacing(screenWidth)),
        Expanded(
          child: _buildStatCard(
            'Staff',
            '${data.staffOnDuty.total}',
            const Color.fromARGB(255, 168, 216, 250),
            const Color(0xFF2196F3),
            Icons.people,
            screenWidth,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    Color bgColor,
    Color valueColor,
    IconData icon,
    double screenWidth,
  ) {
    final labelFontSize = _getStatLabelFontSize(screenWidth);
    final valueFontSize = _getStatValueFontSize(screenWidth);
    final iconSize = _getStatIconSize(screenWidth);

    return Container(
      padding: EdgeInsets.all(_getStatCardPadding(screenWidth)),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: WorkSansAppTextStyles.medium.copyWith(
                  fontSize: labelFontSize,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF757575),
                ),
              ),
              Icon(icon, size: iconSize, color: valueColor.withOpacity(0.7)),
            ],
          ),
          SizedBox(height: _getStatValueSpacing(screenWidth)),
          Text(
            value,
            style: WorkSansAppTextStyles.medium.copyWith(
              fontSize: valueFontSize,
              fontWeight: FontWeight.w700,
              color: valueColor,
              height: 1.1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterTabs(OrderFilter currentFilter, double screenWidth) {
    final tabFontSize = _getTabFontSize(screenWidth);
    final tabPadding = _getTabPadding(screenWidth);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildFilterTab(
            'All',
            OrderFilter.all,
            kPrimary,
            tabFontSize,
            tabPadding,
            currentFilter,
          ),
          SizedBox(width: _getTabSpacing(screenWidth)),
          _buildFilterTab(
            'New',
            OrderFilter.newOrder,
            kPrimary,
            tabFontSize,
            tabPadding,
            currentFilter,
            borderColor: const Color(0xFFE0E0E0),
          ),
          SizedBox(width: _getTabSpacing(screenWidth)),
          _buildFilterTab(
            'In Progress',
            OrderFilter.inProgress,
            kPrimary,
            tabFontSize,
            tabPadding,
            currentFilter,
            borderColor: const Color(0xFFE0E0E0),
          ),
          SizedBox(width: _getTabSpacing(screenWidth)),
          _buildFilterTab(
            'Completed',
            OrderFilter.completed,
            kPrimary,
            tabFontSize,
            tabPadding,
            currentFilter,
            borderColor: const Color(0xFFE0E0E0),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterTab(
    String label,
    OrderFilter filter,
    Color bgColor,
    double fontSize,
    double padding,
    OrderFilter currentFilter, {
    Color? borderColor,
  }) {
    final isSelected = currentFilter == filter;

    return GestureDetector(
      onTap: () {
        context.read<KitchenDashboardBloc>().add(FilterOrders(filter));
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(
          horizontal: padding,
          vertical: padding * 0.6,
        ),
        decoration: BoxDecoration(
          color: isSelected ? bgColor : Colors.white,
          borderRadius: BorderRadius.circular(100),
          border: Border.all(
            color: isSelected ? bgColor : (borderColor ?? Colors.transparent),
            width: 1.5,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: bgColor.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [],
        ),
        child: Text(
          label,
          style: WorkSansAppTextStyles.medium.copyWith(
            fontSize: fontSize,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : Colors.black,
          ),
        ),
      ),
    );
  }

  Widget _buildOrderCard(KitchenOrder order, double screenWidth) {
    final orderNumberFontSize = _getOrderNumberFontSize(screenWidth);
    final itemsFontSize = _getOrderItemsFontSize(screenWidth);
    final statusFontSize = _getOrderStatusFontSize(screenWidth);
    final timeAgoFontSize = _getTimeAgoFontSize(screenWidth);

    // Check if this order is being updated
    final isUpdating = _updatingOrderId == order.id;

    Color borderColor;
    Color statusColor;
    String statusText;
    String? buttonText;
    Color? buttonColor;
    VoidCallback? onButtonPressed;

    switch (order.status.toUpperCase()) {
      case 'PENDING':
        borderColor = const Color(0xFF2196F3);
        statusColor = const Color(0xFF2196F3);
        statusText = 'NEW ORDER';
        buttonText = 'Start Preparation';
        buttonColor = kPrimary;
        onButtonPressed = isUpdating
            ? null
            : () {
                setState(() {
                  _updatingOrderId = order.id;
                });
                context.read<KitchenDashboardBloc>().add(
                  StartOrderPreparation(order.id),
                );
              };
        break;
      case 'PREPARING':
        borderColor = const Color(0xFFFFA726);
        statusColor = const Color(0xFFFFA726);
        statusText = 'IN PROGRESS';
        buttonText = 'Mark as Ready';
        buttonColor = kPrimary;
        onButtonPressed = isUpdating
            ? null
            : () {
                setState(() {
                  _updatingOrderId = order.id;
                });
                context.read<KitchenDashboardBloc>().add(
                  MarkOrderAsReady(order.id),
                );
              };
        break;
      case 'READY':
      case 'COMPLETED':
        borderColor = const Color(0xFF4CAF50);
        statusColor = const Color(0xFF4CAF50);
        statusText = 'READY';
        buttonText = null;
        buttonColor = null;
        onButtonPressed = null;
        break;
      case 'CANCELLED':
        borderColor = const Color(0xFFE57373);
        statusColor = const Color(0xFFE57373);
        statusText = 'CANCELLED';
        buttonText = null;
        buttonColor = null;
        onButtonPressed = null;
        break;
      default:
        borderColor = Colors.grey;
        statusColor = Colors.grey;
        statusText = order.status;
        buttonText = null;
        buttonColor = null;
        onButtonPressed = null;
    }

    return GestureDetector(
      onTap: () {
        context.pushNamed(
          'kitchen-order-details',
          pathParameters: {'orderNumber': order.orderId},
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border(left: BorderSide(color: borderColor, width: 5)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.all(_getOrderCardPadding(screenWidth)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: borderColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          order.orderId,
                          style: WorkSansAppTextStyles.medium.copyWith(
                            fontSize: orderNumberFontSize,
                            fontWeight: FontWeight.w700,
                            color: borderColor,
                          ),
                        ),
                      ),
                      if (order.tableNumber != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.table_restaurant,
                                size: 14,
                                color: Colors.grey[700],
                              ),
                              const SizedBox(width: 4),
                              Text(
                                order.tableNumber!,
                                style: WorkSansAppTextStyles.medium.copyWith(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey[700],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 14,
                        color: Colors.grey[500],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        order.getTimeAgo(),
                        style: WorkSansAppTextStyles.medium.copyWith(
                          fontSize: timeAgoFontSize,
                          fontWeight: FontWeight.w400,
                          color: const Color(0xFF9E9E9E),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              SizedBox(height: _getOrderContentSpacing(screenWidth)),
              Text(
                order.customerName,
                style: WorkSansAppTextStyles.medium.copyWith(
                  fontSize: itemsFontSize + 1,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              SizedBox(height: _getOrderContentSpacing(screenWidth) / 2),
              Text(
                order.getItemsSummary(),
                style: WorkSansAppTextStyles.medium.copyWith(
                  fontSize: itemsFontSize,
                  fontWeight: FontWeight.w400,
                  color: Colors.grey[700],
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (order.specialInstructions != null) ...[
                SizedBox(height: _getOrderContentSpacing(screenWidth) / 2),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.amber[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.amber[200]!),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 16,
                        color: Colors.amber[800],
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          order.specialInstructions!,
                          style: WorkSansAppTextStyles.medium.copyWith(
                            fontSize: itemsFontSize - 1,
                            fontWeight: FontWeight.w500,
                            color: Colors.amber[900],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              SizedBox(height: _getOrderContentSpacing(screenWidth)),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      statusText,
                      style: WorkSansAppTextStyles.medium.copyWith(
                        fontSize: statusFontSize,
                        fontWeight: FontWeight.w700,
                        color: statusColor,
                      ),
                    ),
                  ),
                  Text(
                    '₦${order.totalAmount}',
                    style: WorkSansAppTextStyles.medium.copyWith(
                      fontSize: orderNumberFontSize,
                      fontWeight: FontWeight.w700,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
              if (buttonText != null) ...[
                SizedBox(height: _getOrderButtonSpacing(screenWidth)),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: onButtonPressed,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: buttonColor,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(
                        vertical: _getButtonPaddingVertical(screenWidth),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 0,
                    ),
                    child: isUpdating
                        ? SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : Text(
                            buttonText,
                            style: WorkSansAppTextStyles.medium.copyWith(
                              fontSize: _getButtonFontSize(screenWidth),
                              fontWeight: FontWeight.w600,
                              color: kWhite,
                            ),
                          ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
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

  double _getSectionSpacing(double width) {
    if (width < 360) return 16;
    if (width < 600) return 20;
    return 24;
  }

  double _getCardSpacing(double width) {
    if (width < 360) return 8;
    if (width < 600) return 10;
    return 12;
  }

  double _getStatCardPadding(double width) {
    if (width < 360) return 12;
    if (width < 600) return 14;
    return 16;
  }

  double _getStatLabelFontSize(double width) {
    if (width < 360) return 11;
    if (width < 600) return 12;
    return 13;
  }

  double _getStatValueFontSize(double width) {
    if (width < 360) return 24;
    if (width < 600) return 28;
    return 32;
  }

  double _getStatIconSize(double width) {
    if (width < 360) return 18;
    if (width < 600) return 20;
    return 22;
  }

  double _getStatValueSpacing(double width) {
    if (width < 360) return 4;
    if (width < 600) return 6;
    return 8;
  }

  double _getOrderSpacing(double width) {
    if (width < 360) return 12;
    if (width < 600) return 14;
    return 16;
  }

  double _getOrderCardPadding(double width) {
    if (width < 360) return 14;
    if (width < 600) return 16;
    return 18;
  }

  double _getOrderNumberFontSize(double width) {
    if (width < 360) return 14;
    if (width < 600) return 15;
    return 16;
  }

  double _getOrderItemsFontSize(double width) {
    if (width < 360) return 13;
    if (width < 600) return 14;
    return 15;
  }

  double _getOrderStatusFontSize(double width) {
    if (width < 360) return 11;
    if (width < 600) return 12;
    return 13;
  }

  double _getTimeAgoFontSize(double width) {
    if (width < 360) return 11;
    if (width < 600) return 12;
    return 13;
  }

  double _getOrderContentSpacing(double width) {
    if (width < 360) return 10;
    if (width < 600) return 12;
    return 14;
  }

  double _getOrderButtonSpacing(double width) {
    if (width < 360) return 12;
    if (width < 600) return 14;
    return 16;
  }

  double _getButtonPaddingVertical(double width) {
    if (width < 360) return 14;
    if (width < 600) return 16;
    return 18;
  }

  double _getButtonFontSize(double width) {
    if (width < 360) return 14;
    if (width < 600) return 15;
    return 16;
  }

  double _getTabFontSize(double width) {
    if (width < 360) return 13;
    if (width < 600) return 14;
    return 15;
  }

  double _getTabPadding(double width) {
    if (width < 360) return 16;
    if (width < 600) return 18;
    return 20;
  }

  double _getTabSpacing(double width) {
    if (width < 360) return 8;
    if (width < 600) return 10;
    return 12;
  }
}

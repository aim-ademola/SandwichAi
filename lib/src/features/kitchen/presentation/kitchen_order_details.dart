import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sandwich_ai/src/core/constant/appcolors.dart';
import 'package:sandwich_ai/src/core/constant/textstyle.dart';
import 'package:sandwich_ai/src/features/kitchen/blocs/kitchen-dash_bloc/bloc.dart';
import 'package:sandwich_ai/src/features/kitchen/blocs/kitchen-dash_bloc/event.dart';
import 'package:sandwich_ai/src/features/kitchen/blocs/kitchen-dash_bloc/state.dart';
import 'package:sandwich_ai/src/features/kitchen/data/model/kitchen_dash_model.dart';

class KitchenOrderDetailScreen extends StatefulWidget {
  final String orderNumber;

  const KitchenOrderDetailScreen({super.key, required this.orderNumber});

  @override
  State<KitchenOrderDetailScreen> createState() =>
      _KitchenOrderDetailScreenState();
}

class _KitchenOrderDetailScreenState extends State<KitchenOrderDetailScreen> {
  Map<String, bool> _itemCompletionStatus = {};

  // Track which order is being updated
  String? _updatingOrderId;

  // Cache the last loaded state
  DashboardLoaded? _lastLoadedState;

  @override
  Widget build(BuildContext context) {
    return DefaultTextStyle.merge(
      style: WorkSansAppTextStyles.medium,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F6F6),
        appBar: _buildAppBar(context),
        body: BlocConsumer<KitchenDashboardBloc, KitchenDashboardState>(
          listener: (context, state) {
            if (state is OrderActionSuccess) {
              // Clear loading state
              setState(() {
                _updatingOrderId = null;
              });

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: Colors.green,
                  behavior: SnackBarBehavior.floating,
                  duration: const Duration(seconds: 2),
                ),
              );
            } else if (state is OrderActionError) {
              // Clear loading state
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
              // Cache the loaded state and clear loading
              setState(() {
                _lastLoadedState = state;
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
            KitchenDashboardData? dashboardData;

            if (state is DashboardLoading) {
              return _buildLoadingState();
            } else if (state is DashboardLoaded) {
              _lastLoadedState = state;
              dashboardData = state.dashboardData;
            } else if (state is DashboardRefreshing) {
              dashboardData = state.currentData;
            } else if (state is DashboardError) {
              return _buildErrorState(state);
            } else {
              // For any other state, try to use cached data
              if (_lastLoadedState != null) {
                dashboardData = _lastLoadedState!.dashboardData;
              } else {
                return _buildLoadingState();
              }
            }

            final order = _findOrder(dashboardData.recentOrders);

            if (order == null) {
              return _buildOrderNotFoundState();
            }

            // Initialize completion status for items
            if (_itemCompletionStatus.isEmpty && order.items.isNotEmpty) {
              for (var item in order.items) {
                _itemCompletionStatus[item.id] = false;
              }
            }

            return _buildOrderDetailBody(
              context,
              order,
              state is DashboardRefreshing,
            );
          },
        ),
      ),
    );
  }

  KitchenOrder? _findOrder(List<KitchenOrder> orders) {
    try {
      return orders.firstWhere((order) => order.orderId == widget.orderNumber);
    } catch (e) {
      return null;
    }
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.black),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: Text(
        'Order ${widget.orderNumber}',
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
            'Loading order details...',
            style: WorkSansAppTextStyles.medium.copyWith(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderNotFoundState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Order Not Found',
              style: WorkSansAppTextStyles.medium.copyWith(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Order ${widget.orderNumber} could not be found',
              style: WorkSansAppTextStyles.medium.copyWith(
                fontSize: 14,
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.arrow_back),
              label: const Text('Go Back'),
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

  Widget _buildErrorState(DashboardError state) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 80, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text(
              'Error Loading Order',
              style: WorkSansAppTextStyles.medium.copyWith(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              state.error,
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

  Widget _buildOrderDetailBody(
    BuildContext context,
    KitchenOrder order,
    bool isRefreshing,
  ) {
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
                  child: Column(
                    children: [
                      Expanded(
                        child: ListView(
                          padding: EdgeInsets.symmetric(
                            horizontal: horizontalPadding,
                            vertical: 16,
                          ),
                          children: [
                            _buildOrderInfoCard(order, constraints.maxWidth),
                            SizedBox(
                              height: _getSectionSpacing(constraints.maxWidth),
                            ),
                            _buildCustomerInfoCard(order, constraints.maxWidth),
                            SizedBox(
                              height: _getSectionSpacing(constraints.maxWidth),
                            ),
                            _buildOrderStatusCard(order, constraints.maxWidth),
                            SizedBox(
                              height: _getSectionSpacing(constraints.maxWidth),
                            ),
                            _buildItemsToPrepareCard(
                              order,
                              constraints.maxWidth,
                            ),
                          ],
                        ),
                      ),
                      _buildBottomButtons(
                        order,
                        constraints.maxWidth,
                        horizontalPadding,
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

  Widget _buildOrderInfoCard(KitchenOrder order, double screenWidth) {
    final titleFontSize = _getSectionTitleFontSize(screenWidth);
    final textFontSize = _getBodyFontSize(screenWidth);

    return Container(
      padding: EdgeInsets.all(_getCardPadding(screenWidth)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
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
                'Order Information',
                style: WorkSansAppTextStyles.medium.copyWith(
                  fontSize: titleFontSize,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: kPrimary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  order.orderType,
                  style: WorkSansAppTextStyles.medium.copyWith(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: kPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildInfoRow('Order ID', order.orderId, textFontSize),
          const SizedBox(height: 12),
          _buildInfoRow('Time Ordered', order.getTimeAgo(), textFontSize),
          if (order.tableNumber != null) ...[
            const SizedBox(height: 12),
            _buildInfoRow('Table', order.tableNumber!, textFontSize),
          ],
          const SizedBox(height: 12),
          _buildInfoRow(
            'Total Amount',
            '₦${order.totalAmount}',
            textFontSize,
            isHighlight: true,
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerInfoCard(KitchenOrder order, double screenWidth) {
    final titleFontSize = _getSectionTitleFontSize(screenWidth);
    final textFontSize = _getBodyFontSize(screenWidth);

    return Container(
      padding: EdgeInsets.all(_getCardPadding(screenWidth)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Customer Information',
            style: WorkSansAppTextStyles.medium.copyWith(
              fontSize: titleFontSize,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 16),
          _buildInfoRow(
            'Name',
            order.customerName.isEmpty
                ? 'Walk-in Customer'
                : order.customerName,
            textFontSize,
          ),
          const SizedBox(height: 12),
          _buildInfoRow(
            'Phone',
            order.customerPhone.isEmpty ? 'N/A' : order.customerPhone,
            textFontSize,
          ),
          if (order.specialInstructions != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.amber[200]!),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline, size: 20, color: Colors.amber[800]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Special Instructions',
                          style: WorkSansAppTextStyles.medium.copyWith(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.amber[900],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          order.specialInstructions!,
                          style: WorkSansAppTextStyles.medium.copyWith(
                            fontSize: textFontSize,
                            fontWeight: FontWeight.w500,
                            color: Colors.amber[900],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(
    String label,
    String value,
    double fontSize, {
    bool isHighlight = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: WorkSansAppTextStyles.medium.copyWith(
            fontSize: fontSize,
            fontWeight: FontWeight.w400,
            color: const Color(0xFF757575),
          ),
        ),
        Flexible(
          child: Text(
            value,
            style: WorkSansAppTextStyles.medium.copyWith(
              fontSize: fontSize,
              fontWeight: isHighlight ? FontWeight.w700 : FontWeight.w500,
              color: isHighlight ? kPrimary : Colors.black87,
            ),
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }

  Widget _buildOrderStatusCard(KitchenOrder order, double screenWidth) {
    final titleFontSize = _getSectionTitleFontSize(screenWidth);

    String statusText;
    Color statusBgColor;
    Color statusTextColor;

    switch (order.status.toUpperCase()) {
      case 'PENDING':
        statusText = 'New Order';
        statusBgColor = const Color(0xFFE3F2FD);
        statusTextColor = const Color(0xFF2196F3);
        break;
      case 'IN_QUEUE':
        statusText = 'In Queue';
        statusBgColor = const Color(0xFFE3F2FD);
        statusTextColor = const Color(0xFF2196F3);
        break;
      case 'CONFIRMED':
        statusText = 'Confirmed';
        statusBgColor = const Color(0xFFF3E5F5);
        statusTextColor = const Color(0xFF9C27B0);
        break;
      case 'PREPARING':
        statusText = 'In Progress';
        statusBgColor = const Color(0xFFFFF3E0);
        statusTextColor = kPrimary;
        break;
      case 'READY':
        statusText = 'Ready';
        statusBgColor = const Color(0xFFE0F7FA);
        statusTextColor = const Color(0xFF26C6DA);
        break;
      case 'SERVED':
        statusText = 'Served';
        statusBgColor = const Color(0xFFE8F5E9);
        statusTextColor = const Color(0xFF4CAF50);
        break;
      case 'COMPLETED':
        statusText = 'Completed';
        statusBgColor = const Color(0xFFE8F5E9);
        statusTextColor = const Color(0xFF388E3C);
        break;
      case 'CANCELLED':
        statusText = 'Cancelled';
        statusBgColor = const Color(0xFFFFEBEE);
        statusTextColor = const Color(0xFFE57373);
        break;
      default:
        statusText = order.status;
        statusBgColor = Colors.grey[200]!;
        statusTextColor = Colors.grey[700]!;
    }

    return Container(
      padding: EdgeInsets.all(_getCardPadding(screenWidth)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Order Status',
            style: WorkSansAppTextStyles.medium.copyWith(
              fontSize: titleFontSize,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: _getBadgePaddingHorizontal(screenWidth),
              vertical: _getBadgePaddingVertical(screenWidth),
            ),
            decoration: BoxDecoration(
              color: statusBgColor,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              statusText,
              style: WorkSansAppTextStyles.medium.copyWith(
                fontSize: _getBadgeFontSize(screenWidth),
                fontWeight: FontWeight.w700,
                color: statusTextColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemsToPrepareCard(KitchenOrder order, double screenWidth) {
    final titleFontSize = _getSectionTitleFontSize(screenWidth);
    final itemNameFontSize = _getItemNameFontSize(screenWidth);
    final itemNotesFontSize = _getItemNotesFontSize(screenWidth);

    // Calculate completion percentage
    int completedCount = _itemCompletionStatus.values.where((v) => v).length;
    int totalCount = order.items.length;
    double progress = totalCount > 0 ? completedCount / totalCount : 0;

    // Determine title and progress visibility based on order status
    String itemsTitle;
    bool showProgress;
    bool showCheckboxes;
    Color progressColor;

    // REPLACE the switch in _buildItemsToPrepareCard:
    switch (order.status.toUpperCase()) {
      case 'PENDING':
      case 'IN_QUEUE':
      case 'CONFIRMED':
        itemsTitle = 'Items to Prepare';
        showProgress = false;
        showCheckboxes = false;
        progressColor = kPrimary;
        break;
      case 'PREPARING':
        itemsTitle = 'Items Being Prepared';
        showProgress = true;
        showCheckboxes = true;
        progressColor = const Color(0xFFFFA726);
        break;
      case 'READY':
      case 'SERVED':
      case 'COMPLETED':
        itemsTitle = 'Items Prepared';
        showProgress = true;
        showCheckboxes = false;
        progressColor = const Color(0xFF4CAF50);
        progress = 1.0;
        completedCount = totalCount;
        break;
      case 'CANCELLED':
        itemsTitle = 'Items Cancelled';
        showProgress = false;
        showCheckboxes = false;
        progressColor = const Color(0xFFE57373);
        break;
      default:
        itemsTitle = 'Order Items';
        showProgress = false;
        showCheckboxes = false;
        progressColor = Colors.grey;
    }
    return Container(
      padding: EdgeInsets.all(_getCardPadding(screenWidth)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
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
                itemsTitle,
                style: WorkSansAppTextStyles.medium.copyWith(
                  fontSize: titleFontSize,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
              if (showProgress)
                Text(
                  '$completedCount/$totalCount',
                  style: WorkSansAppTextStyles.medium.copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: progressColor,
                  ),
                ),
            ],
          ),
          if (showProgress) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                minHeight: 6,
              ),
            ),
          ],
          SizedBox(height: _getItemsListSpacing(screenWidth)),
          ...order.items.asMap().entries.map((entry) {
            final index = entry.key;
            final isLast = index == order.items.length - 1;
            final item = entry.value;

            return Column(
              children: [
                _buildOrderItem(
                  item,
                  itemNameFontSize,
                  itemNotesFontSize,
                  screenWidth,
                  showCheckboxes: showCheckboxes,
                  isOrderCompleted:
                      order.status.toUpperCase() == 'READY' ||
                      order.status.toUpperCase() == 'COMPLETED',
                  isOrderCancelled: order.status.toUpperCase() == 'CANCELLED',
                ),
                if (!isLast)
                  Padding(
                    padding: EdgeInsets.symmetric(
                      vertical: _getItemDividerSpacing(screenWidth),
                    ),
                    child: const Divider(
                      color: Color(0xFFE0E0E0),
                      thickness: 1,
                      height: 1,
                    ),
                  ),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildOrderItem(
    OrderItem item,
    double nameFontSize,
    double notesFontSize,
    double screenWidth, {
    required bool showCheckboxes,
    required bool isOrderCompleted,
    required bool isOrderCancelled,
  }) {
    final isChecked = _itemCompletionStatus[item.id] ?? false;
    final dishName = item.menuItem?.dishName ?? 'Unknown Item';

    // Determine visual state
    final shouldShowAsCompleted = isOrderCompleted;
    final shouldShowAsCancelled = isOrderCancelled;
    final shouldShowAsChecked = showCheckboxes && isChecked;

    return Padding(
      padding: EdgeInsets.symmetric(
        vertical: _getItemPaddingVertical(screenWidth),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showCheckboxes)
            SizedBox(
              width: 24,
              height: 24,
              child: Checkbox(
                value: isChecked,
                onChanged: (value) {
                  setState(() {
                    _itemCompletionStatus[item.id] = value ?? false;
                  });
                },
                activeColor: const Color(0xFFFFA726),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            )
          else if (shouldShowAsCompleted)
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: const Color(0xFF4CAF50),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Icon(Icons.check, color: Colors.white, size: 16),
            )
          else if (shouldShowAsCancelled)
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: const Color(0xFFE57373),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Icon(Icons.close, color: Colors.white, size: 16),
            )
          else
            SizedBox(
              width: 24,
              height: 24,
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[400]!, width: 2),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${item.quantity}x $dishName',
                  style: WorkSansAppTextStyles.medium.copyWith(
                    fontSize: nameFontSize,
                    fontWeight: FontWeight.w600,
                    color: (shouldShowAsChecked || shouldShowAsCancelled)
                        ? const Color(0xFF9E9E9E)
                        : Colors.black,
                    decoration: (shouldShowAsChecked || shouldShowAsCancelled)
                        ? TextDecoration.lineThrough
                        : TextDecoration.none,
                  ),
                ),
                if (item.specialRequest != null &&
                    item.specialRequest!.isNotEmpty) ...[
                  SizedBox(height: _getItemNotesSpacing(screenWidth)),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.orange[50],
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      item.specialRequest!,
                      style: WorkSansAppTextStyles.medium.copyWith(
                        fontSize: notesFontSize,
                        fontWeight: FontWeight.w500,
                        color: (shouldShowAsChecked || shouldShowAsCancelled)
                            ? const Color(0xFFBDBDBD)
                            : Colors.orange[900],
                        decoration:
                            (shouldShowAsChecked || shouldShowAsCancelled)
                            ? TextDecoration.lineThrough
                            : TextDecoration.none,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 4),
                Text(
                  '₦${item.totalPrice}',
                  style: WorkSansAppTextStyles.medium.copyWith(
                    fontSize: notesFontSize,
                    fontWeight: FontWeight.w600,
                    color: (shouldShowAsChecked || shouldShowAsCancelled)
                        ? const Color(0xFFBDBDBD)
                        : const Color(0xFF757575),
                    decoration: (shouldShowAsChecked || shouldShowAsCancelled)
                        ? TextDecoration.lineThrough
                        : TextDecoration.none,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomButtons(
    KitchenOrder order,
    double screenWidth,
    double horizontalPadding,
  ) {
    final buttonFontSize = _getButtonFontSize(screenWidth);
    final buttonHeight = _getButtonHeight(screenWidth);

    final isCompleted =
        order.status.toUpperCase() == 'COMPLETED' ||
        order.status.toUpperCase() == 'SERVED';
    final isCancelled = order.status.toUpperCase() == 'CANCELLED';

    // Check if this specific order is being updated
    final isUpdating = _updatingOrderId == order.id;

    return Container(
      padding: EdgeInsets.all(horizontalPadding),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!isCompleted && !isCancelled)
            SizedBox(
              width: double.infinity,
              height: buttonHeight,
              child: ElevatedButton(
                onPressed: isUpdating
                    ? null
                    : () {
                        setState(() => _updatingOrderId = order.id);
                        final bloc = context.read<KitchenDashboardBloc>();
                        switch (order.status.toUpperCase()) {
                          case 'IN_QUEUE':
                            bloc.add(MarkOrderAsComfirmed(order.id));
                            break;
                          case 'CONFIRMED':
                            bloc.add(StartOrderPreparation(order.id));
                            break;
                          case 'PREPARING':
                            bloc.add(MarkOrderAsReady(order.id));
                            break;
                          case 'READY':
                            bloc.add(MarkOrderAsServed(order.id));
                            break;
                          case 'SERVED':
                            bloc.add(MarkOrderAsCompleted(order.id));
                            break;
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
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
                        _getMainButtonText(order.status),
                        style: WorkSansAppTextStyles.medium.copyWith(
                          fontSize: buttonFontSize,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          if (!isCancelled) ...[
            // SizedBox(height: _getButtonSpacing(screenWidth)),
            // SizedBox(
            //   width: double.infinity,
            //   height: buttonHeight,
            //   child: ElevatedButton(
            //     onPressed: () {
            //       _showFlagForHelpDialog(context);
            //     },
            //     style: ElevatedButton.styleFrom(
            //       backgroundColor: const Color(0xFFE0E0E0),
            //       shape: RoundedRectangleBorder(
            //         borderRadius: BorderRadius.circular(12),
            //       ),
            //       elevation: 0,
            //     ),
            //     child: Text(
            //       'Flag for Help',
            //       style: WorkSansAppTextStyles.medium.copyWith(
            //         fontSize: buttonFontSize,
            //         fontWeight: FontWeight.w600,
            //         color: const Color(0xFF757575),
            //       ),
            //     ),
            //   ),
            // ),
          ],
        ],
      ),
    );
  }

  String _getMainButtonText(String status) {
    switch (status.toUpperCase()) {
      case 'PENDING':
        return 'Start Preparation';
      case 'PREPARING':
        return 'Mark as Ready';
      case 'READY':
      case 'COMPLETED':
        return 'Ready for Pickup';
      case 'IN_QUEUE':
        return 'Confirm Order';
      case 'CONFIRMED':
        return 'Start Preparation';

      case 'SERVED':
        return 'Mark as Completed';

      default:
        return 'Update Status';
    }
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

  double _getSectionSpacing(double width) {
    if (width < 360) return 16;
    if (width < 600) return 20;
    return 24;
  }

  double _getCardPadding(double width) {
    if (width < 360) return 16;
    if (width < 600) return 18;
    return 20;
  }

  double _getSectionTitleFontSize(double width) {
    if (width < 360) return 16;
    if (width < 600) return 17;
    return 18;
  }

  double _getBodyFontSize(double width) {
    if (width < 360) return 14;
    if (width < 600) return 15;
    return 16;
  }

  double _getBadgePaddingHorizontal(double width) {
    if (width < 360) return 12;
    if (width < 600) return 14;
    return 16;
  }

  double _getBadgePaddingVertical(double width) {
    if (width < 360) return 6;
    if (width < 600) return 7;
    return 8;
  }

  double _getBadgeFontSize(double width) {
    if (width < 360) return 12;
    if (width < 600) return 13;
    return 14;
  }

  double _getItemsListSpacing(double width) {
    if (width < 360) return 16;
    if (width < 600) return 18;
    return 20;
  }

  double _getItemPaddingVertical(double width) {
    if (width < 360) return 12;
    if (width < 600) return 14;
    return 16;
  }

  double _getItemNameFontSize(double width) {
    if (width < 360) return 15;
    if (width < 600) return 16;
    return 17;
  }

  double _getItemNotesFontSize(double width) {
    if (width < 360) return 13;
    if (width < 600) return 14;
    return 15;
  }

  double _getItemNotesSpacing(double width) {
    if (width < 360) return 4;
    if (width < 600) return 5;
    return 6;
  }

  double _getItemDividerSpacing(double width) {
    if (width < 360) return 8;
    if (width < 600) return 10;
    return 12;
  }

  double _getButtonHeight(double width) {
    if (width < 360) return 48;
    if (width < 600) return 52;
    return 56;
  }

  double _getButtonFontSize(double width) {
    if (width < 360) return 15;
    if (width < 600) return 16;
    return 17;
  }
}

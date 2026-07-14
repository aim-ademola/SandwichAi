import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:sandwich_ai/src/core/local_sandbox/cache_manager.dart';
import 'package:sandwich_ai/src/core/theme/app_theme_extension.dart';
import 'package:sandwich_ai/src/core/constant/textstyle.dart';
import 'package:sandwich_ai/src/features/pos/bloc/order_status_bloc/bloc.dart';
import 'package:sandwich_ai/src/features/pos/bloc/order_status_bloc/event.dart';
import 'package:sandwich_ai/src/features/pos/bloc/order_status_bloc/state.dart';
import 'package:sandwich_ai/src/features/pos/data/model/oder_status_model.dart';
import 'package:sandwich_ai/src/features/pos/data/repository/pos_order_repo.dart';
import 'package:sandwich_ai/src/features/pos/presentation/active_order_dtls.dart';

class ActiveOrdersScreen extends StatefulWidget {
  const ActiveOrdersScreen({super.key});

  @override
  State<ActiveOrdersScreen> createState() => _ActiveOrdersScreenState();
}

class _ActiveOrdersScreenState extends State<ActiveOrdersScreen> {
  static const String _paymentPendingFilter = 'PAYMENT_PENDING';

  String? _selectedStatus;
  KitchenOrder? _selectedOrder;
  String? _confirmingOrderId;

  @override
  void initState() {
    super.initState();
    context.read<KitchenOrdersBloc>().add(const LoadKitchenOrders());
  }

  @override
  Widget build(BuildContext context) {
    final selectedOrder = _selectedOrder;
    if (selectedOrder != null) {
      return OrderDetailScreen(
        order: selectedOrder,
        onBack: () => setState(() => _selectedOrder = null),
        onConfirmPending: selectedOrder.status == OrderStatus.pending
            ? () async {
                await _confirmPendingOrder(selectedOrder);
                if (mounted) {
                  setState(() => _selectedOrder = null);
                }
              }
            : null,
      );
    }

    return DefaultTextStyle.merge(
      style: WorkSansAppTextStyles.medium,
      child: Scaffold(
        backgroundColor: context.modeBackground,
        appBar: AppBar(
          backgroundColor: context.modeSurface,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
          title: Text(
            'Active Orders',
            style: WorkSansAppTextStyles.medium.copyWith(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: context.modeTextPrimary,
            ),
          ),
          centerTitle: true,
        ),
        body: LayoutBuilder(
          builder: (context, constraints) {
            final horizontalPadding = _getHorizontalPadding(
              constraints.maxWidth,
            );
            final verticalSpacing = _getVerticalSpacing(constraints.maxWidth);

            return Column(
              children: [
                _buildSearchAndFilterBar(horizontalPadding, verticalSpacing),
                Expanded(
                  child: BlocBuilder<KitchenOrdersBloc, KitchenOrdersState>(
                    builder: (context, state) {
                      if (state is KitchenOrdersLoading) {
                        return Center(
                          child: CircularProgressIndicator(
                            color: context.modePrimary,
                          ),
                        );
                      }

                      if (state is KitchenOrdersError) {
                        return _buildErrorState(
                          state,
                          horizontalPadding,
                          constraints.maxWidth,
                        );
                      }

                      if (state is KitchenOrdersEmpty) {
                        return _buildEmptyState(
                          horizontalPadding,
                          constraints.maxWidth,
                        );
                      }

                      if (state is KitchenOrdersLoaded ||
                          state is KitchenOrdersRefreshing) {
                        final orders =
                            (state is KitchenOrdersLoaded
                                    ? state.filteredOrders
                                    : (state as KitchenOrdersRefreshing)
                                          .currentData)
                                .where(_isActiveOrder)
                                .toList();
                        if (_selectedStatus == _paymentPendingFilter) {
                          orders.removeWhere(
                            (order) => !_isPaymentPendingOrder(order),
                          );
                        }
                        if (orders.isEmpty) {
                          return _buildEmptyState(
                            horizontalPadding,
                            constraints.maxWidth,
                          );
                        }

                        return RefreshIndicator(
                          color: context.modePrimary,
                          onRefresh: () async {
                            context.read<KitchenOrdersBloc>().add(
                              const RefreshKitchenOrders(),
                            );
                          },
                          child: ListView.separated(
                            padding: EdgeInsets.symmetric(
                              horizontal: horizontalPadding,
                              vertical: verticalSpacing,
                            ),
                            itemCount: orders.length,
                            separatorBuilder: (context, index) =>
                                SizedBox(height: verticalSpacing),
                            itemBuilder: (context, index) {
                              return _buildOrderCard(
                                orders[index],
                                _getBodyTextSize(constraints.maxWidth),
                              );
                            },
                          ),
                        );
                      }

                      return const SizedBox.shrink();
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildSearchAndFilterBar(
    double horizontalPadding,
    double verticalSpacing,
  ) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: horizontalPadding,
        vertical: verticalSpacing,
      ),
      color: context.modeSurface,
      child: Column(
        children: [
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _buildFilterChip('All', null),
                const SizedBox(width: 8),
                _buildFilterChip('Pending', OrderStatus.pending.value),
                const SizedBox(width: 8),
                _buildFilterChip('Confirmed', OrderStatus.confirmed.value),
                const SizedBox(width: 8),
                _buildFilterChip('Preparing', OrderStatus.preparing.value),
                const SizedBox(width: 8),
                _buildFilterChip('Ready', OrderStatus.ready.value),
                const SizedBox(width: 8),
                _buildFilterChip('Served', OrderStatus.served.value),
                const SizedBox(width: 8),
                _buildFilterChip('Payment Pending', _paymentPendingFilter),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String? status) {
    final isSelected = _selectedStatus == status;
    return FilterChip(
      label: Text(
        label,
        style: WorkSansAppTextStyles.medium.copyWith(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: isSelected ? context.modeTextInverse : context.modeTextPrimary,
        ),
      ),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedStatus = selected ? status : null;
        });
        context.read<KitchenOrdersBloc>().add(
          FilterKitchenOrdersByStatus(
            status: status == _paymentPendingFilter ? null : status,
          ),
        );
      },
      backgroundColor: context.modeSurfaceAlt,
      selectedColor: context.modePrimary,
      checkmarkColor: context.modeTextInverse,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      showCheckmark: false,
    );
  }

  Widget _buildOrderCard(KitchenOrder order, double textSize) {
    final amount = double.tryParse(order.totalAmount.toString()) ?? 0;
    final formattedAmount = NumberFormat('#,##0.##').format(amount);
    final isServedUnpaid =
        order.status == OrderStatus.served && !_hasPayment(order);
    final itemCount = order.items.length;
    final cancellationReason = order.cancellationReason?.trim();
    final hasCancellationReason =
        order.status == OrderStatus.cancelled &&
        cancellationReason != null &&
        cancellationReason.isNotEmpty;

    return InkWell(
      onTap: () {
        setState(() => _selectedOrder = order);
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
        decoration: BoxDecoration(
          color: context.modeSurface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: _getStatusColor(order.status).withValues(alpha: 0.38),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 42,
                  height: 42,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: _getStatusColor(
                      order.status,
                    ).withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _getStatusIcon(order.status),
                    size: 21,
                    color: _getStatusColor(order.status),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              order.orderId,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: WorkSansAppTextStyles.medium.copyWith(
                                fontSize: textSize + 1,
                                fontWeight: FontWeight.w800,
                                color: context.modeTextPrimary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          InkWell(
                            onTap: () => _copyOrderId(order.orderId),
                            borderRadius: BorderRadius.circular(6),
                            child: Padding(
                              padding: const EdgeInsets.all(4),
                              child: Icon(
                                Icons.copy_rounded,
                                size: 15,
                                color: context.modeTextMuted,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: [
                          _buildInfoChip(
                            icon: order.orderType == OrderType.dineIn
                                ? Icons.table_restaurant_outlined
                                : Icons.shopping_bag_outlined,
                            label: _orderLocationLabel(order),
                            textSize: textSize,
                          ),
                          _buildInfoChip(
                            icon: Icons.schedule_rounded,
                            label: _formatTimeAgo(order.orderedAt),
                            textSize: textSize,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                _buildStatusPill(order.status, textSize),
              ],
            ),
            if ((order.customerName ?? '').trim().isNotEmpty) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.person_outline_rounded,
                    size: 16,
                    color: context.modeTextMuted,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      order.customerName!.trim(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: WorkSansAppTextStyles.medium.copyWith(
                        fontSize: textSize - 1,
                        fontWeight: FontWeight.w600,
                        color: context.modeTextSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ],
            if (hasCancellationReason) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: context.modeError.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: context.modeError.withValues(alpha: 0.34),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      size: 17,
                      color: context.modeError,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Cancellation reason: $cancellationReason',
                        style: WorkSansAppTextStyles.medium.copyWith(
                          fontSize: textSize - 2,
                          fontWeight: FontWeight.w700,
                          color: context.modeTextPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 12),
            Divider(height: 1, color: context.modeDivider),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Text(
                    '$itemCount item${itemCount == 1 ? '' : 's'}',
                    style: WorkSansAppTextStyles.medium.copyWith(
                      fontSize: textSize - 1,
                      fontWeight: FontWeight.w600,
                      color: context.modeTextMuted,
                    ),
                  ),
                ),
                Text(
                  '\u20A6$formattedAmount',
                  style: WorkSansAppTextStyles.medium.copyWith(
                    fontSize: textSize + 1,
                    fontWeight: FontWeight.w900,
                    color: context.modeTextPrimary,
                  ),
                ),
              ],
            ),
            if (isServedUnpaid) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: context.modeWarning.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: context.modeWarning.withValues(alpha: 0.42),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.payments_outlined,
                      size: 17,
                      color: context.modeWarning,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Served - payment pending',
                        style: WorkSansAppTextStyles.medium.copyWith(
                          fontSize: textSize - 2,
                          fontWeight: FontWeight.w800,
                          color: context.modeTextPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (order.status == OrderStatus.pending) ...[
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                height: 42,
                child: ElevatedButton.icon(
                  onPressed: _confirmingOrderId == order.id
                      ? null
                      : () => _confirmPendingOrder(order),
                  icon: _confirmingOrderId == order.id
                      ? SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: context.modeTextInverse,
                          ),
                        )
                      : const Icon(Icons.check_circle_outline, size: 18),
                  label: Text(
                    _confirmingOrderId == order.id
                        ? 'Confirming...'
                        : 'Confirm Order',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: context.modePrimary,
                    foregroundColor: context.modeTextInverse,
                    disabledBackgroundColor: context.modePrimary.withValues(
                      alpha: 0.55,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _confirmPendingOrder(KitchenOrder order) async {
    setState(() => _confirmingOrderId = order.id);

    final employeeId = await AuthCacheHelper.instance.getEmpID() ?? '';
    if (!mounted) return;

    if (employeeId.isEmpty) {
      setState(() => _confirmingOrderId = null);
      _showSnack(
        'Employee ID not found. Please login again.',
        context.modeError,
      );
      return;
    }

    final response = await context
        .read<PosOrderRepositoryInterface>()
        .updateOrderStatus(
          orderId: order.id,
          status: OrderStatus.confirmed.value,
          updatedBy: employeeId,
        );

    if (!mounted) return;

    setState(() => _confirmingOrderId = null);

    if (response.isSuccess) {
      _showSnack('Order confirmed and sent to kitchen.', context.modeSuccess);
      context.read<KitchenOrdersBloc>().add(const RefreshKitchenOrders());
    } else {
      _showSnack(
        response.error?.toString() ?? 'Failed to confirm order.',
        context.modeError,
      );
    }
  }

  void _showSnack(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: WorkSansAppTextStyles.medium.copyWith(
            color: context.modeTextInverse,
          ),
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildStatusPill(OrderStatus status, double textSize) {
    final background = _getStatusColor(status);
    return Container(
      constraints: const BoxConstraints(minWidth: 82),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status.displayName,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.center,
        style: WorkSansAppTextStyles.medium.copyWith(
          fontSize: textSize - 2,
          fontWeight: FontWeight.w800,
          color: _getStatusTextColor(status),
        ),
      ),
    );
  }

  Widget _buildInfoChip({
    required IconData icon,
    required String label,
    required double textSize,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: context.modeSurfaceAlt,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: context.modeBorder.withValues(alpha: 0.36)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: context.modeTextMuted),
          const SizedBox(width: 5),
          Text(
            label,
            style: WorkSansAppTextStyles.medium.copyWith(
              fontSize: textSize - 2,
              fontWeight: FontWeight.w700,
              color: context.modeTextSecondary,
            ),
          ),
        ],
      ),
    );
  }

  void _copyOrderId(String orderId) {
    Clipboard.setData(ClipboardData(text: orderId));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Order ID copied: $orderId',
          style: WorkSansAppTextStyles.medium.copyWith(
            color: context.modeTextInverse,
            fontSize: 14,
          ),
        ),
        backgroundColor: context.modeSuccess,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  String _orderLocationLabel(KitchenOrder order) {
    final table = order.tableNumber?.trim();
    if (table != null && table.isNotEmpty) return table;

    switch (order.orderType) {
      case OrderType.dineIn:
        return 'Dine in';
      case OrderType.takeaway:
        return 'Takeaway';
      case OrderType.online:
        return 'Online';
      case OrderType.delivery:
        return 'Delivery';
    }
  }

  String _formatTimeAgo(DateTime dateTime) {
    final diff = DateTime.now().difference(dateTime.toLocal());
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min';
    if (diff.inHours < 24) return '${diff.inHours} hr';
    return '${diff.inDays} day';
  }

  IconData _getStatusIcon(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return Icons.pending_actions_rounded;
      case OrderStatus.confirmed:
        return Icons.verified_outlined;
      case OrderStatus.inQueue:
        return Icons.queue_rounded;
      case OrderStatus.preparing:
        return Icons.restaurant_menu_rounded;
      case OrderStatus.ready:
        return Icons.done_all_rounded;
      case OrderStatus.served:
        return Icons.room_service_outlined;
      case OrderStatus.completed:
        return Icons.check_circle_outline_rounded;
      case OrderStatus.cancelled:
        return Icons.cancel_outlined;
    }
  }

  Widget _buildEmptyState(double horizontalPadding, double screenWidth) {
    final textSize = _getBodyTextSize(screenWidth);
    return Center(
      child: Padding(
        padding: EdgeInsets.all(horizontalPadding),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 80,
              color: context.modeTextMuted.withValues(alpha: 0.6),
            ),
            const SizedBox(height: 16),
            Text(
              'No Orders',
              style: WorkSansAppTextStyles.medium.copyWith(
                fontSize: textSize + 2,
                fontWeight: FontWeight.w600,
                color: context.modeTextPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'All orders have been completed or there are no pending orders.',
              style: WorkSansAppTextStyles.medium.copyWith(
                fontSize: textSize - 1,
                color: context.modeTextSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                context.read<KitchenOrdersBloc>().add(
                  const RefreshKitchenOrders(),
                );
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh'),
              style: ElevatedButton.styleFrom(
                backgroundColor: context.modePrimary,
                foregroundColor: context.modeTextInverse,
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

  Widget _buildErrorState(
    KitchenOrdersError state,
    double horizontalPadding,
    double screenWidth,
  ) {
    final textSize = _getBodyTextSize(screenWidth);
    return Center(
      child: Padding(
        padding: EdgeInsets.all(horizontalPadding),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _getErrorIcon(state.errorType),
              size: 80,
              color: context.modeError,
            ),
            const SizedBox(height: 16),
            Text(
              _getErrorTitle(state.errorType),
              style: WorkSansAppTextStyles.medium.copyWith(
                fontSize: textSize + 2,
                fontWeight: FontWeight.w600,
                color: context.modeTextPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              state.error,
              style: WorkSansAppTextStyles.medium.copyWith(
                fontSize: textSize - 1,
                color: context.modeTextSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                context.read<KitchenOrdersBloc>().add(
                  const LoadKitchenOrders(),
                );
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: context.modePrimary,
                foregroundColor: context.modeTextInverse,
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

  IconData _getErrorIcon(KitchenOrdersErrorType errorType) {
    switch (errorType) {
      case KitchenOrdersErrorType.network:
        return Icons.wifi_off;
      case KitchenOrdersErrorType.timeout:
        return Icons.access_time;
      case KitchenOrdersErrorType.notFound:
        return Icons.search_off;
      case KitchenOrdersErrorType.server:
        return Icons.cloud_off;
      default:
        return Icons.error_outline;
    }
  }

  String _getErrorTitle(KitchenOrdersErrorType errorType) {
    switch (errorType) {
      case KitchenOrdersErrorType.network:
        return 'Connection Error';
      case KitchenOrdersErrorType.timeout:
        return 'Request Timeout';
      case KitchenOrdersErrorType.notFound:
        return 'No Orders Found';
      case KitchenOrdersErrorType.server:
        return 'Server Error';
      default:
        return 'Something Went Wrong';
    }
  }

  Color _getStatusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return context.modeWarning.withValues(alpha: 0.24);
      case OrderStatus.confirmed:
        return context.modeInfo.withValues(alpha: 0.22);
      case OrderStatus.inQueue:
        return context.modeWarning.withValues(alpha: 0.22);
      case OrderStatus.preparing:
        return context.modePrimary.withValues(alpha: 0.18);
      case OrderStatus.ready:
        return context.modeSuccess;
      case OrderStatus.served:
        return context.modeSuccess;
      case OrderStatus.completed:
        return context.modeTextSecondary;
      case OrderStatus.cancelled:
        return context.modeError;
    }
  }

  Color _getStatusTextColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
      case OrderStatus.confirmed:
      case OrderStatus.inQueue:
      case OrderStatus.preparing:
        return context.modeTextPrimary;
      case OrderStatus.served:
        return _textOnStatusColor(_getStatusColor(status));
      default:
        return context.modeTextInverse;
    }
  }

  Color _textOnStatusColor(Color backgroundColor) {
    final brightness = ThemeData.estimateBrightnessForColor(backgroundColor);
    return brightness == Brightness.dark
        ? context.modeTextInverse
        : context.modeTextPrimary;
  }

  double _getHorizontalPadding(double width) {
    if (width < 360) return 16;
    if (width < 600) return 20;
    if (width < 900) return 24;
    return 32;
  }

  double _getVerticalSpacing(double width) {
    if (width < 360) return 12;
    if (width < 600) return 14;
    if (width < 900) return 16;
    return 18;
  }

  double _getBodyTextSize(double width) {
    if (width < 360) return 14;
    if (width < 600) return 15;
    if (width < 900) return 16;
    return 17;
  }

  bool _hasPayment(KitchenOrder order) {
    final amountPaid = double.tryParse(order.amountPaid ?? '') ?? 0;
    final method = order.paymentMethod?.trim();
    return amountPaid > 0 || (method != null && method.isNotEmpty);
  }

  bool _isPaymentPendingOrder(KitchenOrder order) {
    return order.status == OrderStatus.served && !_hasPayment(order);
  }

  bool _isActiveOrder(KitchenOrder order) {
    if (order.status == OrderStatus.cancelled ||
        order.status == OrderStatus.completed) {
      return false;
    }

    if (order.status == OrderStatus.served) {
      return _isPaymentPendingOrder(order);
    }

    return true;
  }
}

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:intl/intl.dart';
import 'package:sandwich_ai/src/core/constant/appcolors.dart';
import 'package:sandwich_ai/src/core/constant/textstyle.dart';
import 'package:sandwich_ai/src/features/pos/bloc/order_status_bloc/bloc.dart';
import 'package:sandwich_ai/src/features/pos/bloc/order_status_bloc/event.dart';
import 'package:sandwich_ai/src/features/pos/bloc/order_status_bloc/state.dart';
import 'package:sandwich_ai/src/features/pos/data/model/oder_status_model.dart';
import 'package:sandwich_ai/src/features/pos/presentation/active_order_dtls.dart';

class ActiveOrdersScreen extends StatefulWidget {
  const ActiveOrdersScreen({super.key});

  @override
  State<ActiveOrdersScreen> createState() => _ActiveOrdersScreenState();
}

class _ActiveOrdersScreenState extends State<ActiveOrdersScreen> {
  final TextEditingController _searchController = TextEditingController();
  String? _selectedStatus;

  @override
  void initState() {
    super.initState();
    context.read<KitchenOrdersBloc>().add(const LoadKitchenOrders());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTextStyle.merge(
      style: WorkSansAppTextStyles.medium,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F6F6),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          title: Text(
            'Active Orders',
            style: WorkSansAppTextStyles.medium.copyWith(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: kprimaryTextColor1,
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
                        return const Center(
                          child: CircularProgressIndicator(color: kPrimary),
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
                                .where((o) => o.status != OrderStatus.pending)
                                .toList();

                        if (orders.isEmpty) {
                          return _buildEmptyState(
                            horizontalPadding,
                            constraints.maxWidth,
                          );
                        }

                        return RefreshIndicator(
                          color: kPrimary,
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
      color: Colors.white,
      child: Column(
        children: [
          TextField(
            cursorColor: kPrimary,
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search orders...',
              hintStyle: WorkSansAppTextStyles.medium.copyWith(
                color: Colors.grey,
                fontSize: 14,
              ),
              prefixIcon: const Icon(Icons.search, color: Colors.grey),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, color: Colors.grey),
                      onPressed: () {
                        _searchController.clear();
                        context.read<KitchenOrdersBloc>().add(
                          const SearchKitchenOrders(query: ''),
                        );
                      },
                    )
                  : null,
              filled: true,
              fillColor: const Color(0xFFF8F6F6),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
            onChanged: (value) {
              context.read<KitchenOrdersBloc>().add(
                SearchKitchenOrders(query: value),
              );
            },
          ),
          SizedBox(height: verticalSpacing),
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _buildFilterChip('All', null),
                const SizedBox(width: 8),
                // _buildFilterChip('Pending', OrderStatus.pending.value),
                // const SizedBox(width: 8),
                _buildFilterChip('Confirmed', OrderStatus.confirmed.value),
                const SizedBox(width: 8),
                _buildFilterChip('Preparing', OrderStatus.preparing.value),
                const SizedBox(width: 8),
                _buildFilterChip('Ready', OrderStatus.ready.value),
                const SizedBox(width: 8),
                _buildFilterChip('Served', OrderStatus.served.value),
                const SizedBox(width: 8),
                _buildFilterChip('Cancelled', OrderStatus.cancelled.value),
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
          color: isSelected ? Colors.white : kprimaryTextColor1,
        ),
      ),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedStatus = selected ? status : null;
        });
        context.read<KitchenOrdersBloc>().add(
          FilterKitchenOrdersByStatus(status: status),
        );
      },
      backgroundColor: const Color(0xFFE8E8E8),
      selectedColor: kPrimary,
      checkmarkColor: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      showCheckmark: false,
    );
  }

  Widget _buildOrderCard(KitchenOrder order, double textSize) {
    final amount = double.tryParse(order.totalAmount.toString()) ?? 0;
    final formattedAmount = NumberFormat('#,##0.##').format(amount);
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => OrderDetailScreen(order: order),
          ),
        );
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFE8E8E8),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Row(
                    children: [
                      Flexible(
                        child: Text(
                          order.orderId,
                          style: WorkSansAppTextStyles.medium.copyWith(
                            fontSize: textSize,
                            fontWeight: FontWeight.w600,
                            color: kprimaryTextColor1,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 4),
                      InkWell(
                        onTap: () {
                          Clipboard.setData(ClipboardData(text: order.orderId));
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Order ID copied: ${order.orderId}',
                                style: WorkSansAppTextStyles.medium.copyWith(
                                  color: Colors.white,
                                  fontSize: 14,
                                ),
                              ),
                              backgroundColor: kGreen,
                              duration: const Duration(seconds: 2),
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          );
                        },
                        child: Icon(Icons.copy, size: 16, color: kPrimary),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    order.tableNumber ?? order.orderType.value,
                    style: WorkSansAppTextStyles.medium.copyWith(
                      fontSize: textSize,
                      fontWeight: FontWeight.w500,
                      color: kprimaryTextColor1,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: _getStatusColor(order.status),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      order.status.displayName,
                      style: WorkSansAppTextStyles.medium.copyWith(
                        fontSize: textSize - 1,
                        fontWeight: FontWeight.w600,
                        color: _getStatusTextColor(order.status),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              order.customerName ?? '',
              style: WorkSansAppTextStyles.medium.copyWith(
                fontSize: textSize - 1,
                fontWeight: FontWeight.w500,
                color: kprimaryTextColor1.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${order.items.length} item${order.items.length > 1 ? 's' : ''} • ₦$formattedAmount',
              style: WorkSansAppTextStyles.medium.copyWith(
                fontSize: textSize - 2,
                fontWeight: FontWeight.w500,
                color: kprimaryTextColor1.withOpacity(0.6),
              ),
            ),
          ],
        ),
      ),
    );
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
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No Orders',
              style: WorkSansAppTextStyles.medium.copyWith(
                fontSize: textSize + 2,
                fontWeight: FontWeight.w600,
                color: kprimaryTextColor1,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'All orders have been completed or there are no pending orders.',
              style: WorkSansAppTextStyles.medium.copyWith(
                fontSize: textSize - 1,
                color: kprimaryTextColor1.withOpacity(0.6),
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
              color: Colors.red[400],
            ),
            const SizedBox(height: 16),
            Text(
              _getErrorTitle(state.errorType),
              style: WorkSansAppTextStyles.medium.copyWith(
                fontSize: textSize + 2,
                fontWeight: FontWeight.w600,
                color: kprimaryTextColor1,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              state.error,
              style: WorkSansAppTextStyles.medium.copyWith(
                fontSize: textSize - 1,
                color: kprimaryTextColor1.withOpacity(0.6),
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
        return const Color(0xFFFFE770);
      case OrderStatus.confirmed:
        return const Color(0xFF87CEEB);
      case OrderStatus.inQueue:
        return const Color(0xFFFFB347);
      case OrderStatus.preparing:
        return const Color.fromARGB(255, 255, 155, 6);
      case OrderStatus.ready:
        return const Color(0xFF30A46C);
      case OrderStatus.served:
        return const Color(0xFF9E9E9E);
      case OrderStatus.completed:
        return const Color(0xFF4A5568);
      case OrderStatus.cancelled:
        return const Color(0xFFEF4444);
    }
  }

  Color _getStatusTextColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
      case OrderStatus.confirmed:
      case OrderStatus.inQueue:
      case OrderStatus.preparing:
        return kprimaryTextColor1;
      default:
        return Colors.white;
    }
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
}

import 'package:flutter/material.dart';
import 'package:sandwich_ai/src/core/globals/app_icon.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sandwich_ai/src/core/theme/app_theme_extension.dart';
import 'package:sandwich_ai/src/core/constant/textstyle.dart';

import 'package:intl/intl.dart';
import 'package:sandwich_ai/src/features/procurement/data/model/purchase_order_model.dart';
import 'package:sandwich_ai/src/features/procurement/presentation/order_list_details.dart';
import 'package:sandwich_ai/src/features/procurement/procurement_blocs/order_list-bloc/bloc.dart';
import 'package:sandwich_ai/src/features/procurement/procurement_blocs/order_list-bloc/event.dart';
import 'package:sandwich_ai/src/features/procurement/procurement_blocs/order_list-bloc/state.dart';

class OrdersListScreen extends StatefulWidget {
  const OrdersListScreen({super.key});

  @override
  State<OrdersListScreen> createState() => _OrdersListScreenState();
}

class _OrdersListScreenState extends State<OrdersListScreen>
    with SingleTickerProviderStateMixin {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  late final TabController _tabController;

  String? _selectedStatus;
  String? _selectedPriority;
  String? _selectedCategory;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this)
      ..addListener(_onTabChanged);
    context.read<OrdersListBloc>().add(const LoadOrders());
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) return;
    switch (_tabController.index) {
      case 1:
        context.read<OrdersListBloc>().add(const LoadPendingApprovalOrders());
        break;
      case 2:
        context.read<OrdersListBloc>().add(const LoadOverdueDeliveryOrders());
        break;
      default:
        context.read<OrdersListBloc>().add(const LoadOrders());
    }
  }

  void _onScroll() {
    if (_isBottom) {
      context.read<OrdersListBloc>().add(const LoadMoreOrders());
    }
  }

  bool get _isBottom {
    if (!_scrollController.hasClients) return false;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.offset;
    return currentScroll >= (maxScroll * 0.9);
  }

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildFilterSheet(),
    );
  }

  void _applyFilters(String? status, String? priority, String? category) {
    setState(() {
      _selectedStatus = status;
      _selectedPriority = priority;
      _selectedCategory = category;
    });

    context.read<OrdersListBloc>().add(
      FilterOrders(
        status: status,
        priority: priority,
        primaryCategory: category,
      ),
    );

    Navigator.pop(context);
  }

  void _clearFilters() {
    setState(() {
      _selectedStatus = null;
      _selectedPriority = null;
      _selectedCategory = null;
    });
    context.read<OrdersListBloc>().add(const ClearFilters());
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTextStyle.merge(
      style: WorkSansAppTextStyles.medium,
      child: Scaffold(
        backgroundColor: context.modeBackground,
        appBar: _buildAppBar(context),
        body: _buildBody(context),
        // floatingActionButton: _buildFAB(),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: context.modeSurface,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      leading: IconButton(
        icon: AppIcon(Icons.arrow_back, color: context.modeTextPrimary),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: Text(
        'Purchase Orders',
        style: WorkSansAppTextStyles.medium.copyWith(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: context.modeTextPrimary,
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

        return Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxContentWidth),
            child: Column(
              children: [
                // Search and Filter Bar
                Container(
                  color: context.modeSurface,
                  padding: EdgeInsets.symmetric(
                    horizontal: horizontalPadding,
                    vertical: 16,
                  ),
                  child: Row(
                    children: [
                      Expanded(child: _buildSearchBar()),
                      const SizedBox(width: 12),
                      _buildFilterButton(),
                    ],
                  ),
                ),
                Container(
                  color: context.modeSurface,
                  child: TabBar(
                    controller: _tabController,
                    labelColor: context.modePrimary,
                    unselectedLabelColor: context.modeTextSecondary,
                    indicatorColor: context.modePrimary,
                    labelStyle: WorkSansAppTextStyles.medium.copyWith(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                    tabs: const [
                      Tab(text: 'All'),
                      Tab(text: 'Pending Approvals'),
                      Tab(text: 'Overdue'),
                    ],
                  ),
                ),

                // Active Filters
                if (_hasActiveFilters() && _tabController.index == 0)
                  _buildActiveFilters(horizontalPadding),

                // Orders List
                Expanded(
                  child: BlocBuilder<OrdersListBloc, OrdersListState>(
                    builder: (context, state) {
                      if (state is OrdersLoading) {
                        return _buildLoadingState();
                      } else if (state is OrdersError) {
                        return _buildErrorState(state);
                      } else if (state is OrdersEmpty) {
                        return _buildEmptyState(state);
                      } else if (state is OrdersLoaded) {
                        return _buildOrdersList(state, horizontalPadding);
                      } else if (state is OrdersLoadingMore) {
                        return _buildOrdersListWithLoadMore(
                          state,
                          horizontalPadding,
                        );
                      }
                      return _buildEmptyState(
                        const OrdersEmpty(message: 'No orders found'),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSearchBar() {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: context.modeSurfaceAlt,
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        controller: _searchController,
        style: WorkSansAppTextStyles.medium.copyWith(fontSize: 14),
        decoration: InputDecoration(
          hintText: 'Search by order number or supplier...',
          hintStyle: WorkSansAppTextStyles.medium.copyWith(
            fontSize: 14,
            color: context.modeTextMuted,
          ),
          prefixIcon: AppIconSlot(
            Icons.search,
            color: context.modeTextMuted,
            size: 20,
          ),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const AppIcon(Icons.clear, size: 20),
                  onPressed: () {
                    _searchController.clear();
                    context.read<OrdersListBloc>().add(const SearchOrders(''));
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
        ),
        onSubmitted: (value) {
          if (value.isNotEmpty) {
            context.read<OrdersListBloc>().add(SearchOrders(value));
          }
        },
      ),
    );
  }

  Widget _buildFilterButton() {
    final hasFilters = _hasActiveFilters();
    return Stack(
      children: [
        Container(
          height: 48,
          width: 48,
          decoration: BoxDecoration(
            color: hasFilters ? context.modePrimary : context.modeSurface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: hasFilters ? context.modePrimary : context.modeBorder,
            ),
          ),
          child: IconButton(
            icon: AppIcon(
              Icons.filter_list,
              color: hasFilters
                  ? context.modeTextInverse
                  : context.modeTextPrimary,
            ),
            onPressed: _showFilterBottomSheet,
          ),
        ),
        if (hasFilters)
          Positioned(
            right: 8,
            top: 8,
            child: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: context.modeError,
                shape: BoxShape.circle,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildActiveFilters(double padding) {
    return Container(
      color: context.modeSurface,
      padding: EdgeInsets.only(left: padding, right: padding, bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Active Filters:',
                style: WorkSansAppTextStyles.medium.copyWith(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: context.modeTextPrimary,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: _clearFilters,
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(0, 0),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  'Clear All',
                  style: WorkSansAppTextStyles.medium.copyWith(
                    fontSize: 12,
                    color: context.modePrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (_selectedStatus != null)
                _buildFilterChip(
                  'Status: $_selectedStatus',
                  () =>
                      _applyFilters(null, _selectedPriority, _selectedCategory),
                ),
              if (_selectedPriority != null)
                _buildFilterChip(
                  'Priority: $_selectedPriority',
                  () => _applyFilters(_selectedStatus, null, _selectedCategory),
                ),
              if (_selectedCategory != null)
                _buildFilterChip(
                  'Category: $_selectedCategory',
                  () => _applyFilters(_selectedStatus, _selectedPriority, null),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, VoidCallback onRemove) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: context.modePrimary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.modePrimary.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: WorkSansAppTextStyles.medium.copyWith(
              fontSize: 12,
              color: context.modePrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 4),
          InkWell(
            onTap: onRemove,
            child: AppIcon(Icons.close, size: 16, color: context.modePrimary),
          ),
        ],
      ),
    );
  }

  Widget _buildOrdersList(OrdersLoaded state, double padding) {
    return RefreshIndicator(
      onRefresh: () async {
        context.read<OrdersListBloc>().add(const RefreshOrders());
        await Future.delayed(const Duration(seconds: 1));
      },
      color: context.modePrimary,
      child: ListView.builder(
        controller: _scrollController,
        padding: EdgeInsets.symmetric(horizontal: padding, vertical: 16),
        itemCount: state.orders.length,
        itemBuilder: (context, index) {
          return _buildOrderCard(state.orders[index]);
        },
      ),
    );
  }

  Widget _buildOrdersListWithLoadMore(OrdersLoadingMore state, double padding) {
    return ListView.builder(
      controller: _scrollController,
      padding: EdgeInsets.symmetric(horizontal: padding, vertical: 16),
      itemCount: state.currentOrders.length + 1,
      itemBuilder: (context, index) {
        if (index == state.currentOrders.length) {
          return Padding(
            padding: EdgeInsets.all(16.0),
            child: Center(
              child: CircularProgressIndicator(color: context.modePrimary),
            ),
          );
        }
        return _buildOrderCard(state.currentOrders[index]);
      },
    );
  }

  Widget _buildOrderCard(PurchaseOrder order) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: context.modeSurface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: Theme.of(context).brightness == Brightness.dark
                  ? 0.2
                  : 0.05,
            ),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () async {
            final changed = await Navigator.push<bool>(
              context,
              MaterialPageRoute(
                builder: (_) => OrderDetailsScreen(order: order),
              ),
            );
            if (changed == true && mounted) {
              context.read<OrdersListBloc>().add(const RefreshOrders());
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            order.orderNumber,
                            style: WorkSansAppTextStyles.medium.copyWith(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: context.modeTextPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            order.supplier.businessName,
                            style: WorkSansAppTextStyles.medium.copyWith(
                              fontSize: 14,
                              color: context.modeTextSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    _buildStatusBadge(order.status),
                  ],
                ),

                const SizedBox(height: 16),

                // Amount and Items
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: context.modePrimary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Total Amount',
                              style: WorkSansAppTextStyles.medium.copyWith(
                                fontSize: 12,
                                color: context.modeTextSecondary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '₦${NumberFormat('#,##0.00').format(order.totalAmount)}',
                              style: WorkSansAppTextStyles.medium.copyWith(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: context.modePrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: context.modeSurface,
                          border: Border.all(color: context.modeBorder),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${order.items.length} item${order.items.length > 1 ? 's' : ''}',
                          style: WorkSansAppTextStyles.medium.copyWith(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: context.modeTextPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Dates and Priority Row
                Row(
                  children: [
                    Expanded(
                      child: _buildInfoItem(
                        icon: Icons.calendar_today_outlined,
                        label: 'Order Date',
                        value: DateFormat(
                          'MMM dd, yyyy',
                        ).format(order.orderDate),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildInfoItem(
                        icon: Icons.local_shipping_outlined,
                        label: 'Delivery',
                        value: DateFormat(
                          'MMM dd',
                        ).format(order.expectedDeliveryDate),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Priority and Payment
                Row(
                  children: [
                    _buildPriorityBadge(order.priority),
                    const SizedBox(width: 8),
                    _buildPaymentBadge(order.paymentStatus),
                    if (order.deliveryStatus != null) ...[
                      const SizedBox(width: 8),
                      _buildDeliveryBadge(order.deliveryStatus!),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        AppIcon(icon, size: 16, color: context.modeTextMuted),
        const SizedBox(width: 6),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: WorkSansAppTextStyles.medium.copyWith(
                  fontSize: 11,
                  color: context.modeTextMuted,
                ),
              ),
              Text(
                value,
                style: WorkSansAppTextStyles.medium.copyWith(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: context.modeTextPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBadge(String status) {
    Color backgroundColor;
    Color textColor;

    switch (status.toUpperCase()) {
      case 'PENDING':
        backgroundColor = context.modeWarning.withValues(alpha: 0.12);
        textColor = context.modeWarning;
        break;
      case 'ACCEPTED':
        backgroundColor = context.modeInfo.withValues(alpha: 0.12);
        textColor = context.modeInfo;
        break;
      case 'DECLINED':
        backgroundColor = context.modeError.withValues(alpha: 0.12);
        textColor = context.modeError;
        break;
      case 'IN_TRANSIT':
        backgroundColor = context.modePrimaryAlt.withValues(alpha: 0.12);
        textColor = context.modePrimaryAlt;
        break;
      case 'DELIVERED':
        backgroundColor = context.modeSuccess.withValues(alpha: 0.12);
        textColor = context.modeSuccess;
        break;
      case 'COMPLETED':
        backgroundColor = context.modeSuccess.withValues(alpha: 0.12);
        textColor = context.modeSuccess;
        break;
      case 'CANCELLED':
        backgroundColor = context.modeSurfaceMuted;
        textColor = context.modeTextSecondary;
        break;
      default:
        backgroundColor = context.modeSurfaceMuted;
        textColor = context.modeTextSecondary;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status.replaceAll('_', ' '),
        style: WorkSansAppTextStyles.medium.copyWith(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }

  Widget _buildPriorityBadge(String priority) {
    Color color;
    switch (priority.toUpperCase()) {
      case 'URGENT':
        color = context.modeError;
        break;
      case 'HIGH':
        color = context.modeWarning;
        break;
      default:
        color = context.modeTextMuted;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppIcon(Icons.flag, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            priority,
            style: WorkSansAppTextStyles.medium.copyWith(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentBadge(String status) {
    Color color;
    switch (status.toUpperCase()) {
      case 'COMPLETED':
        color = context.modeSuccess;
        break;
      case 'FAILED':
        color = context.modeError;
        break;
      default:
        color = context.modeWarning;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppIcon(Icons.payment, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            status,
            style: WorkSansAppTextStyles.medium.copyWith(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeliveryBadge(String status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: context.modeInfo.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: context.modeInfo.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppIcon(Icons.local_shipping, size: 12, color: context.modeInfo),
          const SizedBox(width: 4),
          Text(
            status.replaceAll('_', ' '),
            style: WorkSansAppTextStyles.medium.copyWith(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: context.modeInfo,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(child: CircularProgressIndicator(color: context.modePrimary));
  }

  Widget _buildErrorState(OrdersError state) {
    String message = 'Failed to load orders';
    IconData icon = Icons.error_outline;

    switch (state.errorType) {
      case OrdersErrorType.network:
        message = 'No internet connection';
        icon = Icons.wifi_off;
        break;
      case OrdersErrorType.timeout:
        message = 'Request timed out';
        icon = Icons.timer_off;
        break;
      case OrdersErrorType.server:
        message = 'Server error';
        icon = Icons.dns;
        break;
      case OrdersErrorType.general:
        message = state.error;
        break;
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AppIcon(icon, size: 64, color: context.modeTextMuted),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: WorkSansAppTextStyles.medium.copyWith(
                fontSize: 16,
                color: context.modeTextSecondary,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                context.read<OrdersListBloc>().add(const RefreshOrders());
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: context.modePrimary,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Try Again',
                style: WorkSansAppTextStyles.medium.copyWith(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: context.modeTextInverse,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(OrdersEmpty state) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AppIcon(
              Icons.inbox_outlined,
              size: 80,
              color: context.modeTextMuted,
            ),
            const SizedBox(height: 24),
            Text(
              state.message,
              textAlign: TextAlign.center,
              style: WorkSansAppTextStyles.medium.copyWith(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: context.modeTextSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Create your first order to get started',
              textAlign: TextAlign.center,
              style: WorkSansAppTextStyles.medium.copyWith(
                fontSize: 14,
                color: context.modeTextMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterSheet() {
    String? tempStatus = _selectedStatus;
    String? tempPriority = _selectedPriority;
    String? tempCategory = _selectedCategory;

    return StatefulBuilder(
      builder: (context, setModalState) {
        return Container(
          decoration: BoxDecoration(
            color: context.modeSurface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Filter Orders',
                    style: WorkSansAppTextStyles.medium.copyWith(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: context.modeTextPrimary,
                    ),
                  ),
                  IconButton(
                    icon: const AppIcon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Status Filter
              Text(
                'Status',
                style: WorkSansAppTextStyles.medium.copyWith(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: context.modeTextPrimary,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children:
                    [
                      'PENDING',
                      'ACCEPTED',
                      'DECLINED',
                      'IN_TRANSIT',
                      'DELIVERED',
                      'COMPLETED',
                      'CANCELLED',
                    ].map((status) {
                      return _buildFilterChipSelector(
                        status,
                        tempStatus == status,
                        () {
                          setModalState(() {
                            tempStatus = tempStatus == status ? null : status;
                          });
                        },
                      );
                    }).toList(),
              ),

              const SizedBox(height: 24),

              // Priority Filter
              Text(
                'Priority',
                style: WorkSansAppTextStyles.medium.copyWith(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: context.modeTextPrimary,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: ['LOW', 'NORMAL', 'HIGH', 'URGENT'].map((priority) {
                  return _buildFilterChipSelector(
                    priority,
                    tempPriority == priority,
                    () {
                      setModalState(() {
                        tempPriority = tempPriority == priority
                            ? null
                            : priority;
                      });
                    },
                  );
                }).toList(),
              ),

              const SizedBox(height: 24),

              // Category Filter
              Text(
                'Category',
                style: WorkSansAppTextStyles.medium.copyWith(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: context.modeTextPrimary,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children:
                    [
                      'PROTEIN',
                      'GRAIN',
                      'SPICES',
                      'VEGETABLE',
                      'DAIRY',
                      'BEVERAGE',
                      'OIL',
                      'SEASONING',
                    ].map((category) {
                      return _buildFilterChipSelector(
                        category,
                        tempCategory == category,
                        () {
                          setModalState(() {
                            tempCategory = tempCategory == category
                                ? null
                                : category;
                          });
                        },
                      );
                    }).toList(),
              ),

              const SizedBox(height: 32),

              // Apply Button
              ElevatedButton(
                onPressed: () {
                  _applyFilters(tempStatus, tempPriority, tempCategory);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: context.modePrimary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Apply Filters',
                  style: WorkSansAppTextStyles.medium.copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: context.modeTextInverse,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFilterChipSelector(
    String label,
    bool isSelected,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? context.modePrimary : context.modeSurfaceAlt,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? context.modePrimary : context.modeBorder,
          ),
        ),
        child: Text(
          label.replaceAll('_', ' '),
          style: WorkSansAppTextStyles.medium.copyWith(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: isSelected
                ? context.modeTextInverse
                : context.modeTextPrimary,
          ),
        ),
      ),
    );
  }

  bool _hasActiveFilters() {
    return _selectedStatus != null ||
        _selectedPriority != null ||
        _selectedCategory != null;
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
    return 900;
  }
}

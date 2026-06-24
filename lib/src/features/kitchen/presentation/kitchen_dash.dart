import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:sandwich_ai/src/core/theme/app_theme_extension.dart';
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
  String? _updatingOrderId;

  void _dispatch(dynamic event) {
    context.read<KitchenDashboardBloc>().add(event);
  }

  Future<void> _confirmCancel(KitchenOrder order) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Cancel Order',
          style: WorkSansAppTextStyles.medium.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Text(
          'Cancel order ${order.orderId} for ${order.customerName}?',
          style: WorkSansAppTextStyles.medium.copyWith(
            color: const Color(0xFF555555),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Keep',
              style: WorkSansAppTextStyles.medium.copyWith(
                color: const Color(0xFF888888),
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFFE57373),
            ),
            child: Text(
              'Yes, Cancel',
              style: WorkSansAppTextStyles.medium.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      setState(() => _updatingOrderId = order.id);
      _dispatch(CancelOrder(order.id));
    }
  }

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
        key: _scaffoldKey,
        drawer: KitchenAppDrawer(),
        backgroundColor: const Color(0xFFF5F4F2),
        appBar: _buildAppBar(),
        body: BlocConsumer<KitchenDashboardBloc, KitchenDashboardState>(
          listener: (context, state) {
            if (state is OrderActionSuccess) {
              setState(() => _updatingOrderId = state.orderId);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    state.message,
                    style: WorkSansAppTextStyles.medium.copyWith(
                      color: Colors.white,
                    ),
                  ),
                  backgroundColor: const Color(0xFF2D9B6F),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  duration: const Duration(milliseconds: 1500),
                ),
              );
            } else if (state is OrderActionError) {
              setState(() => _updatingOrderId = null);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    state.error,
                    style: WorkSansAppTextStyles.medium.copyWith(
                      color: Colors.white,
                    ),
                  ),
                  backgroundColor: Colors.red,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  duration: const Duration(seconds: 3),
                ),
              );
            } else if (state is DashboardLoaded) {
              setState(() => _updatingOrderId = null);
            }
          },
          buildWhen: (previous, current) =>
              current is! OrderActionSuccess && current is! OrderActionError,
          builder: (context, state) {
            if (state is DashboardLoading) return _buildLoadingState();
            if (state is DashboardLoaded)
              return _buildLoadedState(
                state.dashboardData,
                state.filteredOrders,
                state.currentFilter,
              );
            if (state is DashboardRefreshing)
              return _buildLoadedState(
                state.currentData,
                state.currentData.recentOrders,
                OrderFilter.all,
                isRefreshing: true,
              );
            if (state is DashboardEmpty) return _buildEmptyState();
            if (state is DashboardError) return _buildErrorState(state);
            return _buildLoadingState();
          },
        ),
      ),
    );
  }

  // ── AppBar ─────────────────────────────────────────────────────────────────

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      leading: IconButton(
        icon: const Icon(Icons.menu_rounded, color: Color(0xFF1A1A1A)),
        onPressed: () => _scaffoldKey.currentState?.openDrawer(),
      ),
      title: Text(
        'Live Orders',
        style: WorkSansAppTextStyles.medium.copyWith(
          fontSize: 17,
          fontWeight: FontWeight.w700,
          color: const Color(0xFF1A1A1A),
        ),
      ),
      centerTitle: true,
      actions: [
        IconButton(
          icon: Icon(Icons.refresh_rounded, color: kPrimary),
          onPressed: () => _dispatch(const RefreshDashboardData()),
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: const Color(0xFFEEEEEE)),
      ),
    );
  }

  // ── Loaded state ───────────────────────────────────────────────────────────

  Widget _buildLoadedState(
    KitchenDashboardData data,
    List<KitchenOrder> orders,
    OrderFilter currentFilter, {
    bool isRefreshing = false,
  }) {
    final visible = orders
        .where((o) => o.status.toUpperCase() != 'PENDING')
        .toList();

    return Stack(
      children: [
        RefreshIndicator(
          onRefresh: () async {
            _dispatch(const RefreshDashboardData());
            await Future.delayed(const Duration(seconds: 1));
          },
          color: kPrimary,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
            children: [
              _buildStatsRow(data),
              const SizedBox(height: 14),
              _buildFilterChips(currentFilter),
              const SizedBox(height: 14),
              if (visible.isEmpty)
                _buildNoOrdersForFilter(currentFilter)
              else
                ...visible.map(
                  (order) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _buildOrderCard(order),
                  ),
                ),
            ],
          ),
        ),
        if (isRefreshing)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: LinearProgressIndicator(
              backgroundColor: Colors.transparent,
              color: kPrimary,
            ),
          ),
      ],
    );
  }

  // ── Stats row ──────────────────────────────────────────────────────────────

  Widget _buildStatsRow(KitchenDashboardData data) {
    return Row(
      children: [
        _statCard(
          label: 'Ongoing',
          value: '${data.orderStats.ongoingOrders}',
          color: kPrimary,
          bg: kPrimary.withValues(alpha: 0.08),
          icon: Icons.pending_actions_rounded,
        ),
        const SizedBox(width: 10),
        _statCard(
          label: 'Delivered',
          value: '${data.orderStats.ordersDelivered}',
          color: const Color(0xFF2D9B6F),
          bg: const Color(0xFFE8F7F1),
          icon: Icons.check_circle_rounded,
        ),
        const SizedBox(width: 10),
        _statCard(
          label: 'Staff',
          value: '${data.staffOnDuty.total}',
          color: const Color(0xFF4A6FE3),
          bg: const Color(0xFFEBF0FF),
          icon: Icons.people_alt_rounded,
        ),
      ],
    );
  }

  Widget _statCard({
    required String label,
    required String value,
    required Color color,
    required Color bg,
    required IconData icon,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Container(
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: WorkSansAppTextStyles.medium.copyWith(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: color,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: WorkSansAppTextStyles.medium.copyWith(
                    fontSize: 11,
                    color: color.withValues(alpha: 0.7),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── Filter chips ───────────────────────────────────────────────────────────

  Widget _buildFilterChips(OrderFilter currentFilter) {
    const filters = [
      (OrderFilter.all, 'All'),
      (OrderFilter.newOrder, 'New'),
      (OrderFilter.inProgress, 'In Progress'),
      (OrderFilter.completed, 'Done'),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filters.map((entry) {
          final (filter, label) = entry;
          final selected = currentFilter == filter;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => _dispatch(FilterOrders(filter)),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: selected ? kPrimary : Colors.white,
                  borderRadius: BorderRadius.circular(100),
                  border: Border.all(
                    color: selected ? kPrimary : const Color(0xFFDDDDDD),
                  ),
                ),
                child: Text(
                  label,
                  style: WorkSansAppTextStyles.medium.copyWith(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: selected ? Colors.white : const Color(0xFF555555),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── Order card ─────────────────────────────────────────────────────────────

  Widget _buildOrderCard(KitchenOrder order) {
    final cfg = _statusConfig(order.status);
    if (cfg.hidden) return const SizedBox.shrink();

    // ✅ Use realActions — not cfg.actions (which has empty stubs)
    final actions = _resolveActions(order);
    final isUpdating = _updatingOrderId == order.id;

    return GestureDetector(
      onTap: () => context.pushNamed(
        'kitchen-order-details',
        pathParameters: {'orderNumber': order.orderId},
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        clipBehavior: Clip.hardEdge,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Left status panel ──
              Container(
                width: 52,
                color: cfg.color,
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Icon(cfg.icon, color: Colors.white, size: 20),
                    RotatedBox(
                      quarterTurns: 3,
                      child: Text(
                        order.getTimeAgo(),
                        style: WorkSansAppTextStyles.medium.copyWith(
                          fontSize: 10,
                          color: Colors.white.withValues(alpha: 0.85),
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // ── Card body ──
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header row: order ID + table + status pill
                      Row(
                        children: [
                          Text(
                            order.orderId,
                            style: WorkSansAppTextStyles.medium.copyWith(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: cfg.color,
                            ),
                          ),
                          if (order.tableNumber != null) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF0F0F0),
                                borderRadius: BorderRadius.circular(5),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.table_restaurant_rounded,
                                    size: 11,
                                    color: Colors.grey[600],
                                  ),
                                  const SizedBox(width: 3),
                                  Text(
                                    order.tableNumber!,
                                    style: WorkSansAppTextStyles.medium
                                        .copyWith(
                                          fontSize: 11,
                                          color: Colors.grey[600],
                                          fontWeight: FontWeight.w600,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: cfg.color.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              cfg.label,
                              style: WorkSansAppTextStyles.medium.copyWith(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: cfg.color,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 7),

                      // Customer name
                      Text(
                        order.customerName,
                        style: WorkSansAppTextStyles.medium.copyWith(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1A1A1A),
                        ),
                      ),

                      const SizedBox(height: 3),

                      // Items summary
                      Text(
                        order.getItemsSummary(),
                        style: WorkSansAppTextStyles.medium.copyWith(
                          fontSize: 13,
                          color: const Color(0xFF888888),
                          height: 1.4,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),

                      // Special instructions
                      if (order.specialInstructions != null) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFFBEB),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFFFE082)),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(
                                Icons.info_outline_rounded,
                                size: 13,
                                color: Color(0xFFF59E0B),
                              ),
                              const SizedBox(width: 5),
                              Expanded(
                                child: Text(
                                  order.specialInstructions!,
                                  style: WorkSansAppTextStyles.medium.copyWith(
                                    fontSize: 12,
                                    color: const Color(0xFF92400E),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      // ✅ Action buttons using resolvedActions
                      if (actions.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        if (isUpdating)
                          Center(
                            child: SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  cfg.color,
                                ),
                              ),
                            ),
                          )
                        else
                          Row(
                            children: List.generate(actions.length, (i) {
                              final action = actions[i];
                              final isPrimary = i == 0;
                              return Expanded(
                                child: Padding(
                                  padding: EdgeInsets.only(
                                    left: i == 0 ? 0 : 8,
                                  ),
                                  child: GestureDetector(
                                    onTap: action.onPressed,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 10,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isPrimary
                                            ? cfg.color
                                            : const Color(0xFFF5F5F5),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      alignment: Alignment.center,
                                      child: Text(
                                        action.label,
                                        style: WorkSansAppTextStyles.medium
                                            .copyWith(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                              color: isPrimary
                                                  ? Colors.white
                                                  : const Color(0xFF666666),
                                            ),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }),
                          ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Status config (icons + colors + labels only — NO actions here) ─────────

  _StatusConfig _statusConfig(String status) {
    switch (status.toUpperCase()) {
      case 'PENDING':
        return const _StatusConfig(
          hidden: true,
          color: Colors.grey,
          icon: Icons.circle,
          label: '',
        );
      case 'IN_QUEUE':
        return const _StatusConfig(
          color: Color(0xFF4A6FE3),
          icon: Icons.queue_rounded,
          label: 'IN QUEUE',
        );
      case 'CONFIRMED':
        return const _StatusConfig(
          color: Color(0xFF9C27B0),
          icon: Icons.check_circle_outline_rounded,
          label: 'CONFIRMED',
        );
      case 'PREPARING':
        return _StatusConfig(
          color: kPrimary,
          icon: Icons.outdoor_grill_rounded,
          label: 'PREPARING',
        );
      case 'READY':
        return const _StatusConfig(
          color: Color(0xFF00ACC1),
          icon: Icons.done_all_rounded,
          label: 'READY',
        );
      case 'SERVED':
        return const _StatusConfig(
          color: Color(0xFF2D9B6F),
          icon: Icons.restaurant_rounded,
          label: 'SERVED',
        );
      case 'COMPLETED':
        return const _StatusConfig(
          color: Color(0xFF388E3C),
          icon: Icons.verified_rounded,
          label: 'COMPLETED',
        );
      case 'CANCELLED':
        return const _StatusConfig(
          color: Color(0xFFE57373),
          icon: Icons.cancel_outlined,
          label: 'CANCELLED',
        );
      default:
        return _StatusConfig(
          color: Colors.grey,
          icon: Icons.help_outline,
          label: status.toUpperCase(),
        );
    }
  }

  // ── Actions (real callbacks — the only place actions are defined) ──────────

  List<_OrderAction> _resolveActions(KitchenOrder order) {
    switch (order.status.toUpperCase()) {
      case 'IN_QUEUE':
        return [
          _OrderAction(
            label: 'Confirm',
            onPressed: () {
              setState(() => _updatingOrderId = order.id);
              _dispatch(MarkOrderAsComfirmed(order.id));
            },
          ),
          _OrderAction(
            label: 'Cancel',
            isPrimary: false,
            onPressed: () => _confirmCancel(order),
          ),
        ];
      case 'CONFIRMED':
        return [
          _OrderAction(
            label: 'Start Prep',
            onPressed: () {
              setState(() => _updatingOrderId = order.id);
              _dispatch(StartOrderPreparation(order.id));
            },
          ),
          _OrderAction(
            label: 'Cancel',
            isPrimary: false,
            onPressed: () => _confirmCancel(order),
          ),
        ];
      case 'PREPARING':
        return [
          _OrderAction(
            label: 'Mark Ready',
            onPressed: () {
              setState(() => _updatingOrderId = order.id);
              _dispatch(MarkOrderAsReady(order.id));
            },
          ),
          _OrderAction(
            label: 'Cancel',
            isPrimary: false,
            onPressed: () => _confirmCancel(order),
          ),
        ];
      case 'READY':
        return [
          _OrderAction(
            label: 'Mark Served',
            onPressed: () {
              setState(() => _updatingOrderId = order.id);
              _dispatch(MarkOrderAsServed(order.id));
            },
          ),
        ];
      case 'SERVED':
        return [
          _OrderAction(
            label: 'Mark Completed',
            onPressed: () {
              setState(() => _updatingOrderId = order.id);
              _dispatch(MarkOrderAsCompleted(order.id));
            },
          ),
        ];
      default:
        return [];
    }
  }

  // ── Empty / Error / Loading ────────────────────────────────────────────────

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: kPrimary, strokeWidth: 2.5),
          const SizedBox(height: 16),
          Text(
            'Loading orders...',
            style: WorkSansAppTextStyles.medium.copyWith(
              fontSize: 14,
              color: const Color(0xFF888888),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: kPrimary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.receipt_long_rounded,
                size: 36,
                color: kPrimary,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'No orders yet',
              style: WorkSansAppTextStyles.medium.copyWith(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1A1A1A),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Orders will show up here as customers place them',
              style: WorkSansAppTextStyles.medium.copyWith(
                fontSize: 13,
                color: const Color(0xFF888888),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            GestureDetector(
              onTap: () => _dispatch(const RefreshDashboardData()),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: kPrimary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Refresh',
                  style: WorkSansAppTextStyles.medium.copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoOrdersForFilter(OrderFilter filter) {
    final messages = {
      OrderFilter.newOrder: 'No new orders right now',
      OrderFilter.inProgress: 'Nothing in progress',
      OrderFilter.completed: 'No completed orders yet',
    };
    final message = messages[filter] ?? 'No orders';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 60),
      child: Column(
        children: [
          Icon(Icons.inbox_rounded, size: 48, color: Colors.grey[300]),
          const SizedBox(height: 12),
          Text(
            message,
            style: WorkSansAppTextStyles.medium.copyWith(
              fontSize: 14,
              color: const Color(0xFFAAAAAA),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(DashboardError state) {
    final configs = {
      DashboardErrorType.network: (
        Icons.wifi_off_rounded,
        'No connection',
        'Check your network and pull down to retry',
      ),
      DashboardErrorType.timeout: (
        Icons.timer_off_rounded,
        'Timed out',
        'The request took too long — pull down to retry',
      ),
      DashboardErrorType.server: (
        Icons.cloud_off_rounded,
        'Server error',
        'Something went wrong on our end',
      ),
    };

    final (icon, title, message) =
        configs[state.errorType] ??
        (Icons.error_outline_rounded, 'Something went wrong', state.error);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 32, color: const Color(0xFFE57373)),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: WorkSansAppTextStyles.medium.copyWith(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1A1A1A),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              style: WorkSansAppTextStyles.medium.copyWith(
                fontSize: 13,
                color: const Color(0xFF888888),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            GestureDetector(
              onTap: () => _dispatch(const LoadDashboardData()),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: kPrimary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Try Again',
                  style: WorkSansAppTextStyles.medium.copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Data classes ───────────────────────────────────────────────────────────────

class _OrderAction {
  const _OrderAction({
    required this.label,
    required this.onPressed,
    this.isPrimary = true,
  });
  final String label;
  final VoidCallback onPressed;
  final bool isPrimary;
}

class _StatusConfig {
  const _StatusConfig({
    this.hidden = false,
    required this.color,
    required this.icon,
    required this.label,
  });
  final bool hidden;
  final Color color;
  final IconData icon;
  final String label;
}

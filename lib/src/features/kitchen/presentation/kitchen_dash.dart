import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:sandwich_ai/src/core/globals/notifications/notification_bell.dart';
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
    final reasonController = TextEditingController();
    String? errorText;
    final reason = await showDialog<String>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            'Cancel Order',
            style: WorkSansAppTextStyles.medium.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Cancel order ${order.orderId} for ${order.customerName}?',
                style: WorkSansAppTextStyles.medium.copyWith(
                  color: context.modeTextSecondary,
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: reasonController,
                minLines: 3,
                maxLines: 5,
                textInputAction: TextInputAction.newline,
                decoration: InputDecoration(
                  labelText: 'Reason',
                  hintText: 'Explain why this order is being cancelled',
                  errorText: errorText,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                'Keep',
                style: WorkSansAppTextStyles.medium.copyWith(
                  color: context.modeTextMuted,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                final trimmedReason = reasonController.text.trim();
                if (trimmedReason.isEmpty) {
                  setDialogState(() {
                    errorText = 'Cancellation reason is required';
                  });
                  return;
                }
                Navigator.pop(ctx, trimmedReason);
              },
              style: TextButton.styleFrom(foregroundColor: context.modeError),
              child: Text(
                'Yes, Cancel',
                style: WorkSansAppTextStyles.medium.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
    reasonController.dispose();
    if (reason != null && mounted) {
      setState(() => _updatingOrderId = order.id);
      _dispatch(CancelOrder(order.id, reason: reason));
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
        backgroundColor: context.modeBackground,
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
                      color: context.modeTextInverse,
                    ),
                  ),
                  backgroundColor: context.modeSuccess,
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
                      color: context.modeTextInverse,
                    ),
                  ),
                  backgroundColor: context.modeError,
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
            if (state is DashboardLoading) {
              return _buildLoadingState();
            }
            if (state is DashboardLoaded) {
              return _buildLoadedState(
                state.dashboardData,
                state.filteredOrders,
              );
            }
            if (state is DashboardRefreshing) {
              return _buildLoadedState(
                state.currentData,
                state.currentData.recentOrders,
                isRefreshing: true,
              );
            }
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
      backgroundColor: context.modeSurface,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      leading: IconButton(
        icon: Icon(Icons.menu_rounded, color: context.modeTextPrimary),
        onPressed: () => _scaffoldKey.currentState?.openDrawer(),
      ),
      title: Text(
        'Live Orders',
        style: WorkSansAppTextStyles.medium.copyWith(
          fontSize: 17,
          fontWeight: FontWeight.w700,
          color: context.modeTextPrimary,
        ),
      ),
      centerTitle: true,
      actions: [
        const NotificationBellAction(margin: EdgeInsets.zero),
        IconButton(
          icon: Icon(Icons.refresh_rounded, color: context.modePrimary),
          onPressed: () => _dispatch(const RefreshDashboardData()),
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: context.modeDivider),
      ),
    );
  }

  // ── Loaded state ───────────────────────────────────────────────────────────

  Widget _buildLoadedState(
    KitchenDashboardData data,
    List<KitchenOrder> orders, {
    bool isRefreshing = false,
  }) {
    final sortedOrders = [...orders]
      ..sort((a, b) => b.orderedAt.compareTo(a.orderedAt));

    return Stack(
      children: [
        RefreshIndicator(
          onRefresh: () async {
            _dispatch(const RefreshDashboardData());
            await Future.delayed(const Duration(seconds: 1));
          },
          color: context.modePrimary,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
            children: [
              _buildStatsRow(data),
              const SizedBox(height: 14),
              _buildOrderStatsChart(data.orderStats),
              const SizedBox(height: 18),
              if (sortedOrders.isEmpty)
                _buildNoOrdersForFilter(OrderFilter.all)
              else
                ...sortedOrders.map(
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
              color: context.modePrimary,
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
          color: context.modePrimary,
          bg: context.modePrimary.withValues(alpha: 0.08),
          icon: Icons.pending_actions_rounded,
        ),
        const SizedBox(width: 10),
        _statCard(
          label: 'Delivered',
          value: '${data.orderStats.ordersDelivered}',
          color: context.modeSuccess,
          bg: context.modeSuccess.withValues(alpha: 0.12),
          icon: Icons.check_circle_rounded,
        ),
        const SizedBox(width: 10),
        _statCard(
          label: 'Staff',
          value: '${data.staffOnDuty.total}',
          color: context.modeInfo,
          bg: context.modeInfo.withValues(alpha: 0.12),
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
                    fontWeight: FontWeight.w700,
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

  // ── Order card ─────────────────────────────────────────────────────────────

  Widget _buildOrderCard(KitchenOrder order) {
    final cfg = _statusConfig(order.status);

    // ✅ Use realActions — not cfg.actions (which has empty stubs)
    final actions = _resolveActions(order);
    final isUpdating = _updatingOrderId == order.id;
    final kitchenNote = _kitchenNotePreview(order.specialInstructions);

    return GestureDetector(
      onTap: () => context.pushNamed(
        'kitchen-order-details',
        pathParameters: {'orderNumber': order.orderId},
      ),
      child: Container(
        decoration: BoxDecoration(
          color: context.modeSurface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: context.modeTextPrimary.withValues(alpha: 0.04),
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
                    Icon(cfg.icon, color: context.modeTextInverse, size: 20),
                    RotatedBox(
                      quarterTurns: 3,
                      child: Text(
                        order.getTimeAgo(),
                        style: WorkSansAppTextStyles.medium.copyWith(
                          fontSize: 11,
                          color: context.modeTextInverse.withValues(
                            alpha: 0.85,
                          ),
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0,
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
                                color: context.modeSurfaceAlt,
                                borderRadius: BorderRadius.circular(5),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.table_restaurant_rounded,
                                    size: 11,
                                    color: context.modeTextMuted,
                                  ),
                                  const SizedBox(width: 3),
                                  Text(
                                    order.tableNumber!,
                                    style: WorkSansAppTextStyles.medium
                                        .copyWith(
                                          fontSize: 11,
                                          color: context.modeTextMuted,
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
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: cfg.color,
                                letterSpacing: 0,
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
                          color: context.modeTextPrimary,
                        ),
                      ),

                      const SizedBox(height: 3),

                      // Items summary
                      Text(
                        order.getItemsSummary(),
                        style: WorkSansAppTextStyles.medium.copyWith(
                          fontSize: 13,
                          color: context.modeTextSecondary,
                          height: 1.4,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),

                      // Special instructions
                      if (kitchenNote.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
                          decoration: BoxDecoration(
                            color: context.modeWarning.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: context.modeWarning.withValues(
                                alpha: 0.35,
                              ),
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.info_outline_rounded,
                                size: 13,
                                color: context.modeWarning,
                              ),
                              const SizedBox(width: 5),
                              Expanded(
                                child: Text(
                                  kitchenNote,
                                  style: WorkSansAppTextStyles.medium.copyWith(
                                    fontSize: 12,
                                    color: context.modeWarning,
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
                                            : context.modeSurfaceAlt,
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
                                                  ? context.modeTextInverse
                                                  : context.modeTextSecondary,
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
        return _StatusConfig(
          color: context.modeWarning,
          icon: Icons.receipt_long_rounded,
          label: 'PENDING',
        );
      case 'IN_QUEUE':
        return _StatusConfig(
          color: context.modeInfo,
          icon: Icons.queue_rounded,
          label: 'IN QUEUE',
        );
      case 'CONFIRMED':
        return _StatusConfig(
          color: context.modePrimaryBlue,
          icon: Icons.check_circle_outline_rounded,
          label: 'NEW ORDER',
        );
      case 'PREPARING':
        return _StatusConfig(
          color: context.modePrimary,
          icon: Icons.outdoor_grill_rounded,
          label: 'PREPARING',
        );
      case 'READY':
        return _StatusConfig(
          color: context.modeInfo,
          icon: Icons.done_all_rounded,
          label: 'READY',
        );
      case 'SERVED':
        return _StatusConfig(
          color: context.modeSuccess,
          icon: Icons.restaurant_rounded,
          label: 'SERVED',
        );
      case 'COMPLETED':
        return _StatusConfig(
          color: context.modeSuccess,
          icon: Icons.verified_rounded,
          label: 'COMPLETED',
        );
      case 'CANCELLED':
        return _StatusConfig(
          color: context.modeError,
          icon: Icons.cancel_outlined,
          label: 'CANCELLED',
        );
      default:
        return _StatusConfig(
          color: context.modeTextMuted,
          icon: Icons.help_outline,
          label: status.toUpperCase(),
        );
    }
  }

  // ── Actions (real callbacks — the only place actions are defined) ──────────

  List<_OrderAction> _resolveActions(KitchenOrder order) {
    switch (order.status.toUpperCase()) {
      case 'PENDING':
        return [];
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
            label: 'Start Preparation',
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

  String _kitchenNotePreview(String? value) {
    final note = value?.trim();
    if (note == null || note.isEmpty) return '';

    return note
        .split(RegExp(r'\r?\n'))
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty && !_looksLikeAddress(line))
        .join('\n');
  }

  bool _looksLikeAddress(String line) {
    final lower = line.toLowerCase();
    final startsWithHouseNumber = RegExp(r'^(no\.?\s*)?\d+\s+').hasMatch(lower);
    final hasAddressWord = RegExp(
      r'\b(street|st\.?|road|rd\.?|avenue|ave\.?|close|crescent|lane|estate|drive|dr\.?|block|plot|house|flat)\b',
    ).hasMatch(lower);

    return startsWithHouseNumber && hasAddressWord;
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: context.modePrimary,
            strokeWidth: 2.5,
          ),
          const SizedBox(height: 16),
          Text(
            'Loading orders...',
            style: WorkSansAppTextStyles.medium.copyWith(
              fontSize: 14,
              color: context.modeTextSecondary,
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
                color: context.modePrimary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.receipt_long_rounded,
                size: 36,
                color: context.modePrimary,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'No orders yet',
              style: WorkSansAppTextStyles.medium.copyWith(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: context.modeTextPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Orders will show up here as customers place them',
              style: WorkSansAppTextStyles.medium.copyWith(
                fontSize: 13,
                color: context.modeTextSecondary,
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
                  color: context.modePrimary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Refresh',
                  style: WorkSansAppTextStyles.medium.copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: context.modeTextInverse,
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
          Icon(
            Icons.inbox_rounded,
            size: 48,
            color: context.modeTextMuted.withValues(alpha: 0.45),
          ),
          const SizedBox(height: 12),
          Text(
            message,
            style: WorkSansAppTextStyles.medium.copyWith(
              fontSize: 14,
              color: context.modeTextMuted,
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
                color: context.modeError.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 32, color: context.modeError),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: WorkSansAppTextStyles.medium.copyWith(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: context.modeTextPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              style: WorkSansAppTextStyles.medium.copyWith(
                fontSize: 13,
                color: context.modeTextSecondary,
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
                  color: context.modePrimary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Try Again',
                  style: WorkSansAppTextStyles.medium.copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: context.modeTextInverse,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderStatsChart(OrderStats stats) {
    final total =
        stats.ongoingOrders + stats.ordersDelivered + stats.ordersReceived;
    if (total == 0) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.modeSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.modeBorder.withValues(alpha: 0.55)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Order Statistics',
            style: WorkSansAppTextStyles.medium.copyWith(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: context.modeTextPrimary,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                flex: 4,
                child: SizedBox(
                  height: 120,
                  child: PieChart(
                    PieChartData(
                      sectionsSpace: 4,
                      centerSpaceRadius: 28,
                      sections: [
                        PieChartSectionData(
                          color: context.modePrimary,
                          value: stats.ongoingOrders.toDouble(),
                          title:
                              '${((stats.ongoingOrders / total) * 100).toStringAsFixed(0)}%',
                          radius: 25,
                          titleStyle: WorkSansAppTextStyles.medium.copyWith(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: context.modeTextInverse,
                          ),
                        ),
                        PieChartSectionData(
                          color: context.modeSuccess,
                          value: stats.ordersDelivered.toDouble(),
                          title:
                              '${((stats.ordersDelivered / total) * 100).toStringAsFixed(0)}%',
                          radius: 25,
                          titleStyle: WorkSansAppTextStyles.medium.copyWith(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: context.modeTextInverse,
                          ),
                        ),
                        PieChartSectionData(
                          color: context.modeInfo,
                          value: stats.ordersReceived.toDouble(),
                          title:
                              '${((stats.ordersReceived / total) * 100).toStringAsFixed(0)}%',
                          radius: 25,
                          titleStyle: WorkSansAppTextStyles.medium.copyWith(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: context.modeTextInverse,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 5,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _chartIndicator(
                      color: context.modePrimary,
                      label: 'Ongoing (${stats.ongoingOrders})',
                    ),
                    const SizedBox(height: 8),
                    _chartIndicator(
                      color: context.modeSuccess,
                      label: 'Delivered (${stats.ordersDelivered})',
                    ),
                    const SizedBox(height: 8),
                    _chartIndicator(
                      color: context.modeInfo,
                      label: 'Received (${stats.ordersReceived})',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _chartIndicator({required Color color, required String label}) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: WorkSansAppTextStyles.medium.copyWith(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: context.modeTextPrimary,
          ),
        ),
      ],
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
    required this.color,
    required this.icon,
    required this.label,
  });
  final Color color;
  final IconData icon;
  final String label;
}

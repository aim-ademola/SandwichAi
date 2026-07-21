import 'package:flutter/material.dart';
import 'package:sandwich_ai/src/core/globals/app_icon.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:sandwich_ai/src/core/constant/textstyle.dart';
import 'package:sandwich_ai/src/core/theme/app_theme_extension.dart';
import 'package:sandwich_ai/src/features/pos/bloc/order_status_bloc/bloc.dart';
import 'package:sandwich_ai/src/features/pos/bloc/order_status_bloc/event.dart';
import 'package:sandwich_ai/src/features/pos/bloc/order_status_bloc/state.dart';
import 'package:sandwich_ai/src/features/pos/data/model/oder_status_model.dart';

class KitchenOrderHistoryScreen extends StatefulWidget {
  const KitchenOrderHistoryScreen({super.key});

  @override
  State<KitchenOrderHistoryScreen> createState() =>
      _KitchenOrderHistoryScreenState();
}

class _KitchenOrderHistoryScreenState extends State<KitchenOrderHistoryScreen> {
  String? _selectedStatus;

  static const _kitchenHistoryStatuses = {
    OrderStatus.confirmed,
    OrderStatus.inQueue,
    OrderStatus.preparing,
    OrderStatus.ready,
    OrderStatus.served,
    OrderStatus.completed,
    OrderStatus.cancelled,
  };

  @override
  void initState() {
    super.initState();
    context.read<KitchenOrdersBloc>().add(const LoadKitchenOrders());
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTextStyle.merge(
      style: WorkSansAppTextStyles.medium,
      child: Scaffold(
        backgroundColor: context.modeBackground,
        appBar: AppBar(
          backgroundColor: context.modeSurface,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
          title: Text(
            'Order History',
            style: WorkSansAppTextStyles.medium.copyWith(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: context.modeTextPrimary,
            ),
          ),
          centerTitle: true,
          actions: [
            IconButton(
              tooltip: 'Refresh',
              onPressed: () => context.read<KitchenOrdersBloc>().add(
                const RefreshKitchenOrders(),
              ),
              icon: AppIcon(Icons.refresh_rounded, color: context.modePrimary),
            ),
          ],
        ),
        body: Column(
          children: [
            _buildFilters(),
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
                    return _buildMessage(
                      icon: Icons.error_outline,
                      title: 'Unable to load history',
                      message: state.error,
                      actionLabel: 'Try Again',
                      onAction: () => context.read<KitchenOrdersBloc>().add(
                        const LoadKitchenOrders(),
                      ),
                    );
                  }

                  final orders = _ordersFromState(state);
                  if (orders.isEmpty) {
                    return _buildMessage(
                      icon: Icons.receipt_long_outlined,
                      title: 'No order history',
                      message: 'Kitchen order history will appear here.',
                      actionLabel: 'Refresh',
                      onAction: () => context.read<KitchenOrdersBloc>().add(
                        const RefreshKitchenOrders(),
                      ),
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
                      padding: const EdgeInsets.all(16),
                      itemCount: orders.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (context, index) =>
                          _HistoryOrderCard(order: orders[index]),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      height: 56,
      color: context.modeSurface,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          _buildFilterChip('All', null),
          const SizedBox(width: 8),
          _buildFilterChip('New Order', OrderStatus.confirmed.value),
          const SizedBox(width: 8),
          _buildFilterChip('Preparing', OrderStatus.preparing.value),
          const SizedBox(width: 8),
          _buildFilterChip('Ready', OrderStatus.ready.value),
          const SizedBox(width: 8),
          _buildFilterChip('Served', OrderStatus.served.value),
          const SizedBox(width: 8),
          _buildFilterChip('Completed', OrderStatus.completed.value),
          const SizedBox(width: 8),
          _buildFilterChip('Cancelled', OrderStatus.cancelled.value),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String? status) {
    final selected = _selectedStatus == status;
    return FilterChip(
      selected: selected,
      showCheckmark: false,
      label: Text(label),
      labelStyle: WorkSansAppTextStyles.medium.copyWith(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: selected ? context.modeTextInverse : context.modeTextPrimary,
      ),
      backgroundColor: context.modeSurfaceAlt,
      selectedColor: context.modePrimary,
      onSelected: (value) {
        setState(() => _selectedStatus = value ? status : null);
      },
    );
  }

  List<KitchenOrder> _ordersFromState(KitchenOrdersState state) {
    final source = switch (state) {
      KitchenOrdersLoaded() => state.orders,
      KitchenOrdersRefreshing() => state.currentData,
      _ => const <KitchenOrder>[],
    };

    final orders = source.where((order) {
      if (!_kitchenHistoryStatuses.contains(order.status)) return false;
      return _selectedStatus == null || order.status.value == _selectedStatus;
    }).toList()..sort((a, b) => b.orderedAt.compareTo(a.orderedAt));

    return orders;
  }

  Widget _buildMessage({
    required IconData icon,
    required String title,
    required String message,
    required String actionLabel,
    required VoidCallback onAction,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AppIcon(icon, size: 64, color: context.modeTextMuted),
            const SizedBox(height: 14),
            Text(
              title,
              textAlign: TextAlign.center,
              style: WorkSansAppTextStyles.medium.copyWith(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: context.modeTextPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: WorkSansAppTextStyles.medium.copyWith(
                fontSize: 14,
                color: context.modeTextSecondary,
              ),
            ),
            const SizedBox(height: 18),
            ElevatedButton.icon(
              onPressed: onAction,
              icon: const AppIcon(Icons.refresh),
              label: Text(actionLabel),
              style: ElevatedButton.styleFrom(
                backgroundColor: context.modePrimary,
                foregroundColor: context.modeTextInverse,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HistoryOrderCard extends StatelessWidget {
  const _HistoryOrderCard({required this.order});

  final KitchenOrder order;

  @override
  Widget build(BuildContext context) {
    final amount = double.tryParse(order.totalAmount) ?? 0;
    final formattedAmount = NumberFormat('#,##0.##').format(amount);
    final statusColor = _statusColor(context, order.status);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.modeSurface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: context.modeBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  order.orderId,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: WorkSansAppTextStyles.medium.copyWith(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: context.modeTextPrimary,
                  ),
                ),
              ),
              _StatusBadge(status: order.status, color: statusColor),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 8,
            children: [
              _InfoChip(icon: Icons.schedule, label: _timeAgo(order.orderedAt)),
              _InfoChip(
                icon: Icons.restaurant_menu,
                label:
                    '${order.items.length} item${order.items.length == 1 ? '' : 's'}',
              ),
              _InfoChip(
                icon: Icons.payments_outlined,
                label: 'N$formattedAmount',
              ),
            ],
          ),
          if ((order.customerName ?? '').trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              order.customerName!.trim(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: WorkSansAppTextStyles.medium.copyWith(
                fontSize: 13,
                color: context.modeTextSecondary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _timeAgo(DateTime dateTime) {
    final diff = DateTime.now().difference(dateTime.toLocal());
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) return '${diff.inHours} hr ago';
    return '${diff.inDays} day ago';
  }

  Color _statusColor(BuildContext context, OrderStatus status) {
    switch (status) {
      case OrderStatus.confirmed:
      case OrderStatus.inQueue:
        return context.modeInfo;
      case OrderStatus.preparing:
        return context.modePrimary;
      case OrderStatus.ready:
      case OrderStatus.served:
      case OrderStatus.completed:
        return context.modeSuccess;
      case OrderStatus.cancelled:
        return context.modeError;
      case OrderStatus.pending:
        return context.modeWarning;
    }
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status, required this.color});

  final OrderStatus status;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final label = status == OrderStatus.confirmed
        ? 'New Order'
        : status.displayName;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: WorkSansAppTextStyles.medium.copyWith(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: color,
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        AppIcon(icon, size: 15, color: context.modeTextMuted),
        const SizedBox(width: 5),
        Text(
          label,
          style: WorkSansAppTextStyles.medium.copyWith(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: context.modeTextSecondary,
          ),
        ),
      ],
    );
  }
}

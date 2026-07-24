import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sandwich_ai/src/core/constant/textstyle.dart';
import 'package:sandwich_ai/src/core/globals/app_icon.dart';
import 'package:sandwich_ai/src/core/theme/app_theme_extension.dart';
import 'package:sandwich_ai/src/features/kitchen/blocs/kitchen-dash_bloc/bloc.dart';
import 'package:sandwich_ai/src/features/kitchen/blocs/kitchen-dash_bloc/event.dart';
import 'package:sandwich_ai/src/features/kitchen/blocs/kitchen-dash_bloc/state.dart';
import 'package:sandwich_ai/src/features/kitchen/data/model/kitchen_dash_model.dart';

class KitchenOrderStatisticsScreen extends StatefulWidget {
  const KitchenOrderStatisticsScreen({super.key});

  @override
  State<KitchenOrderStatisticsScreen> createState() =>
      _KitchenOrderStatisticsScreenState();
}

class _KitchenOrderStatisticsScreenState
    extends State<KitchenOrderStatisticsScreen> {
  @override
  void initState() {
    super.initState();
    context.read<KitchenDashboardBloc>().add(const LoadDashboardData());
  }

  void _refresh() {
    context.read<KitchenDashboardBloc>().add(const RefreshDashboardData());
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
          leading: IconButton(
            icon: AppIcon(Icons.arrow_back, color: context.modeTextPrimary),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            'Order Statistics',
            style: WorkSansAppTextStyles.medium.copyWith(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: context.modeTextPrimary,
            ),
          ),
          centerTitle: true,
          actions: [
            IconButton(
              icon: AppIcon(Icons.refresh_rounded, color: context.modePrimary),
              onPressed: _refresh,
            ),
          ],
        ),
        body: BlocBuilder<KitchenDashboardBloc, KitchenDashboardState>(
          buildWhen: (previous, current) =>
              current is! OrderActionSuccess && current is! OrderActionError,
          builder: (context, state) {
            if (state is DashboardLoaded) {
              return _StatisticsBody(data: state.dashboardData);
            }
            if (state is DashboardError) {
              return _StateMessage(
                icon: Icons.error_outline,
                title: 'Could not load statistics',
                message: state.error,
                onRetry: _refresh,
              );
            }
            return Center(
              child: CircularProgressIndicator(color: context.modePrimary),
            );
          },
        ),
      ),
    );
  }
}

class _StatisticsBody extends StatelessWidget {
  final KitchenDashboardData data;

  const _StatisticsBody({required this.data});

  @override
  Widget build(BuildContext context) {
    final stats = data.orderStats;
    final total =
        stats.ongoingOrders + stats.ordersDelivered + stats.ordersReceived;

    return RefreshIndicator(
      color: context.modePrimary,
      onRefresh: () async {
        context.read<KitchenDashboardBloc>().add(const RefreshDashboardData());
      },
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _StatsChart(stats: stats),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _MetricTile(
                  icon: Icons.pending_actions_rounded,
                  label: 'Ongoing',
                  value: stats.ongoingOrders.toString(),
                  color: context.modePrimary,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MetricTile(
                  icon: Icons.check_circle_rounded,
                  label: 'Delivered',
                  value: stats.ordersDelivered.toString(),
                  color: context.modeSuccess,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _MetricTile(
                  icon: Icons.inbox_rounded,
                  label: 'Received',
                  value: stats.ordersReceived.toString(),
                  color: context.modeInfo,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MetricTile(
                  icon: Icons.receipt_long,
                  label: 'Total',
                  value: total.toString(),
                  color: context.modeTextPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _MetricTile(
            icon: Icons.people_alt_rounded,
            label: 'Staff on Duty',
            value: data.staffOnDuty.total.toString(),
            color: context.modeInfo,
          ),
        ],
      ),
    );
  }
}

class _StatsChart extends StatelessWidget {
  final OrderStats stats;

  const _StatsChart({required this.stats});

  @override
  Widget build(BuildContext context) {
    final total =
        stats.ongoingOrders + stats.ordersDelivered + stats.ordersReceived;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.modeSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.modeBorder.withValues(alpha: 0.55)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Order Statistics',
            style: WorkSansAppTextStyles.medium.copyWith(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: context.modeTextPrimary,
            ),
          ),
          const SizedBox(height: 18),
          if (total == 0)
            const _StateMessage(
              icon: Icons.pie_chart_outline,
              title: 'No order statistics yet',
              message: '',
            )
          else
            Row(
              children: [
                Expanded(
                  flex: 4,
                  child: SizedBox(
                    height: 150,
                    child: PieChart(
                      PieChartData(
                        sectionsSpace: 4,
                        centerSpaceRadius: 36,
                        sections: [
                          _section(
                            context,
                            color: context.modePrimary,
                            value: stats.ongoingOrders,
                            total: total,
                          ),
                          _section(
                            context,
                            color: context.modeSuccess,
                            value: stats.ordersDelivered,
                            total: total,
                          ),
                          _section(
                            context,
                            color: context.modeInfo,
                            value: stats.ordersReceived,
                            total: total,
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
                    children: [
                      _ChartIndicator(
                        color: context.modePrimary,
                        label: 'Ongoing (${stats.ongoingOrders})',
                      ),
                      const SizedBox(height: 10),
                      _ChartIndicator(
                        color: context.modeSuccess,
                        label: 'Delivered (${stats.ordersDelivered})',
                      ),
                      const SizedBox(height: 10),
                      _ChartIndicator(
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

  PieChartSectionData _section(
    BuildContext context, {
    required Color color,
    required int value,
    required int total,
  }) {
    final percent = total == 0 ? 0 : (value / total) * 100;
    return PieChartSectionData(
      color: color,
      value: value.toDouble(),
      title: value == 0 ? '' : '${percent.toStringAsFixed(0)}%',
      radius: 34,
      titleStyle: WorkSansAppTextStyles.medium.copyWith(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: context.modeTextInverse,
      ),
    );
  }
}

class _ChartIndicator extends StatelessWidget {
  final Color color;
  final String label;

  const _ChartIndicator({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: WorkSansAppTextStyles.medium.copyWith(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: context.modeTextPrimary,
            ),
          ),
        ),
      ],
    );
  }
}

class _MetricTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _MetricTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 92),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.modeSurface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(child: AppIcon(icon, color: color, size: 20)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: WorkSansAppTextStyles.medium.copyWith(
                    fontSize: 12,
                    color: context.modeTextSecondary,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: WorkSansAppTextStyles.medium.copyWith(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StateMessage extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final VoidCallback? onRetry;

  const _StateMessage({
    required this.icon,
    required this.title,
    required this.message,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppIcon(icon, size: 54, color: context.modeTextMuted),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: WorkSansAppTextStyles.medium.copyWith(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: context.modeTextPrimary,
              ),
            ),
            if (message.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                message,
                textAlign: TextAlign.center,
                style: WorkSansAppTextStyles.medium.copyWith(
                  fontSize: 13,
                  color: context.modeTextSecondary,
                ),
              ),
            ],
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
            ],
          ],
        ),
      ),
    );
  }
}

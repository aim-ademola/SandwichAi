import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:sandwich_ai/src/core/constant/textstyle.dart';
import 'package:sandwich_ai/src/core/globals/notifications/notification_bell.dart';
import 'package:sandwich_ai/src/core/local_sandbox/drawer_onboarding_cache.dart';
import 'package:sandwich_ai/src/core/theme/app_theme_extension.dart';
import 'package:sandwich_ai/src/features/pos/bloc/pos_dashboard_state_bloc/bloc.dart';
import 'package:sandwich_ai/src/features/pos/bloc/pos_dashboard_state_bloc/event.dart';
import 'package:sandwich_ai/src/features/pos/bloc/pos_dashboard_state_bloc/state.dart';
import 'package:sandwich_ai/src/features/pos/data/model/pos_dashboard_summary.dart';
import 'package:sandwich_ai/src/features/pos/presentation/pos_drawer.dart';
import 'package:showcaseview/showcaseview.dart';

class PosDashboardScreen extends StatefulWidget {
  const PosDashboardScreen({super.key});

  @override
  State<PosDashboardScreen> createState() => _PosDashboardScreenState();
}

class _PosDashboardScreenState extends State<PosDashboardScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final GlobalKey _activeOrdersTourKey = GlobalKey();
  late final ShowcaseView _showcaseView;
  bool _activeOrdersTourQueued = false;

  @override
  void initState() {
    super.initState();
    _showcaseView = ShowcaseView.register(
      onFinish:
          DrawerOnboardingCache.instance.markPosDashboardActiveOrdersTourSeen,
      blurValue: 1,
    );
    context.read<DashboardBloc>().add(const LoadDashboardSummary());
  }

  @override
  void dispose() {
    _showcaseView.unregister();
    super.dispose();
  }

  Future<void> _queueActiveOrdersTour() async {
    if (_activeOrdersTourQueued) return;
    _activeOrdersTourQueued = true;

    final hasSeenTour = await DrawerOnboardingCache.instance
        .hasSeenPosDashboardActiveOrdersTour();
    if (hasSeenTour || !mounted) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _showcaseView.startShowCase([_activeOrdersTourKey]);
    });
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTextStyle.merge(
      style: WorkSansAppTextStyles.medium,
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: context.modeBackground,
        drawer: const PosAppDrawer(),
        appBar: AppBar(
          backgroundColor: context.modeSurface,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
          leading: IconButton(
            icon: Icon(Icons.menu, color: context.modeTextPrimary),
            onPressed: () => _scaffoldKey.currentState?.openDrawer(),
          ),
          title: Text(
            'SandwichAI',
            style: WorkSansAppTextStyles.medium.copyWith(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: context.modeTextPrimary,
            ),
          ),
          actions: [
            const NotificationBellAction(margin: EdgeInsets.zero),
            BlocBuilder<DashboardBloc, DashboardState>(
              builder: (context, state) {
                return IconButton(
                  icon: Icon(
                    Icons.refresh,
                    color: state is DashboardRefreshing
                        ? context.modeTextMuted
                        : context.modeTextPrimary,
                  ),
                  onPressed: state is DashboardRefreshing
                      ? null
                      : () => context.read<DashboardBloc>().add(
                          const RefreshDashboardSummary(),
                        ),
                );
              },
            ),
          ],
        ),
        body: BlocBuilder<DashboardBloc, DashboardState>(
          builder: (context, state) {
            if (state is DashboardLoading) {
              return Center(
                child: CircularProgressIndicator(color: context.modePrimary),
              );
            }

            if (state is DashboardError) {
              return _buildErrorState(state.error);
            }

            if (state is DashboardLoaded || state is DashboardRefreshing) {
              _queueActiveOrdersTour();
              final summary = state is DashboardLoaded
                  ? state.summary
                  : (state as DashboardRefreshing).currentSummary;

              return Stack(
                children: [
                  RefreshIndicator(
                    color: context.modePrimary,
                    onRefresh: () async {
                      context.read<DashboardBloc>().add(
                        const RefreshDashboardSummary(),
                      );
                    },
                    child: _buildDashboardContent(summary),
                  ),
                  if (state is DashboardRefreshing)
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      child: LinearProgressIndicator(
                        backgroundColor: context.modeSurfaceMuted,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          context.modePrimary,
                        ),
                      ),
                    ),
                ],
              );
            }

            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  Widget _buildDashboardContent(DashboardSummaryModel summary) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final padding = _getHorizontalPadding(constraints.maxWidth);

        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.fromLTRB(padding, 18, padding, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildActionGrid(constraints.maxWidth),
              const SizedBox(height: 24),
              _buildSectionHeader(
                title: "Today's Performance",
                subtitle: 'Key business metrics for today.',
              ),
              const SizedBox(height: 14),
              _buildKpiGrid(summary, constraints.maxWidth),
              const SizedBox(height: 24),
              _buildSectionHeader(
                title: 'Operational Intelligence',
                subtitle: 'Conversion flow and order movement at a glance.',
              ),
              const SizedBox(height: 14),
              _buildSalesFunnelCard(summary),
              const SizedBox(height: 14),
              _buildOperationalSummary(summary),
            ],
          ),
        );
      },
    );
  }

  Widget _buildActionGrid(double width) {
    final spacing = _getSpacing(width);
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: spacing,
      mainAxisSpacing: spacing,
      childAspectRatio: width < 360 ? 1.08 : 1.18,
      children: [
        _buildActionCard(
          icon: Icons.shopping_cart_outlined,
          label: 'New Order',
          onTap: () => context.goNamed('Pos-nav', extra: 1),
        ),
        _buildActionCard(
          icon: Icons.receipt_long_outlined,
          label: 'Active Orders',
          onTap: () => context.goNamed('Pos-nav', extra: 2),
          showcaseKey: _activeOrdersTourKey,
          showcaseDescription:
              'Use Active Orders to continue orders already sent to kitchen, take payment, and check completion status.',
        ),
      ],
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    GlobalKey? showcaseKey,
    String? showcaseDescription,
  }) {
    final card = Material(
      color: context.modePrimary,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 38, color: context.modeTextInverse),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: WorkSansAppTextStyles.medium.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: context.modeTextInverse,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.chevron_right,
                    size: 22,
                    color: context.modeTextInverse,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (showcaseKey == null || showcaseDescription == null) return card;

    return Showcase(
      key: showcaseKey,
      description: showcaseDescription,
      targetBorderRadius: BorderRadius.circular(14),
      tooltipBackgroundColor: context.modePrimary,
      textColor: context.modeTextInverse,
      targetPadding: const EdgeInsets.all(8),
      child: card,
    );
  }

  Widget _buildSectionHeader({
    required String title,
    required String subtitle,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: WorkSansAppTextStyles.medium.copyWith(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: context.modeTextPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: WorkSansAppTextStyles.medium.copyWith(
            fontSize: 12,
            color: context.modeTextSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildKpiGrid(DashboardSummaryModel summary, double width) {
    final cards = [
      _KpiData(
        label: 'Revenue',
        value: summary.formattedSales,
        icon: Icons.payments_outlined,
        color: context.modeSuccess,
      ),
      _KpiData(
        label: 'Orders',
        value: '${summary.totalOrders}',
        icon: Icons.receipt_long_outlined,
        color: context.modeInfo,
      ),
      _KpiData(
        label: 'Avg Order',
        value: summary.formattedAvgOrder,
        icon: Icons.trending_up_rounded,
        color: context.modePrimary,
      ),
      _KpiData(
        label: 'Pending Pay',
        value: '${summary.pendingOrders}',
        icon: Icons.hourglass_bottom_rounded,
        color: context.modeWarning,
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: cards.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: _getSpacing(width),
        mainAxisSpacing: _getSpacing(width),
        childAspectRatio: width < 360 ? 1.18 : 1.34,
      ),
      itemBuilder: (context, index) => _buildKpiCard(cards[index]),
    );
  }

  Widget _buildKpiCard(_KpiData data) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.modeSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.modeBorder.withValues(alpha: 0.55)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: data.color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(data.icon, color: data.color, size: 21),
          ),
          const Spacer(),
          Text(
            data.value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: WorkSansAppTextStyles.medium.copyWith(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: context.modeTextPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            data.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: WorkSansAppTextStyles.medium.copyWith(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: context.modeTextSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSalesFunnelCard(DashboardSummaryModel summary) {
    final stages = summary.funnelOrFallback;
    final maxValue = stages.fold<double>(
      0,
      (previous, stage) => math.max(previous, stage.value),
    );

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
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: context.modePrimary.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.filter_alt_outlined,
                  color: context.modePrimary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Sales Funnel',
                      style: WorkSansAppTextStyles.medium.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: context.modeTextPrimary,
                      ),
                    ),
                    Text(
                      'Stage-by-stage order conversion',
                      style: WorkSansAppTextStyles.medium.copyWith(
                        fontSize: 12,
                        color: context.modeTextSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          if (stages.isEmpty || maxValue <= 0)
            _buildNoFunnelData()
          else ...[
            SizedBox(
              height: 190,
              child: BarChart(
                BarChartData(
                  minY: 0,
                  maxY: maxValue * 1.2,
                  alignment: BarChartAlignment.spaceAround,
                  gridData: const FlGridData(show: false),
                  borderData: FlBorderData(show: false),
                  titlesData: const FlTitlesData(show: false),
                  barTouchData: BarTouchData(enabled: false),
                  barGroups: [
                    for (var i = 0; i < stages.length; i++)
                      BarChartGroupData(
                        x: i,
                        barRods: [
                          BarChartRodData(
                            toY: stages[i].value,
                            width: 24,
                            borderRadius: BorderRadius.circular(6),
                            color: _funnelColor(i),
                            backDrawRodData: BackgroundBarChartRodData(
                              show: true,
                              toY: maxValue * 1.2,
                              color: context.modeSurfaceMuted.withValues(
                                alpha: 0.55,
                              ),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            ...stages.asMap().entries.map(
              (entry) => _buildFunnelStageRow(
                stage: entry.value,
                color: _funnelColor(entry.key),
                maxValue: maxValue,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildNoFunnelData() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
      decoration: BoxDecoration(
        color: context.modeSurfaceAlt,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        'No funnel data available yet',
        textAlign: TextAlign.center,
        style: WorkSansAppTextStyles.medium.copyWith(
          fontSize: 13,
          color: context.modeTextSecondary,
        ),
      ),
    );
  }

  Widget _buildFunnelStageRow({
    required SalesFunnelStageModel stage,
    required Color color,
    required double maxValue,
  }) {
    final percentage = maxValue <= 0 ? 0 : ((stage.value / maxValue) * 100);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              stage.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: WorkSansAppTextStyles.medium.copyWith(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: context.modeTextPrimary,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            '${stage.value.toStringAsFixed(stage.value % 1 == 0 ? 0 : 1)} (${percentage.toStringAsFixed(0)}%)',
            style: WorkSansAppTextStyles.medium.copyWith(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: context.modeTextSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOperationalSummary(DashboardSummaryModel summary) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.modeSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.modeBorder.withValues(alpha: 0.55)),
      ),
      child: Column(
        children: [
          _buildOperationalRow(
            icon: Icons.timelapse_rounded,
            label: 'Active orders',
            value: '${summary.activeOrders}',
            color: context.modePrimaryBlue,
          ),
          Divider(height: 22, color: context.modeDivider),
          _buildOperationalRow(
            icon: Icons.check_circle_outline_rounded,
            label: 'Completed orders',
            value: '${summary.completedOrders}',
            color: context.modeSuccess,
          ),
          Divider(height: 22, color: context.modeDivider),
          _buildOperationalRow(
            icon: Icons.support_agent_rounded,
            label: 'Complaints today',
            value: '${summary.complaintsToday}',
            color: context.modeError,
          ),
        ],
      ),
    );
  }

  Widget _buildOperationalRow({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(9),
          ),
          child: Icon(icon, color: color, size: 19),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: WorkSansAppTextStyles.medium.copyWith(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: context.modeTextPrimary,
            ),
          ),
        ),
        Text(
          value,
          style: WorkSansAppTextStyles.medium.copyWith(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: context.modeTextPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: context.modeError),
            const SizedBox(height: 16),
            Text(
              'Oops! Something went wrong',
              style: WorkSansAppTextStyles.medium.copyWith(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: context.modeTextPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: WorkSansAppTextStyles.medium.copyWith(
                fontSize: 14,
                color: context.modeTextSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                context.read<DashboardBloc>().add(const LoadDashboardSummary());
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

  Color _funnelColor(int index) {
    final colors = [
      context.modePrimary,
      context.modePrimaryBlue,
      context.modeWarning,
      context.modeSuccess,
      context.modePrimaryAlt,
      context.modeInfo,
    ];
    return colors[index % colors.length];
  }

  double _getHorizontalPadding(double width) {
    if (width < 360) return 16;
    if (width < 600) return 20;
    if (width < 900) return 24;
    return 32;
  }

  double _getSpacing(double width) {
    if (width < 360) return 12;
    if (width < 600) return 14;
    if (width < 900) return 16;
    return 18;
  }
}

class _KpiData {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _KpiData({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });
}

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:sandwich_ai/src/core/globals/app_icon.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:intl/intl.dart';
import 'package:sandwich_ai/src/core/constant/textstyle.dart';
import 'package:sandwich_ai/src/core/local_sandbox/drawer_onboarding_cache.dart';
import 'package:sandwich_ai/src/core/theme/app_theme_extension.dart';
import 'package:sandwich_ai/src/features/pos/bloc/pos_dashboard_state_bloc/bloc.dart';
import 'package:sandwich_ai/src/features/pos/bloc/pos_dashboard_state_bloc/event.dart';
import 'package:sandwich_ai/src/features/pos/bloc/pos_dashboard_state_bloc/state.dart';
import 'package:sandwich_ai/src/features/pos/data/model/pos_dashboard_summary.dart';
import 'package:sandwich_ai/src/features/pos/presentation/pos_drawer.dart';
import 'package:sandwich_ai/src/features/pos/presentation/pos_showcase_scope.dart';
import 'package:showcaseview/showcaseview.dart';

class PosDashboardScreen extends StatefulWidget {
  const PosDashboardScreen({super.key});

  @override
  State<PosDashboardScreen> createState() => _PosDashboardScreenState();
}

class _PosDashboardScreenState extends State<PosDashboardScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final GlobalKey _activeOrdersTourKey = GlobalKey();
  bool _activeOrdersTourQueued = false;
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    context.read<DashboardBloc>().add(
      LoadDashboardSummary(date: _dashboardDateParam),
    );
  }

  String get _dashboardDateParam =>
      DateFormat('yyyy-MM-dd').format(_selectedDate);

  bool get _isSelectedDateToday {
    final now = DateTime.now();
    return _selectedDate.year == now.year &&
        _selectedDate.month == now.month &&
        _selectedDate.day == now.day;
  }

  String get _selectedDateLabel {
    if (_isSelectedDateToday) return 'Today';
    return DateFormat('MMM d').format(_selectedDate);
  }

  String get _snapshotTitle {
    if (_isSelectedDateToday) return "Today's Snapshot";
    return '${DateFormat('MMM d').format(_selectedDate)} Snapshot';
  }

  Future<void> _queueActiveOrdersTour() async {
    if (_activeOrdersTourQueued) return;
    _activeOrdersTourQueued = true;

    final hasSeenTour = await DrawerOnboardingCache.instance
        .hasSeenPosDashboardActiveOrdersTour();
    if (hasSeenTour || !mounted) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ShowcaseView.getNamed(
        posShowcaseScope,
      ).startShowCase([_activeOrdersTourKey]);
      unawaited(
        DrawerOnboardingCache.instance.markPosDashboardActiveOrdersTourSeen(),
      );
    });
  }

  Future<void> _pickDashboardDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(now.year - 2),
      lastDate: now,
      helpText: 'Select dashboard date',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(
              context,
            ).colorScheme.copyWith(primary: context.modePrimary),
          ),
          child: child!,
        );
      },
    );

    if (picked == null || !mounted) return;
    setState(() => _selectedDate = picked);
    context.read<DashboardBloc>().add(
      LoadDashboardSummary(date: DateFormat('yyyy-MM-dd').format(picked)),
    );
  }

  void _refreshDashboard() {
    context.read<DashboardBloc>().add(
      RefreshDashboardSummary(date: _dashboardDateParam),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTextStyle.merge(
      style: WorkSansAppTextStyles.medium,
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: context.modeBackground,
        drawer: const PosAppDrawer(),
        appBar: _buildAppBar(),
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
                    onRefresh: () async => _refreshDashboard(),
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

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: context.modeBackground,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      toolbarHeight: 86,
      leadingWidth: 72,
      leading: Center(
        child: IconButton(
          icon: HugeIcon(
            icon: HugeIcons.strokeRoundedMenu01,
            color: context.modeTextPrimary,
            size: 28 * AppIcon.sizeScale,
            strokeWidth: 1.8,
          ),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
          tooltip: 'Menu',
        ),
      ),
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(
            'assets/img/Logo-DqvzRW6_.png',
            width: 28,
            height: 28,
            fit: BoxFit.contain,
          ),
          const SizedBox(width: 10),
          Text(
            'SandwichAI',
            style: WorkSansAppTextStyles.medium.copyWith(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: context.modeTextPrimary,
            ),
          ),
        ],
      ),
      centerTitle: true,
      actions: [
        BlocBuilder<DashboardBloc, DashboardState>(
          builder: (context, state) {
            return IconButton(
              icon: HugeIcon(
                icon: HugeIcons.strokeRoundedRefresh,
                color: state is DashboardRefreshing
                    ? context.modeTextMuted
                    : context.modeTextPrimary,
                size: 28 * AppIcon.sizeScale,
                strokeWidth: 1.8,
              ),
              onPressed: state is DashboardRefreshing
                  ? null
                  : _refreshDashboard,
              tooltip: 'Refresh',
            );
          },
        ),
        const SizedBox(width: 14),
      ],
    );
  }

  Widget _buildDashboardContent(DashboardSummaryModel summary) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final padding = _getHorizontalPadding(constraints.maxWidth);

        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.fromLTRB(padding, 20, padding, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildActionGrid(constraints.maxWidth),
              const SizedBox(height: 28),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _snapshotTitle,
                      style: WorkSansAppTextStyles.medium.copyWith(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: context.modeTextPrimary,
                      ),
                    ),
                  ),
                  _buildDateChip(),
                ],
              ),
              const SizedBox(height: 22),
              _buildSnapshotList(summary),
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
      childAspectRatio: width < 360 ? 0.82 : 0.9,
      children: [
        _buildActionCard(
          icon: HugeIcons.strokeRoundedShoppingCart02,
          label: 'New Order',
          subtitle: 'Create a new order',
          onTap: () => context.goNamed('Pos-nav', extra: 1),
          colors: [context.modePrimary, context.modePrimaryAlt],
        ),
        _buildActionCard(
          icon: HugeIcons.strokeRoundedInvoice03,
          label: 'Active Orders',
          subtitle: 'View ongoing orders',
          onTap: () => context.goNamed('Pos-nav', extra: 2),
          colors: [context.modeWarning, context.modePrimary],
          showcaseKey: _activeOrdersTourKey,
          showcaseDescription:
              'Use Active Orders to continue orders already sent to kitchen, take payment, and check completion status.',
        ),
      ],
    );
  }

  Widget _buildActionCard({
    required List<List<dynamic>> icon,
    required String label,
    required String subtitle,
    required VoidCallback onTap,
    required List<Color> colors,
    GlobalKey? showcaseKey,
    String? showcaseDescription,
  }) {
    final card = Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: colors,
            ),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: colors.last.withValues(alpha: 0.24),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Positioned(
                right: -12,
                bottom: -16,
                child: Container(
                  width: 110,
                  height: 110,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.08),
                      width: 1,
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: SizedBox.expand(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Container(
                        width: 54,
                        height: 54,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.12),
                              blurRadius: 14,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Center(
                          child: HugeIcon(
                            icon: icon,
                            color: colors.first,
                            size: 27 * AppIcon.sizeScale,
                            strokeWidth: 1.9,
                          ),
                        ),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: WorkSansAppTextStyles.medium.copyWith(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            subtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: WorkSansAppTextStyles.medium.copyWith(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: Colors.white.withValues(alpha: 0.82),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(
                        width: 24,
                        height: 24,
                        child: HugeIcon(
                          icon: HugeIcons.strokeRoundedArrowRight02,
                          color: Colors.white.withValues(alpha: 0.9),
                          size: 18 * AppIcon.sizeScale,
                          strokeWidth: 2,
                        ),
                      ),
                    ],
                  ),
                ),
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
      targetBorderRadius: BorderRadius.circular(18),
      tooltipBackgroundColor: context.modePrimary,
      textColor: context.modeTextInverse,
      targetPadding: const EdgeInsets.all(8),
      child: card,
    );
  }

  Widget _buildDateChip() {
    return Material(
      color: context.modeSurface,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: _pickDashboardDate,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          height: 38,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: context.modeBorder.withValues(alpha: 0.5),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              HugeIcon(
                icon: HugeIcons.strokeRoundedCalendar03,
                color: context.modeTextPrimary,
                size: 18 * AppIcon.sizeScale,
                strokeWidth: 1.8,
              ),
              const SizedBox(width: 8),
              Text(
                _selectedDateLabel,
                style: WorkSansAppTextStyles.medium.copyWith(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: context.modeTextPrimary,
                ),
              ),
              const SizedBox(width: 4),
              AppIcon(
                Icons.keyboard_arrow_down_rounded,
                size: 18,
                color: context.modeTextMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSnapshotList(DashboardSummaryModel summary) {
    final rows = [
      _SnapshotData(
        title: 'Orders',
        subtitle: _isSelectedDateToday
            ? 'Total orders today'
            : 'Total orders on ${DateFormat('MMM d').format(_selectedDate)}',
        value: '${summary.totalOrders}',
        icon: HugeIcons.strokeRoundedShoppingCart02,
        color: context.modeInfo,
      ),
      _SnapshotData(
        title: 'Sales',
        subtitle: _isSelectedDateToday
            ? 'Total sales today'
            : 'Total sales on ${DateFormat('MMM d').format(_selectedDate)}',
        value: summary.formattedSales,
        icon: HugeIcons.strokeRoundedChartIncrease,
        color: context.modeSuccess,
      ),
      _SnapshotData(
        title: 'Pending Orders',
        subtitle: 'Awaiting processing',
        value: '${summary.pendingOrders}',
        icon: HugeIcons.strokeRoundedHourglass,
        color: context.modeWarning,
      ),
      _SnapshotData(
        title: 'Completed Orders',
        subtitle: 'Successfully delivered',
        value: '${summary.completedOrders}',
        icon: HugeIcons.strokeRoundedCheckmarkSquare02,
        color: context.modePrimaryBlue,
      ),
    ];

    return Column(
      children: rows
          .map(
            (row) => Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: _buildSnapshotRow(row),
            ),
          )
          .toList(),
    );
  }

  Widget _buildSnapshotRow(_SnapshotData data) {
    return Container(
      constraints: const BoxConstraints(minHeight: 110),
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
      decoration: BoxDecoration(
        color: context.modeSurface,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              color: data.color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
              child: HugeIcon(
                icon: data.icon,
                color: data.color,
                size: 35 * AppIcon.sizeScale,
                strokeWidth: 1.8,
              ),
            ),
          ),
          const SizedBox(width: 22),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  data.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: WorkSansAppTextStyles.medium.copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: context.modeTextPrimary,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  data.subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: WorkSansAppTextStyles.medium.copyWith(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: context.modeTextSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            data.value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: WorkSansAppTextStyles.medium.copyWith(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: data.color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            HugeIcon(
              icon: HugeIcons.strokeRoundedAlert02,
              size: 64 * AppIcon.sizeScale,
              color: context.modeError,
            ),
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
                context.read<DashboardBloc>().add(
                  LoadDashboardSummary(date: _dashboardDateParam),
                );
              },
              icon: const AppIcon(Icons.refresh),
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

  double _getHorizontalPadding(double width) {
    if (width < 360) return 16;
    if (width < 600) return 20;
    if (width < 900) return 24;
    return 32;
  }

  double _getSpacing(double width) {
    if (width < 360) return 14;
    if (width < 600) return 18;
    if (width < 900) return 20;
    return 22;
  }
}

class _SnapshotData {
  const _SnapshotData({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String title;
  final String subtitle;
  final String value;
  final List<List<dynamic>> icon;
  final Color color;
}

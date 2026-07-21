import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:sandwich_ai/src/core/globals/app_icon.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sandwich_ai/src/core/globals/notifications/notification_bell.dart';
import 'package:sandwich_ai/src/core/theme/app_theme_extension.dart';
import 'package:sandwich_ai/src/core/constant/textstyle.dart';
import 'package:sandwich_ai/src/features/processing/bloc/processing_dash_bloc/bloc.dart';
import 'package:sandwich_ai/src/features/processing/bloc/processing_dash_bloc/event.dart'
    show RefreshProcessingDashboard, LoadProcessingDashboard;
import 'package:sandwich_ai/src/features/processing/bloc/processing_dash_bloc/state.dart';
import 'package:sandwich_ai/src/features/processing/data/model/processing_dash_model.dart';
import 'package:sandwich_ai/src/features/processing/presentation/processing_drawer.dart';
import 'package:sandwich_ai/src/features/processing/presentation/recent_ver_dtls.dart';
import 'package:sandwich_ai/src/features/stock_control/presentation/shimmer_card.dart';

class ProcessingDashboardScreen extends StatefulWidget {
  const ProcessingDashboardScreen({super.key});

  @override
  State<ProcessingDashboardScreen> createState() =>
      _ProcessingDashboardScreenState();
}

class _ProcessingDashboardScreenState extends State<ProcessingDashboardScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  void _loadDashboard() {
    context.read<ProcessingDashboardBloc>().add(LoadProcessingDashboard());
  }

  Future<void> _onRefresh() async {
    context.read<ProcessingDashboardBloc>().add(RefreshProcessingDashboard());
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTextStyle.merge(
      style: WorkSansAppTextStyles.medium,
      child: Scaffold(
        key: _scaffoldKey,
        drawer: ProcessingAppDrawer(),
        backgroundColor: context.modeBackground,
        appBar: _buildAppBar(context),
        body: BlocConsumer<ProcessingDashboardBloc, ProcessingDashboardState>(
          listener: (context, state) {
            if (state is ProcessingDashboardError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.error),
                  backgroundColor: context.modeError,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          },
          builder: (context, state) {
            if (state is ProcessingDashboardInitial ||
                state is ProcessingDashboardLoading ||
                state is ProcessingDashboardRefreshing) {
              return _buildLoading();
            } else if (state is ProcessingDashboardLoaded) {
              return _buildDashboardContent(state.data);
            } else if (state is ProcessingDashboardRefreshing) {
              return _buildDashboardContent(state.currentData);
            } else if (state is ProcessingDashboardError) {
              return _buildError(state.error, state.errorType);
            }
            return _buildLoading();
          },
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: context.modeSurface,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      leading: IconButton(
        icon: AppIcon(Icons.menu, color: context.modeTextPrimary),
        onPressed: () {
          _scaffoldKey.currentState?.openDrawer();
        },
      ),
      title: Text(
        'Today\'s Overview',
        style: WorkSansAppTextStyles.medium.copyWith(
          fontSize: 17,
          fontWeight: FontWeight.w600,
          color: context.modeTextPrimary,
        ),
      ),
      centerTitle: false,
      actions: [
        const NotificationBellAction(margin: EdgeInsets.zero),
        BlocBuilder<ProcessingDashboardBloc, ProcessingDashboardState>(
          builder: (context, state) {
            return IconButton(
              icon: AppIcon(Icons.refresh, color: context.modeTextPrimary),
              onPressed: state is ProcessingDashboardLoading
                  ? null
                  : () => _onRefresh(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildLoading() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return shimmerCatalogCard(constraints.maxWidth);
      },
    );
  }

  Widget _buildError(String error, ProcessingDashboardErrorType errorType) {
    IconData errorIcon;
    String errorTitle;

    switch (errorType) {
      case ProcessingDashboardErrorType.network:
        errorIcon = Icons.wifi_off;
        errorTitle = 'Connection Error';
        break;
      case ProcessingDashboardErrorType.timeout:
        errorIcon = Icons.access_time;
        errorTitle = 'Request Timeout';
        break;
      case ProcessingDashboardErrorType.server:
        errorIcon = Icons.error_outline;
        errorTitle = 'Server Error';
        break;
      case ProcessingDashboardErrorType.notFound:
        errorIcon = Icons.search_off;
        errorTitle = 'Not Found';
        break;
      default:
        errorIcon = Icons.error_outline;
        errorTitle = 'Error';
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AppIcon(errorIcon, size: 64, color: context.modeTextMuted),
            const SizedBox(height: 16),
            Text(
              errorTitle,
              style: WorkSansAppTextStyles.medium.copyWith(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: context.modeTextPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: WorkSansAppTextStyles.medium.copyWith(
                fontSize: 14,
                color: context.modeTextSecondary,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadDashboard,
              icon: const AppIcon(Icons.refresh),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: context.modePrimary,
                foregroundColor: context.modeTextInverse,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardContent(ProcessingDashboardData data) {
    return RefreshIndicator(
      onRefresh: _onRefresh,
      color: context.modePrimary,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildOverviewCards(data),
            const SizedBox(height: 28),
            _buildDailyProcessingTasks(data.processingTasks),
            const SizedBox(height: 40),
            _buildRecentVerificationsCard(data.recentVerifications),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewCards(ProcessingDashboardData data) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final spacing = 16.0;
        final cardWidth = (constraints.maxWidth - spacing) / 2;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            SizedBox(
              width: cardWidth,
              child: _buildMetricCard(
                title: 'Product Intake',
                value: data.productIntake.count.toString(),
                subtitle: null,
                trend: null,
              ),
            ),
            SizedBox(
              width: cardWidth,
              child: _buildMetricCard(
                title: 'Waste Today',
                value: 'â‚¦${_formatNumber(data.wasteToday.value)}',
                subtitle: '${data.wasteToday.count} items',
                trend: null,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    String? subtitle,
    String? trend,
  }) {
    final Color? trendColor = trend != null
        ? (trend.startsWith('+') ? context.modeSuccess : context.modeError)
        : null;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.modeSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.modeBorder, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: WorkSansAppTextStyles.medium.copyWith(
              fontSize: 14,
              height: 1.3,
              color: context.modeTextSecondary,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: WorkSansAppTextStyles.medium.copyWith(
              fontSize: 32,
              fontWeight: FontWeight.w700,
              color: context.modeTextPrimary,
              height: 1.0,
            ),
          ),
          const SizedBox(height: 8),
          if (trend != null)
            Text(
              trend,
              style: WorkSansAppTextStyles.medium.copyWith(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: trendColor,
              ),
            )
          else if (subtitle != null)
            Text(
              subtitle,
              style: WorkSansAppTextStyles.medium.copyWith(
                fontSize: 13,
                color: context.modeTextMuted,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDailyProcessingTasks(ProcessingTasks tasks) {
    final total = tasks.pending + tasks.inProcess + tasks.completedToday;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.modeSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.modeBorder, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Daily Processing Tasks',
            style: WorkSansAppTextStyles.medium.copyWith(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: context.modeTextPrimary,
            ),
          ),
          const SizedBox(height: 18),
          if (total == 0)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Text(
                  'No tasks today',
                  style: WorkSansAppTextStyles.medium.copyWith(
                    fontSize: 14,
                    color: context.modeTextSecondary,
                  ),
                ),
              ),
            )
          else
            Row(
              children: [
                Expanded(
                  flex: 4,
                  child: SizedBox(
                    height: 120,
                    child: PieChart(
                      PieChartData(
                        sectionsSpace: 3,
                        centerSpaceRadius: 25,
                        sections: [
                          PieChartSectionData(
                            color: context.modeTextMuted,
                            value: tasks.pending.toDouble(),
                            title:
                                '${((tasks.pending / total) * 100).toStringAsFixed(0)}%',
                            radius: 25,
                            titleStyle: WorkSansAppTextStyles.medium.copyWith(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: context.modeTextInverse,
                            ),
                          ),
                          PieChartSectionData(
                            color: context.modeWarning,
                            value: tasks.inProcess.toDouble(),
                            title:
                                '${((tasks.inProcess / total) * 100).toStringAsFixed(0)}%',
                            radius: 25,
                            titleStyle: WorkSansAppTextStyles.medium.copyWith(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: context.modeTextInverse,
                            ),
                          ),
                          PieChartSectionData(
                            color: context.modeSuccess,
                            value: tasks.completedToday.toDouble(),
                            title:
                                '${((tasks.completedToday / total) * 100).toStringAsFixed(0)}%',
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
                        color: context.modeTextMuted,
                        label: 'Pending (${tasks.pending})',
                      ),
                      const SizedBox(height: 8),
                      _chartIndicator(
                        color: context.modeWarning,
                        label: 'In Process (${tasks.inProcess})',
                      ),
                      const SizedBox(height: 8),
                      _chartIndicator(
                        color: context.modeSuccess,
                        label: 'Completed (${tasks.completedToday})',
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

  Widget _buildRecentVerificationsCard(List<RecentVerification> verifications) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.modeSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.modeBorder, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Recent Verifications',
            style: WorkSansAppTextStyles.medium.copyWith(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: context.modeTextPrimary,
            ),
          ),
          const SizedBox(height: 20),
          if (verifications.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  children: [
                    AppIcon(
                      Icons.verified_outlined,
                      size: 48,
                      color: context.modeTextMuted,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'No recent verifications',
                      style: WorkSansAppTextStyles.medium.copyWith(
                        fontSize: 14,
                        color: context.modeTextMuted,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: verifications.length,
              separatorBuilder: (context, index) =>
                  Divider(height: 32, color: context.modeDivider, thickness: 1),
              itemBuilder: (context, index) {
                final verification = verifications[index];
                return _buildVerificationItem(verification);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildVerificationItem(RecentVerification verification) {
    final statusColor = verification.status.toLowerCase() == 'verified'
        ? context.modeSuccess
        : context.modeWarning;

    return InkWell(
      onTap: () {
        Navigator.of(context).push(
          CupertinoPageRoute(
            builder: (context) =>
                VerificationDetailsScreen(verification: verification),
          ),
        );
      },
      borderRadius: BorderRadius.circular(12),
      child: Ink(
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: AppIcon(
                  Icons.check_circle,
                  color: statusColor,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      verification.productName,
                      style: WorkSansAppTextStyles.medium.copyWith(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: context.modeTextPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'By ${verification.verifiedBy}',
                      style: WorkSansAppTextStyles.medium.copyWith(
                        fontSize: 13,
                        color: context.modeTextMuted,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  verification.status,
                  style: WorkSansAppTextStyles.medium.copyWith(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: statusColor,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              AppIcon(
                Icons.arrow_forward_ios,
                size: 16,
                color: context.modeTextMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatNumber(double number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toStringAsFixed(0);
  }
}
